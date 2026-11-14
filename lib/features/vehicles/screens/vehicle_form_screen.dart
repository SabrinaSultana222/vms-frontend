import 'package:flutter/material.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/components/app_button.dart';
import '../../../shared/components/app_text_field.dart';
import '../../../shared/layout/app_shell.dart';
import '../../../shared/layout/responsive_layout.dart';
import '../data/vehicle_repository.dart';
import '../models/vehicle.dart';
import '../models/vehicle_status.dart';
import '../models/vehicle_type.dart';

/// Screen for creating a new vehicle or editing an existing one.
///
/// Fields: id, vehicleNumber, company, type, brand, model, status.
class VehicleFormScreen extends StatefulWidget {
  final Vehicle? initialVehicle;

  const VehicleFormScreen({
    super.key,
    this.initialVehicle,
  });

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _vehicleNumberController;
  late final TextEditingController _companyController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;

  late String _selectedType;
  late String _selectedStatus;

  bool _isSaving = false;
  String? _backendError;

  bool get isEditing => widget.initialVehicle != null;

  @override
  void initState() {
    super.initState();
    if (!AuthSession.instance.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        }
      });
      _vehicleNumberController = TextEditingController();
      _companyController = TextEditingController();
      _brandController = TextEditingController();
      _modelController = TextEditingController();
      _selectedType = VehicleType.dropdownValues.first;
      _selectedStatus = VehicleStatus.dropdownValues.first;
      return;
    }

    final v = widget.initialVehicle;

    _vehicleNumberController = TextEditingController(text: v?.vehicleNumber ?? '');
    _companyController = TextEditingController(text: v?.company ?? '');
    _brandController = TextEditingController(text: v?.brand ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');

    // Match existing dropdown values as plain strings
    final rawType = v?.type;
    _selectedType = VehicleType.dropdownValues.firstWhere(
      (d) => d.toLowerCase() == (rawType ?? 'Truck').toLowerCase(),
      orElse: () => VehicleType.dropdownValues.first,
    );

    final rawStatus = v?.status;
    _selectedStatus = VehicleStatus.dropdownValues.firstWhere(
      (s) => s.toLowerCase() == (rawStatus ?? 'Active').toLowerCase(),
      orElse: () => VehicleStatus.dropdownValues.first,
    );
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _companyController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _backendError = null;
    });

    final vehicleNumber = _vehicleNumberController.text.trim().toUpperCase();
    final company = _companyController.text.trim();
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();

    try {
      if (isEditing) {
        final id = widget.initialVehicle!.id ?? widget.initialVehicle!.vehicleNumber;
        final updated = widget.initialVehicle!.copyWith(
          id: id,
          vehicleNumber: vehicleNumber,
          company: company,
          type: _selectedType,
          brand: brand,
          model: model,
          status: _selectedStatus,
        );

        await VehicleRepository.instance.updateVehicle(id, updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vehicle ${updated.vehicleNumber} updated successfully!'),
              backgroundColor: AppColors.statusActive,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        final newVehicle = Vehicle(
          vehicleNumber: vehicleNumber,
          company: company,
          type: _selectedType,
          brand: brand,
          model: model,
          status: _selectedStatus,
        );

        final created = await VehicleRepository.instance.createVehicle(newVehicle);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vehicle ${created.vehicleNumber} registered successfully!'),
              backgroundColor: AppColors.statusActive,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _backendError = e.message;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.statusInactive,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backendError = 'Failed to save vehicle: $e';
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save vehicle: $e'),
            backgroundColor: AppColors.statusInactive,
          ),
        );
      }
    } finally {
      if (mounted && _isSaving) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.instance.isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final title = isEditing
        ? 'Edit Vehicle: ${widget.initialVehicle!.vehicleNumber}'
        : 'Register New Vehicle';

    return AppShell(
      currentRoute: isEditing ? AppRoutes.vehicleEdit : AppRoutes.vehicleRegister,
      title: title,
      actions: [
        AppButton(
          label: 'Back to Vehicles',
          isOutlined: true,
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      child: SingleChildScrollView(
        child: ResponsiveContentWrapper(
          maxWidth: AppConstants.maxFormWidth,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top breadcrumb banner
                _buildBreadcrumbs(),
                const SizedBox(height: 16),

                // Backend Error Banner
                if (_backendError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusInactiveBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.statusInactive),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.statusInactive,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Backend Error',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.statusInactive,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _backendError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setState(() => _backendError = null),
                          tooltip: 'Dismiss',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Form Section 1: Vehicle Identification
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          title: 'Vehicle Identification',
                          subtitle: 'Vehicle registration number and assigned company.',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildRow([
                          AppTextField(
                            controller: _vehicleNumberController,
                            label: 'Vehicle Number *',
                            hint: 'e.g. VN-1001 or ABC-7890',
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Vehicle Number is required'
                                : null,
                          ),
                          AppTextField(
                            controller: _companyController,
                            label: 'Company *',
                            hint: 'e.g. Apex Logistics',
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Company is required'
                                : null,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Form Section 2: Specifications & Classification
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          title: 'Classification & Status',
                          subtitle: 'Vehicle category, brand, model, and operational status.',
                          icon: Icons.tune_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildRow([
                          // Vehicle Type Dropdown (plain string matching backend values)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Type *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedType,
                                decoration: const InputDecoration(),
                                items: VehicleType.dropdownValues.map((t) {
                                  return DropdownMenuItem(
                                    value: t,
                                    child: Row(
                                      children: [
                                        Icon(
                                          VehicleType.iconFor(t),
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(t),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedType = val);
                                },
                              ),
                            ],
                          ),
                          // Operational Status Dropdown (plain string matching backend values)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedStatus,
                                decoration: const InputDecoration(),
                                items: VehicleStatus.dropdownValues.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: VehicleStatus.colorFor(s),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(s),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedStatus = val);
                                },
                              ),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _buildRow([
                          AppTextField(
                            controller: _brandController,
                            label: 'Brand *',
                            hint: 'e.g. Ford, Toyota, Tesla',
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Brand is required'
                                : null,
                          ),
                          AppTextField(
                            controller: _modelController,
                            label: 'Model *',
                            hint: 'e.g. F-150, Camry, Model 3',
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Model is required'
                                : null,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Bottom Form Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Cancel',
                      isOutlined: true,
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                    AppButton(
                      label: isEditing ? 'Save Changes' : 'Register Vehicle',
                      icon: isEditing ? Icons.save_outlined : Icons.add,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _handleSave,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Vehicles',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
        Text(
          isEditing ? 'Edit Vehicle' : 'Register Vehicle',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Responsive(
      desktop: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ))
            .toList(),
      ),
      mobile: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: c,
                ))
            .toList(),
      ),
    );
  }
}

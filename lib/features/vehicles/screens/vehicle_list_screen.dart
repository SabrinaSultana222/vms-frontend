import 'package:flutter/material.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/components/app_button.dart';
import '../../../shared/components/confirmation_dialog.dart';
import '../../../shared/layout/app_shell.dart';
import '../../../shared/layout/responsive_layout.dart';
import '../data/vehicle_repository.dart';
import '../models/vehicle.dart';
import '../models/vehicle_status.dart';
import '../models/vehicle_type.dart';
import '../widgets/vehicle_stats_cards.dart';
import '../widgets/vehicle_status_badge.dart';

/// Screen displaying the inventory list of vehicles with filtering and CRUD actions.
class VehicleListScreen extends StatefulWidget {
  final VehicleRepository? repository;

  const VehicleListScreen({
    super.key,
    this.repository,
  });

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  late final VehicleRepository _repository;
  final _searchController = TextEditingController();

  String? _selectedStatus;
  String? _selectedType;
  String _searchQuery = '';
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? VehicleRepository.instance;
    _repository.addListener(_onRepositoryChanged);

    // Initial load from Spring Boot API if vehicles list is not already initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!AuthSession.instance.isAuthenticated && widget.repository == null) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        return;
      }
      if (_repository.vehicles.isEmpty && !_repository.hasError) {
        _fetchVehicles();
      }
    });
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onRepositoryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchVehicles() async {
    if (!AuthSession.instance.isAuthenticated && widget.repository == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
      return;
    }
    try {
      await _repository.fetchVehicles();
    } catch (_) {
      // Error state is captured in repository and handled in UI build
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedStatus = null;
      _selectedType = null;
    });
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.pushNamed(context, AppRoutes.vehicleRegister);
    if (result == true && mounted) {
      _fetchVehicles();
    }
  }

  Future<void> _navigateToEdit(Vehicle vehicle) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.vehicleEdit,
      arguments: vehicle,
    );
    if (result == true && mounted) {
      _fetchVehicles();
    }
  }

  Future<void> _handleDelete(Vehicle vehicle) async {
    if (_isDeleting) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Vehicle',
      message:
          'Are you sure you want to delete ${vehicle.displayName} (${vehicle.vehicleNumber})? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final id = vehicle.id ?? vehicle.vehicleNumber;
      setState(() => _isDeleting = true);

      try {
        await _repository.deleteVehicle(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vehicle ${vehicle.vehicleNumber} was deleted successfully.'),
              backgroundColor: AppColors.textPrimary,
            ),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete vehicle: ${e.message}'),
              backgroundColor: AppColors.statusInactive,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete vehicle: $e'),
              backgroundColor: AppColors.statusInactive,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.instance.isAuthenticated && widget.repository == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredVehicles = _repository.filter(
      query: _searchQuery,
      status: _selectedStatus,
      type: _selectedType,
    );

    final hasActiveFilters = _searchQuery.isNotEmpty ||
        _selectedStatus != null ||
        _selectedType != null;

    return AppShell(
      currentRoute: AppRoutes.vehicles,
      title: 'Vehicle Fleet Management',
      actions: [
        AppButton(
          label: 'Register Vehicle',
          icon: Icons.add,
          onPressed: _navigateToCreate,
        ),
      ],
      child: SingleChildScrollView(
        child: ResponsiveContentWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. KPI Statistics Overview Cards
              VehicleStatsCards(repository: _repository),
              const SizedBox(height: 24),

              // 2. Filter & Search Toolbar Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Responsive(
                    desktop: _buildDesktopFilterBar(hasActiveFilters),
                    mobile: _buildMobileFilterBar(hasActiveFilters),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Vehicles Content (Loading, Error, Empty, or Table)
              _buildVehiclesContent(filteredVehicles, hasActiveFilters),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehiclesContent(List<Vehicle> filteredVehicles, bool hasActiveFilters) {
    // 1. Loading State
    if (_repository.isLoading && _repository.vehicles.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loading fleet vehicles from server...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connecting to backend API',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Error State (No silent fallback to mock data)
    if (_repository.hasError && _repository.vehicles.isEmpty) {
      return Card(
        color: AppColors.statusInactiveBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          side: const BorderSide(color: AppColors.statusInactive, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: AppColors.statusInactive,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to Load Vehicles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _repository.errorMessage ??
                        'An error occurred while connecting to the Spring Boot backend.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Retry Connection',
                    icon: Icons.refresh,
                    onPressed: _fetchVehicles,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. Empty State (No vehicles in repository or no filter match)
    if (filteredVehicles.isEmpty) {
      return Card(
        child: _buildEmptyState(hasActiveFilters),
      );
    }

    // 4. Success State (Table on desktop, Card list on mobile)
    return Card(
      child: Responsive(
        desktop: _buildDesktopTable(filteredVehicles),
        mobile: _buildMobileCardList(filteredVehicles),
      ),
    );
  }

  Widget _buildDesktopFilterBar(bool hasActiveFilters) {
    return Row(
      children: [
        // Search Input
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by vehicle number, company, brand, or model...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        const SizedBox(width: 12),

        // Status Filter Dropdown (plain string matching backend values)
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('desktop_status_$_selectedStatus'),
            initialValue: _selectedStatus,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Statuses')),
              ...VehicleStatus.dropdownValues.map(
                (s) => DropdownMenuItem(value: s, child: Text(s)),
              ),
            ],
            onChanged: (val) => setState(() => _selectedStatus = val),
          ),
        ),
        const SizedBox(width: 12),

        // Type Filter Dropdown (plain string matching backend values)
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('desktop_type_$_selectedType'),
            initialValue: _selectedType,
            decoration: const InputDecoration(labelText: 'Vehicle Type'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Types')),
              ...VehicleType.dropdownValues.map(
                (t) => DropdownMenuItem(value: t, child: Text(t)),
              ),
            ],
            onChanged: (val) => setState(() => _selectedType = val),
          ),
        ),
        if (hasActiveFilters) ...[
          const SizedBox(width: 12),
          AppButton(
            label: 'Reset',
            isOutlined: true,
            icon: Icons.filter_alt_off_outlined,
            onPressed: _resetFilters,
          ),
        ],
      ],
    );
  }

  Widget _buildMobileFilterBar(bool hasActiveFilters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search vehicles...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                key: ValueKey('mobile_status_$_selectedStatus'),
                initialValue: _selectedStatus,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...VehicleStatus.dropdownValues.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s)),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedStatus = val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String?>(
                key: ValueKey('mobile_type_$_selectedType'),
                initialValue: _selectedType,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...VehicleType.dropdownValues.map(
                    (t) => DropdownMenuItem(value: t, child: Text(t)),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedType = val),
              ),
            ),
          ],
        ),
        if (hasActiveFilters) ...[
          const SizedBox(height: 12),
          AppButton(
            label: 'Clear Filters',
            isOutlined: true,
            onPressed: _resetFilters,
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopTable(List<Vehicle> vehicles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${vehicles.length} of ${_repository.totalCount} vehicles',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 960),
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 64,
              columns: const [
                DataColumn(label: Text('VEHICLE NUMBER')),
                DataColumn(label: Text('COMPANY')),
                DataColumn(label: Text('TYPE')),
                DataColumn(label: Text('BRAND')),
                DataColumn(label: Text('MODEL')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: vehicles.map((v) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        v.vehicleNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        v.company,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            v.vehicleType.icon,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(v.type),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        v.brand,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(
                      Text(v.model),
                    ),
                    DataCell(VehicleStatusBadge(status: v.status)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit Vehicle',
                            color: AppColors.primary,
                            onPressed: () => _navigateToEdit(v),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            tooltip: 'Delete Vehicle',
                            color: AppColors.statusInactive,
                            onPressed: () => _handleDelete(v),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCardList(List<Vehicle> vehicles) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vehicles.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final v = vehicles[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(v.vehicleType.icon, color: AppColors.primary),
          ),
          title: Text(
            '${v.brand} ${v.model}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('No: ${v.vehicleNumber} • Company: ${v.company}'),
              const SizedBox(height: 4),
              VehicleStatusBadge(status: v.status),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                _navigateToEdit(v);
              } else if (action == 'delete') {
                _handleDelete(v);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppColors.statusInactive),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.statusInactive)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool hasFilters) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No vehicles match your filter criteria' : 'No vehicles found in fleet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Try searching for another keyword or clear existing filters.'
                  : 'Start by registering your first company vehicle.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            if (hasFilters)
              AppButton(
                label: 'Clear All Filters',
                isOutlined: true,
                onPressed: _resetFilters,
              )
            else
              AppButton(
                label: 'Register First Vehicle',
                icon: Icons.add,
                onPressed: _navigateToCreate,
              ),
          ],
        ),
      ),
    );
  }
}

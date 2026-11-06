import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/components/app_button.dart';
import '../../../shared/components/confirmation_dialog.dart';
import '../../../shared/layout/app_shell.dart';
import '../../../shared/layout/responsive_layout.dart';
import '../data/mock_vehicles.dart';
import '../models/vehicle.dart';
import '../models/vehicle_status.dart';
import '../models/vehicle_type.dart';
import '../widgets/vehicle_stats_cards.dart';
import '../widgets/vehicle_status_badge.dart';

/// Screen displaying the inventory list of vehicles with filtering and CRUD actions.
class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _repository = VehicleRepository.instance;
  final _searchController = TextEditingController();

  VehicleStatus? _selectedStatus;
  VehicleType? _selectedType;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onRepositoryChanged);
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

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedStatus = null;
      _selectedType = null;
    });
  }

  void _navigateToCreate() {
    Navigator.pushNamed(context, AppRoutes.vehicleRegister);
  }

  void _navigateToEdit(Vehicle vehicle) {
    Navigator.pushNamed(
      context,
      AppRoutes.vehicleEdit,
      arguments: vehicle,
    );
  }

  Future<void> _handleDelete(Vehicle vehicle) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Vehicle',
      message: 'Are you sure you want to delete ${vehicle.displayName} (${vehicle.vehicleNumber})? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      _repository.deleteVehicle(vehicle.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle ${vehicle.vehicleNumber} was deleted.'),
          backgroundColor: AppColors.textPrimary,
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.amber,
            onPressed: () => _repository.addVehicle(vehicle),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

              // 3. Vehicles Table or Empty State Card
              Card(
                child: filteredVehicles.isEmpty
                    ? _buildEmptyState(hasActiveFilters)
                    : Responsive(
                        desktop: _buildDesktopTable(filteredVehicles),
                        mobile: _buildMobileCardList(filteredVehicles),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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

        // Status Filter Dropdown
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<VehicleStatus?>(
            key: ValueKey('desktop_status_$_selectedStatus'),
            initialValue: _selectedStatus,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Statuses')),
              ...VehicleStatus.values.map(
                (s) => DropdownMenuItem(value: s, child: Text(s.label)),
              ),
            ],
            onChanged: (val) => setState(() => _selectedStatus = val),
          ),
        ),
        const SizedBox(width: 12),

        // Type Filter Dropdown
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<VehicleType?>(
            key: ValueKey('desktop_type_$_selectedType'),
            initialValue: _selectedType,
            decoration: const InputDecoration(labelText: 'Vehicle Type'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Types')),
              ...VehicleType.values.map(
                (t) => DropdownMenuItem(value: t, child: Text(t.label)),
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
              child: DropdownButtonFormField<VehicleStatus?>(
                key: ValueKey('mobile_status_$_selectedStatus'),
                initialValue: _selectedStatus,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...VehicleStatus.values.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedStatus = val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<VehicleType?>(
                key: ValueKey('mobile_type_$_selectedType'),
                initialValue: _selectedType,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...VehicleType.values.map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.label)),
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
                          Icon(v.type.icon, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(v.type.label),
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
            child: Icon(v.type.icon, color: AppColors.primary),
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

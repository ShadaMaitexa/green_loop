import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_models/data_models.dart';
import 'package:auth/auth.dart';
import 'user_management_state.dart';
import 'package:ui_kit/ui_kit.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementState>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UserManagementState>();

    return Padding(
      padding: const EdgeInsets.all(GLSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, state),
          const SizedBox(height: GLSpacing.lg),
          _buildFilters(context, state),
          const SizedBox(height: GLSpacing.lg),
          Expanded(
            child: Card(
              child: state.isLoading && state.users.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.users.isEmpty
                      ? const Center(child: Text('No users found'))
                      : _buildUserTable(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserManagementState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Management',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Create and manage all platform users',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        GLButton(
          text: 'Add User',
          onPressed: () => _showAddUserDialog(context),
          icon: Icons.add_rounded,
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, UserManagementState state) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        state.setSearchQuery('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => state.setSearchQuery(value),
          ),
        ),
        const SizedBox(width: GLSpacing.md),
        Expanded(
          child: DropdownButtonFormField<UserRole>(
            value: state.filterRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              contentPadding: EdgeInsets.symmetric(horizontal: GLSpacing.md),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Roles')),
              ...UserRole.values.map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.label),
                  )),
            ],
            onChanged: (value) => state.setRoleFilter(value),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTable(BuildContext context, UserManagementState state) {
    return ListView(
      children: [
        DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Ward')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: state.users.map((user) {
            return DataRow(cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(user.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.role.label,
                    style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              DataCell(Text(user.assignedWard?.nameEn ?? '-')),
              DataCell(
                Switch(
                  value: user.isActive,
                  onChanged: (value) => _confirmStatusToggle(context, user),
                  activeThumbColor: Colors.green,
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {}, // Implementation placeholder
                ),
              ),
            ]);
          }).toList(),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return Colors.deepPurple;
      case UserRole.hksWorker: return Colors.blue;
      case UserRole.recycler: return Colors.orange;
      case UserRole.resident: return Colors.green;
    }
  }

  void _confirmStatusToggle(BuildContext context, PlatformUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Deactivate User?' : 'Activate User?'),
        content: Text('Are you sure you want to ${user.isActive ? 'deactivate' : 'activate'} ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<UserManagementState>().toggleUserStatus(user);
              Navigator.pop(context);
            },
            child: Text(user.isActive ? 'Deactivate' : 'Activate', style: TextStyle(color: user.isActive ? Colors.red : Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    // Simplified stub for the dialog
    showDialog(
      context: context,
      builder: (context) => const _AddUserDialog(),
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.resident;
  List<Ward> _wards = [];
  int? _selectedWardId;

  @override
  void initState() {
    super.initState();
    _loadWards();
  }

  Future<void> _loadWards() async {
    try {
      final wards = await context.read<AuthRepository>().getWards();
      if (mounted) setState(() => _wards = wards);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GLTextField(label: 'Full Name', controller: _nameController),
              const SizedBox(height: GLSpacing.md),
              GLTextField(label: 'Email', controller: _emailController),
              const SizedBox(height: GLSpacing.md),
              GLTextField(label: 'Phone', controller: _phoneController),
              const SizedBox(height: GLSpacing.md),
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: UserRole.values.map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role.label),
                    )).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
                },
              ),
              if (_selectedRole == UserRole.hksWorker) ...[
                const SizedBox(height: GLSpacing.md),
                DropdownButtonFormField<int>(
                  value: _selectedWardId,
                  decoration: const InputDecoration(labelText: 'Assign Ward'),
                  items: _wards.map((ward) => DropdownMenuItem(
                        value: ward.id,
                        child: Text(ward.nameEn),
                      )).toList(),
                  onChanged: (value) => setState(() => _selectedWardId = value),
                  validator: (value) => value == null ? 'Please select a ward' : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        GLButton(
          text: 'Create',
          isLoading: context.watch<UserManagementState>().isLoading,
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final success = await context.read<UserManagementState>().createUser({
                'name': _nameController.text,
                'email': _emailController.text,
                'phone': _phoneController.text,
                'role': _selectedRole.toJson(),
                if (_selectedRole == UserRole.hksWorker) 'ward_id': _selectedWardId,
              });
              if (success && mounted && context.mounted) Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}

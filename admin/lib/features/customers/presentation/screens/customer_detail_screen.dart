import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../utils/phone_formatter.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerByIdProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, customerAsync.value),
            tooltip: 'Edit Customer',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(context, value, customerAsync.value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'suspend',
                child: Text('Suspend Customer'),
              ),
              const PopupMenuItem(
                value: 'activate',
                child: Text('Activate Customer'),
              ),
              const PopupMenuItem(
                value: 'ban',
                child: Text('Ban Customer'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Customer'),
              ),
            ],
          ),
        ],
      ),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (customer) {
          if (customer == null) {
            return const Center(child: Text('Customer not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(context, customer),
                const SizedBox(height: 16),
                _buildStatsCards(customer),
                const SizedBox(height: 16),
                _buildContactInfoSection(context, customer),
                const SizedBox(height: 16),
                _buildAccountInfoSection(context, customer),
                if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotesSection(context, customer),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Customer customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAvatar(customer),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (customer.businessName != null &&
                      customer.businessName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      customer.businessName!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: customer.statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      customer.displayStatus,
                      style: TextStyle(
                        color: customer.statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Joined: ${_formatDate(customer.createdAt)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Customer customer) {
    if (customer.avatarUrl != null && customer.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(customer.avatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    final initials = customer.name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join('');
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.blue.shade300,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildStatsCards(Customer customer) {
    return Row(
      children: [
        _buildStatCard(
          'Total Orders',
          customer.totalOrders.toString(),
          Icons.shopping_cart,
          Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Total Spent',
          '\$${customer.totalSpent.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Pending',
          customer.pendingOrders.toString(),
          Icons.pending,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoSection(BuildContext context, Customer customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Email', customer.email, Icons.email),
            const SizedBox(height: 12),
            _buildInfoRow('Phone', formatPhoneWithFlag(customer.phone), Icons.phone),
            if (customer.fullAddress != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Address', customer.fullAddress!, Icons.location_on),
            ],
            if (customer.gender != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Gender', customer.gender!, Icons.person),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoSection(BuildContext context, Customer customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Customer ID', customer.id.substring(0, 16), Icons.fingerprint),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Last Login',
              customer.lastLogin != null ? _formatDate(customer.lastLogin!) : 'Never',
              Icons.login,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Email Verified',
              customer.emailVerified ? 'Yes' : 'No',
              customer.emailVerified ? Icons.check_circle : Icons.cancel,
              valueColor: customer.emailVerified ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Phone Verified',
              customer.phoneVerified ? 'Yes' : 'No',
              customer.phoneVerified ? Icons.check_circle : Icons.cancel,
              valueColor: customer.phoneVerified ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, Customer customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showEditNotesDialog(context, customer),
                ),
              ],
            ),
            const Divider(),
            Text(customer.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _handleAction(BuildContext context, String action, Customer? customer) {
    if (customer == null) return;
    _confirmAction(context, action, customer);
  }

  void _confirmAction(BuildContext context, String action, Customer customer) {
    final repository = ref.read(customerRepositoryProvider);
    String title = '';
    String content = '';
    Color buttonColor = Colors.blue;

    switch (action) {
      case 'suspend':
        title = 'Suspend Customer';
        content = 'Are you sure you want to suspend ${customer.name}? They will not be able to place orders.';
        buttonColor = Colors.orange;
        break;
      case 'ban':
        title = 'Ban Customer';
        content = 'Are you sure you want to ban ${customer.name}? This action can be reversed later.';
        buttonColor = Colors.red;
        break;
      case 'activate':
        title = 'Activate Customer';
        content = 'Are you sure you want to activate ${customer.name}?';
        break;
      case 'delete':
        title = 'Delete Customer';
        content = 'Are you sure you want to delete ${customer.name}? This action cannot be undone.';
        buttonColor = Colors.red;
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
            onPressed: () async {
              Navigator.pop(context);

              try {
                switch (action) {
                  case 'suspend':
                    await repository.suspendCustomer(customer.id);
                    break;
                  case 'ban':
                    await repository.banCustomer(customer.id);
                    break;
                  case 'activate':
                    await repository.activateCustomer(customer.id);
                    break;
                  case 'delete':
                    await repository.deleteCustomer(customer.id);
                    if (mounted) Navigator.pop(context);
                    break;
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Customer ${action}d successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(action[0].toUpperCase() + action.substring(1),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Customer? customer) {
    if (customer == null) return;

    final nameController = TextEditingController(text: customer.name);
    final emailController = TextEditingController(text: customer.email);
    final phoneController = TextEditingController(text: customer.phone ?? '');
    final businessController =
        TextEditingController(text: customer.businessName ?? '');
    final addressController = TextEditingController(text: customer.address ?? '');
    final cityController = TextEditingController(text: customer.city ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: businessController,
                decoration: const InputDecoration(labelText: 'Business Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repository = ref.read(customerRepositoryProvider);
              await repository.updateCustomer(customer.id, {
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'businessName': businessController.text.trim(),
                'address': addressController.text.trim(),
                'city': cityController.text.trim(),
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditNotesDialog(BuildContext context, Customer customer) {
    final notesController = TextEditingController(text: customer.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Notes'),
        content: TextField(
          controller: notesController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repository = ref.read(customerRepositoryProvider);
              await repository.updateCustomerNotes(
                  customer.id, notesController.text.trim());

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notes updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
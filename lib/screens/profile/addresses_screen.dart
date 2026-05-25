import 'package:flutter/material.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/screens/navigation_shell.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:shopsnports/models/address.dart';

class AddressesScreen extends StatefulWidget {
  static const routeName = '/profile/addresses';
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  bool _isLoading = true;
  List<Address> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _isLoading = false;
          // Mock data - in production, fetch from Firestore
          _addresses = [
            const Address(
              id: '1',
              type: 'Home',
              name: 'John Doe',
              street: '123 Main Street',
              apt: 'Apt 4B',
              city: 'Lagos',
              state: 'Lagos State',
              zip: '100001',
              landmark: 'Near City Mall',
              country: 'Nigeria',
              phone: '+234 123 456 7890',
              isDefault: true,
            ),
            const Address(
              id: '2',
              type: 'Office',
              name: 'John Doe',
              street: '456 Business Avenue',
              apt: 'Suite 200',
              city: 'Lagos',
              state: 'Lagos State',
              zip: '100002',
              landmark: 'Victoria Island',
              country: 'Nigeria',
              phone: '+234 098 765 4321',
              isDefault: false,
            ),
          ];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addAddress() async {
    final result = await Navigator.pushNamed(context, AppRoutes.addAddress);
    if (result != null && result is Address) {
      setState(() {
        _addresses.add(result);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address added successfully')),
        );
      }
    }
  }

  Future<void> _editAddress(Address address, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressesScreen(), // Would use edit mode
      ),
    );
    if (result != null && result is Address) {
      setState(() {
        _addresses[index] = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address updated successfully')),
        );
      }
    }
  }

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _addresses.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _setDefault(int index) {
    setState(() {
      for (var i = 0; i < _addresses.length; i++) {
        _addresses[i] = Address(
          id: _addresses[i].id,
          type: _addresses[i].type,
          name: _addresses[i].name,
          street: _addresses[i].street,
          apt: _addresses[i].apt,
          city: _addresses[i].city,
          state: _addresses[i].state,
          zip: _addresses[i].zip,
          landmark: _addresses[i].landmark,
          country: _addresses[i].country,
          phone: _addresses[i].phone,
          isDefault: i == index,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default address updated')),
    );
  }

  void _handleNavTap(int index) {
    // Navigate to NavigationShell with selected index
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => NavigationShell(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 4,
      onNavTap: _handleNavTap,
      appBar: null,
      appBarTitle: 'My Addresses',
      showNewsTicker: false,
      body: Column(
        children: [
          // Back Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Profile',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addAddress,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Address'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),

          // Addresses List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _addresses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No addresses saved yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your delivery addresses here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _addAddress,
                              icon: const Icon(Icons.add_location),
                              label: const Text('Add First Address'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _addresses.length,
                        itemBuilder: (context, index) {
                          final address = _addresses[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: address.isDefault
                                  ? BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    )
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: Type & Default Badge
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            address.type == 'Home'
                                                ? Icons.home
                                                : address.type == 'Office'
                                                    ? Icons.business
                                                    : Icons.location_on,
                                            size: 20,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            address.type,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (address.isDefault) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'DEFAULT',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      PopupMenuButton(
                                        itemBuilder: (context) => [
                                          if (!address.isDefault)
                                            const PopupMenuItem(
                                              value: 'default',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Set as Default'),
                                                ],
                                              ),
                                            ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 18),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    size: 18,
                                                    color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'default') {
                                            _setDefault(index);
                                          } else if (value == 'edit') {
                                            _editAddress(address, index);
                                          } else if (value == 'delete') {
                                            _deleteAddress(index);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Name
                                  Text(
                                    address.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Address Lines
                                  Text(
                                    '${address.street}${address.apt.isNotEmpty ? ', ${address.apt}' : ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${address.city}, ${address.state} ${address.zip}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    address.country,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),

                                  if (address.landmark.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.place,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          address.landmark,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  if (address.phone != null &&
                                      address.phone!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.phone,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          address.phone!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

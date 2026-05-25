import 'package:flutter/material.dart';

class DeliveryAddressCard extends StatelessWidget {
  final String label;
  final String name;
  final String addressLine;
  final String phone;
  final VoidCallback? onEdit;
  final VoidCallback? onSelect;

  const DeliveryAddressCard({
    super.key,
    required this.label,
    required this.name,
    required this.addressLine,
    required this.phone,
    this.onEdit,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(child: Text(label[0])),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$label • $name',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(addressLine),
                const SizedBox(height: 4),
                Text(phone, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: onSelect,
              icon: const Icon(Icons.check_circle_outline)),
        ],
      ),
    );
  }
}

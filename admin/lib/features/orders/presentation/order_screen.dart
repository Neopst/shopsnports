// lib/features/orders/presentation/order_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/features/orders/data/order_provider.dart';

class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text("No orders found"));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("ID")),
                DataColumn(label: Text("Customer")),
                DataColumn(label: Text("Total")),
                DataColumn(label: Text("Status")),
              ],
              rows: orders.map((o) {
                return DataRow(
                  cells: [
                    DataCell(Text(o["id"].toString())),
                    DataCell(Text(o["customer"].toString())),
                    DataCell(Text(o["total"].toString())),
                    DataCell(Text(o["status"].toString())),
                  ],
                );
              }).toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}

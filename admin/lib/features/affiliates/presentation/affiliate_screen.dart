// lib/features/affiliates/presentation/affiliate_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/features/affiliates/data/affiliate_provider.dart';

class AffiliateScreen extends ConsumerWidget {
  const AffiliateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final affiliatesAsync = ref.watch(affiliatesProvider);

    return Scaffold(
      body: affiliatesAsync.when(
        data: (affiliates) {
          if (affiliates.isEmpty) {
            return const Center(child: Text("No affiliates found"));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("ID")),
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Email")),
                DataColumn(label: Text("Commission")),
              ],
              rows: affiliates.map((a) {
                return DataRow(
                  cells: [
                    DataCell(Text(a.id)),
                    DataCell(Text(a.fullName)),
                    DataCell(Text(a.email)),
                    DataCell(Text('${a.commissionRate}%')),
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

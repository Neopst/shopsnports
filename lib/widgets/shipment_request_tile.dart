import 'package:flutter/material.dart';
import '../services/mock_affiliate_service.dart';

class ShipmentRequestTile extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isAdmin;
  final MockAffiliateService? service;

  const ShipmentRequestTile(
      {super.key, required this.request, this.isAdmin = false, this.service});

  @override
  Widget build(BuildContext context) {
    final client = request['client'] as Map<String, dynamic>? ?? {};
    final name = client['name'] ?? client['email'] ?? 'Client';
    final status = request['status'] ?? 'unknown';
    final createdAt = request['createdAt'] ?? '';
    final id = request['id'] ?? 'na';

    double? parseAmount(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final amount = parseAmount(request['amount'] ??
        request['payoutAmount'] ??
        request['affiliatePayout'] ??
        request['client']?['amount']);

    double? parsePercent(dynamic p) {
      if (p == null) return null;
      if (p is num) return p.toDouble();
      if (p is String) return double.tryParse(p);
      return null;
    }

    final percent = parsePercent(request['adminCommissionPercent'] ??
            request['commissionPercent'] ??
            request['commission']) ??
        10.0;
    final commission = (amount != null) ? (amount * percent / 100.0) : null;

    String timeAgo(String iso) {
      try {
        final dt = DateTime.parse(iso);
        final diff = DateTime.now().difference(dt);
        if (diff.inDays > 0) return '${diff.inDays}d ago';
        if (diff.inHours > 0) return '${diff.inHours}h ago';
        if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
        return 'just now';
      } catch (_) {
        return iso.toString();
      }
    }

    Widget statusChip(String s) {
      final color = s == 'completed' ? Colors.green : Colors.orange;
      return Chip(
          label: Text(s.toString()),
          backgroundColor: color.withAlpha((0.12 * 255).round()));
    }

    String payoutState() {
      if (status == 'completed') {
        final hasPayout = request['payoutAmount'] != null ||
            request['affiliatePayout'] != null ||
            amount != null;
        return hasPayout ? 'Payout scheduled' : 'Pending payout';
      }
      return status.toString();
    }

    return ListTile(
      key: Key('affiliate_request_$id'),
      title: Text(name.toString()),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '${timeAgo(createdAt.toString())} • ${request['client']?['item'] ?? ''}'),
          const SizedBox(height: 4),
          Text(payoutState(),
              key: Key('request_status_$id'),
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (amount != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text('₦ ${amount.toStringAsFixed(0)}',
                key: Key('request_amount_$id')),
          ),
        if (commission != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text('Commission: ₦ ${commission.toStringAsFixed(0)}',
                key: Key('request_commission_$id'),
                style: const TextStyle(fontSize: 12)),
          ),
        statusChip(status.toString()),
        const SizedBox(width: 8),
        // Mark complete button (visible to all, enabled only for admins)
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: TextButton(
            key: Key('mark_complete_button_$id'),
            onPressed: () async {
              if (!isAdmin) {
                // Non-admins: inform them this action is for admins only
                final messenger = ScaffoldMessenger.of(context);
                messenger
                    .showSnackBar(const SnackBar(content: Text('Admins only')));
                return;
              }

              // Admin path: call into the provided service if available
              if (service != null) {
                final messenger = ScaffoldMessenger.of(context);
                final id = request['id']?.toString() ?? '';
                try {
                  final updated = await service!.markRequestCompleted(id);
                  if (updated != null) {
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Marked complete')));
                  } else {
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Request not found')));
                  }
                } catch (e) {
                  messenger.showSnackBar(
                      const SnackBar(content: Text('Failed to mark complete')));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked complete (mock)')));
              }
            },
            style: TextButton.styleFrom(
                foregroundColor: isAdmin ? Colors.blue : Colors.grey),
            child: const Text('Mark complete'),
          ),
        ),
        const Icon(Icons.chevron_right)
      ]),
      onTap: () {
        // In a real app we'd open details
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Open request details (mock)')));
      },
    );
  }
}

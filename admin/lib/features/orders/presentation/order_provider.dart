import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/order_service_enhanced.dart';

final orderServiceProvider = Provider((ref) => OrderServiceEnhanced());

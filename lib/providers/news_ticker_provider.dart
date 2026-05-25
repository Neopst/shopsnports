import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide news ticker raw content. The string uses '*' as a separator
/// between items (as provided by the user). Consumers can parse this or
/// use the convenience provider below which returns a parsed list.
const _rawNews =
    'LICENSED \$ OPERATIONAL: NIGERIAN CUSTOMS AGENT * FREIGHT FORWARDING AGENT * IATA CARGO AGENT * FOREIGN AIRLINE AGENCY PERMIT * OIL INDUSTRY SERVICE COMPANY PERMIT (SPECIALISED CATEGORY)* AVIATION & APPLIED SERVICES * LOGISTICS & SUPPLY CHAIN MANAGEMENT (AIR & SEA) * SPECIAL CARGO HANDLING * (AVI,RADIOACTIVE,HUM,OHG,OIL WELL EQUIPMENT)';

final newsTickerRawProvider = Provider<String>((_) => _rawNews);

final newsTickerItemsProvider = Provider<List<String>>((ref) {
  final raw = ref.watch(newsTickerRawProvider);
  final parts = raw
      .split('*')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);
  return parts;
});

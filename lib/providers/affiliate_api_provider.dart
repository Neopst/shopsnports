import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/services/affiliate_api.dart';
import 'package:shopsnports/providers/firestore_provider.dart';

final affiliateApiProvider = Provider<AffiliateApi>((ref) {
  final db = ref.read(firestoreProvider);
  return AffiliateApi.withDb(db);
});

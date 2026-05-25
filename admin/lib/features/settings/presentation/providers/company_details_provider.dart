import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/company_details.dart';
import '../../data/services/company_details_service.dart';

final companyDetailsServiceProvider = Provider<CompanyDetailsService>((ref) {
  return CompanyDetailsService();
});

class CompanyDetailsNotifier extends Notifier<AsyncValue<CompanyDetails>> {
  @override
  AsyncValue<CompanyDetails> build() {
    _loadCompanyDetails();
    return const AsyncValue.loading();
  }

  Future<void> _loadCompanyDetails() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(companyDetailsServiceProvider);
      final details = await service.loadCompanyDetails();
      state = AsyncValue.data(details);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateCompanyDetails(CompanyDetails details) async {
    try {
      final service = ref.read(companyDetailsServiceProvider);
      await service.saveCompanyDetails(details);
      state = AsyncValue.data(details);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadCompanyDetails();
  }
}

final companyDetailsProvider =
    NotifierProvider<CompanyDetailsNotifier, AsyncValue<CompanyDetails>>(
      CompanyDetailsNotifier.new,
    );

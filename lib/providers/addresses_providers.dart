import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/models/address.dart';
import 'package:shopsnports/repositories/addresses_repository.dart';
import 'package:shopsnports/repositories/mock_addresses_repository.dart';

final addressesRepositoryProvider = Provider<AddressesRepository>((ref) {
  return MockAddressesRepository();
});

final addressesStreamProvider = StreamProvider<List<Address>>((ref) {
  final repo = ref.watch(addressesRepositoryProvider);
  return repo.addressesStream();
});

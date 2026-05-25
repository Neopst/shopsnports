import 'package:shopsnports/models/address.dart';

abstract class AddressesRepository {
  /// Stream of the current user's addresses.
  Stream<List<Address>> addressesStream();

  /// Add or update an address; returns the saved address (with id when created).
  Future<Address> saveAddress(Address address);

  /// Remove an address by id.
  Future<void> deleteAddress(String id);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/admin/di/admin_account_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_ticket_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_list_item.dart';

import 'admin_account_controller_fakes.dart';

void main() {
  test('AdminUserDetailController loads detail, vehicles, drivers, documents, tickets, and payments', () async {
    final fake = FakeAdminAccountRepository()
      ..details = AdminUserDetails(<String, Object?>{'id': 'user-1', 'name': 'Admin User'})
      ..vehicles = <AdminVehicleListItem>[AdminVehicleListItem.fromRaw(<String, Object?>{'id': 'vehicle-1'})]
      ..drivers = <AdminDriverListItem>[AdminDriverListItem.fromRaw(<String, Object?>{'id': 'driver-1'})]
      ..documents = <AdminDocumentItem>[const AdminDocumentItem(<String, Object?>{'id': 'doc-1'})]
      ..tickets = <AdminTicketListItem>[const AdminTicketListItem(<String, Object?>{'id': 'ticket-1'})]
      ..payments = <AdminTransactionItem>[AdminTransactionItem.fromRaw(<String, Object?>{'id': 'payment-1'})];

    final container = ProviderContainer(
      overrides: [adminAccountRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final provider = adminUserDetailControllerProvider('user-1');
    final controller = container.read(provider.notifier);
    await controller.load();
    await controller.loadVehicles();
    await controller.loadDrivers();
    await controller.loadDocuments();
    await controller.loadTickets();
    await controller.loadPayments();

    final state = container.read(provider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.user?.fullName, 'Admin User');
    expect(state.vehicles, hasLength(1));
    expect(state.drivers, hasLength(1));
    expect(state.documents, hasLength(1));
    expect(state.tickets, hasLength(1));
    expect(state.payments, hasLength(1));
  });
}

import 'package:fleet_stack/core/models/admin_transaction_item.dart';

class UserTransactionsPage {
  final List<AdminTransactionItem> items;
  final int page;
  final int limit;
  final int total;

  const UserTransactionsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });
}

import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';

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

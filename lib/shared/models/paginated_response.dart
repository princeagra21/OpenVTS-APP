class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.total,
    this.page = 1,
    this.limit = 20,
    this.isFromCache = false,
  });

  final List<T> data;
  final int total;
  final int page;
  final int limit;
  final bool isFromCache;

  bool get hasMore => data.length < total;
}

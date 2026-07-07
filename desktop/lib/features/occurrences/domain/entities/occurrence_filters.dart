class OccurrenceFilters {
  const OccurrenceFilters({
    this.status,
    this.priority,
    this.categoryId,
    this.search,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });

  final String? status;
  final String? priority;
  final String? categoryId;
  final String? search;
  final String sortBy;
  final String sortOrder;

  OccurrenceFilters copyWith({
    String? status,
    bool clearStatus = false,
    String? priority,
    bool clearPriority = false,
    String? categoryId,
    bool clearCategoryId = false,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) {
    return OccurrenceFilters(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      search: search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

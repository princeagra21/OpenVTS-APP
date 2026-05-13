import 'package:open_vts/features/superadmin/presentation/layout/super_admin_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/features/superadmin/presentation/components/transactions/payments_screen.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_components.dart';
import 'package:open_vts/shared/widgets/top_bar.dart';

part of 'payments_screen.dart';

extension _PaymentsScreenBuild on _PaymentsScreenState {
  Widget _buildPaymentsScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(width) + 6;
    final topPadding = MediaQuery.of(context).padding.top;
    final cs = Theme.of(context).colorScheme;
    final scale = (width / 420).clamp(0.9, 1.0);
    final labelStyle = AppFonts.roboto(
      fontSize: 12 * scale,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: cs.onSurface.withOpacity(0.7),
    );
    final query = _searchController.text.trim().toLowerCase();
    final filteredTransactions = _transactions.where((t) {
      final status = t.status.toLowerCase();
      final matchesStatus =
          _statusFilter == 'All' ||
          (_statusFilter == 'Success' && status.contains('success')) ||
          (_statusFilter == 'Pending' &&
              (status.contains('pending') || status.contains('processing'))) ||
          (_statusFilter == 'Failed' &&
              (status.contains('fail') || status.contains('decline')));
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;
      final name = t.fromUserName.toLowerCase();
      final email = t.fromUserEmail.toLowerCase();
      final reference = (t.raw['reference']?.toString() ?? '').toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          reference.contains(query);
    }).toList();
    final totalTxns = _transactions.length;
    final success = _transactions.where((t) {
      final s = t.status.toLowerCase();
      return s.contains('success');
    }).toList();
    final pending = _transactions.where((t) {
      final s = t.status.toLowerCase();
      return s.contains('pending') || s.contains('processing');
    }).toList();
    final failed = _transactions.where((t) {
      final s = t.status.toLowerCase();
      return s.contains('fail') || s.contains('decline');
    }).toList();
    final revenue = success.fold<double>(
      0,
      (sum, t) => sum + _parseAmount(t.amount),
    );
    final successRate = totalTxns == 0
        ? 0
        : ((success.length / totalTxns) * 100).round();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: _refreshPayments,
              color: cs.primary,
              backgroundColor: cs.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  padding,
                  topPadding + AppUtils.appBarHeightCustom + 40,
                  padding,
                  (MediaQuery.of(context).padding.bottom + padding + 16)
                      .clamp(24.0, 96.0)
                      .toDouble(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment',
                                style: AppUtils.headlineSmallBase.copyWith(
                                  fontSize:
                                      AdaptiveUtils.getSubtitleFontSize(width) +
                                      2,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RecordManualPaymentScreen(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Record',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Admin', style: labelStyle),
                          const SizedBox(height: 8),
                          if (_loadingAdmins)
                            const AppShimmer(
                              width: double.infinity,
                              height: 52,
                              radius: 12,
                            )
                          else
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _pickAdminFilter(context, cs, scale),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs.onSurface.withOpacity(0.12),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _allAdminsSelected
                                            ? 'All Admins'
                                            : (_selectedAdmin != null
                                                  ? (_selectedAdmin!
                                                            .name
                                                            .isNotEmpty
                                                        ? _selectedAdmin!.name
                                                        : _selectedAdmin!
                                                              .email
                                                              .isNotEmpty
                                                        ? _selectedAdmin!.email
                                                        : _selectedAdmin!.id)
                                                  : 'All Admins'),
                                        maxLines: 2,
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                        style: AppFonts.roboto(
                                          fontSize: 14 * scale,
                                          height: 20 / 14,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.expand_more,
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text('Date Range', style: labelStyle),
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                _pickDateRangeFilter(context, cs, scale),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cs.onSurface.withOpacity(0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedRange ?? 'Select range',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.roboto(
                                        fontSize: 14 * scale,
                                        height: 20 / 14,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.expand_more,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                        AdaptiveUtils.getHorizontalPadding(width),
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: cs.onSurface.withOpacity(0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overview',
                            style: AppUtils.headlineSmallBase.copyWith(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          SizedBox(
                            height:
                                AdaptiveUtils.getLeftSectionSpacing(width) + 8,
                          ),
                          if (_loadingTransactions)
                            const AppShimmer(
                              width: double.infinity,
                              height: 120,
                              radius: 16,
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final spacing =
                                    AdaptiveUtils.getLeftSectionSpacing(width) +
                                    6;
                                final maxWidth = constraints.maxWidth;
                                final columns = 2;
                                final totalSpacing = spacing * (columns - 1);
                                final itemWidth =
                                    (maxWidth - totalSpacing) / columns;
                                final titleFontSize =
                                    AdaptiveUtils.getTitleFontSize(width) + 1;
                                final valueFontSize =
                                    AdaptiveUtils.getSubtitleFontSize(width) +
                                    4;
                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    _summaryCard(
                                      context,
                                      width: itemWidth,
                                      title: 'REVENUE',
                                      value: _formatInrCompact(revenue),
                                      titleSize: titleFontSize,
                                      valueSize: valueFontSize,
                                      icon: Symbols.payments,
                                      padding: spacing,
                                    ),
                                    _summaryCard(
                                      context,
                                      width: itemWidth,
                                      title: 'SUCCESSFUL',
                                      value: '${success.length}',
                                      titleSize: titleFontSize,
                                      valueSize: valueFontSize,
                                      icon: Symbols.check_circle,
                                      padding: spacing,
                                    ),
                                    _summaryCard(
                                      context,
                                      width: itemWidth,
                                      title: 'PENDING',
                                      value: '${pending.length}',
                                      titleSize: titleFontSize,
                                      valueSize: valueFontSize,
                                      icon: Symbols.schedule,
                                      padding: spacing,
                                    ),
                                    _summaryCard(
                                      context,
                                      width: itemWidth,
                                      title: 'FAILED',
                                      value: '${failed.length}',
                                      titleSize: titleFontSize,
                                      valueSize: valueFontSize,
                                      icon: Symbols.cancel,
                                      padding: spacing,
                                    ),
                                    _summaryCard(
                                      context,
                                      width: itemWidth,
                                      title: 'SUCCESS RATE',
                                      value: '$successRate%',
                                      titleSize: titleFontSize,
                                      valueSize: valueFontSize,
                                      icon: Symbols.percent,
                                      padding: spacing,
                                    ),
                                    _summaryCard(
                                      context,
                                      width: itemWidth,
                                      title: 'TOTAL TXNS',
                                      value: '$totalTxns',
                                      titleSize: titleFontSize,
                                      valueSize: valueFontSize,
                                      icon: Symbols.receipt_long,
                                      padding: spacing,
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Status',
                            style: AppUtils.headlineSmallBase.copyWith(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statusPill(
                                context,
                                label: 'Success',
                                value: '$successRate%',
                                color: cs.primary,
                                scale: scale,
                              ),
                              const SizedBox(width: 10),
                              _statusPill(
                                context,
                                label: 'Pending',
                                value:
                                    '${totalTxns == 0 ? 0 : ((pending.length / totalTxns) * 100).round()}%',
                                color: cs.primary.withOpacity(0.7),
                                scale: scale,
                              ),
                              const SizedBox(width: 10),
                              _statusPill(
                                context,
                                label: 'Failed',
                                value:
                                    '${totalTxns == 0 ? 0 : ((failed.length / totalTxns) * 100).round()}%',
                                color: cs.primary.withOpacity(0.5),
                                scale: scale,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: totalTxns == 0
                                  ? 0
                                  : (success.length / totalTxns).clamp(0, 1),
                              minHeight: 8,
                              backgroundColor: cs.onSurface.withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: cs.surfaceContainerHighest),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transactions',
                            style: AppUtils.headlineSmallBase.copyWith(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height:
                                AdaptiveUtils.getHorizontalPadding(width) * 3.5,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: AppFonts.roboto(
                                fontSize: 14 * scale,
                                height: 20 / 14,
                                color: cs.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search name, email, or reference',
                                hintStyle: AppFonts.roboto(
                                  color: cs.onSurface.withOpacity(0.5),
                                  fontSize: 12 * scale,
                                  height: 16 / 12,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: AdaptiveUtils.getIconSize(width),
                                  color: cs.onSurface,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal:
                                      AdaptiveUtils.getHorizontalPadding(width),
                                  vertical: AdaptiveUtils.getHorizontalPadding(
                                    width,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    final chosen = await showModalBottomSheet<String>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: cs.surface,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      builder: (ctx) {
                                        final items = [
                                          'All',
                                          'Success',
                                          'Pending',
                                          'Failed',
                                        ];
                                        return SafeArea(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              16,
                                              16,
                                              8,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 42,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: cs.onSurface
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          2,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Filter Status',
                                                  style: AppFonts.roboto(
                                                    fontWeight: FontWeight.w600,
                                                    color: cs.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  height:
                                                      MediaQuery.of(
                                                        ctx,
                                                      ).size.height *
                                                      0.7,
                                                  child: ListView.separated(
                                                    itemCount: items.length,
                                                    separatorBuilder: (_, __) =>
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                    itemBuilder: (_, index) {
                                                      final item = items[index];
                                                      return ListTile(
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                            ),
                                                        title: Text(
                                                          item,
                                                          style:
                                                              AppFonts.roboto(
                                                                fontSize:
                                                                    14 * scale,
                                                                height: 20 / 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        onTap: () =>
                                                            Navigator.pop(
                                                              ctx,
                                                              item,
                                                            ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                    if (chosen != null) {
                                      updateLocalUiState(this, () => _statusFilter = chosen);
                                      _onFilterChanged();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: cs.onSurface.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.tune,
                                          size: 16 * scale,
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Filter',
                                          style: AppFonts.roboto(
                                            fontSize: 12 * scale,
                                            height: 16 / 12,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _loadTransactions,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: cs.onSurface.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.refresh,
                                          size: 16 * scale,
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Refresh',
                                          style: AppFonts.roboto(
                                            fontSize: 12 * scale,
                                            height: 16 / 12,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () =>
                                      _showExportOptions(filteredTransactions),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: cs.onSurface.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.upload,
                                          size: 16 * scale,
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Export',
                                          style: AppFonts.roboto(
                                            fontSize: 12 * scale,
                                            height: 16 / 12,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...filteredTransactions.map((t) {
                            final name = t.fromUserName.isNotEmpty
                                ? t.fromUserName
                                : (t.actorName.isNotEmpty ? t.actorName : '—');
                            final dateText = _formatDateTime(t.time);
                            final amount = _formatCurrency(
                              t.amount,
                              t.currency,
                            );
                            final (statusText, statusIcon, statusColor) =
                                _statusMeta(t.status, cs);
                            final mode = _titleCase(
                              t.raw['paymentMode']?.toString() ?? '—',
                            );
                            final type = _titleCase(
                              t.raw['paymentType']?.toString() ?? '—',
                            );
                            final reference =
                                t.raw['reference']?.toString() ?? '—';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 40 * scale,
                                          height: 40 * scale,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? cs.surfaceContainerHighest
                                                : Colors.grey.shade50,
                                            border: Border.all(
                                              color: cs.outline.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.person_outline,
                                            size: 18 * scale,
                                            color: cs.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: AppFonts.roboto(
                                                  fontSize: 14 * scale,
                                                  height: 20 / 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: cs.onSurface,
                                                ),
                                                maxLines: 2,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                dateText,
                                                style: AppFonts.roboto(
                                                  fontSize: 12 * scale,
                                                  height: 16 / 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: cs.onSurface
                                                      .withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              amount,
                                              style: AppFonts.roboto(
                                                fontSize: 14 * scale,
                                                height: 20 / 14,
                                                fontWeight: FontWeight.w700,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? cs.surfaceContainerHighest
                                                    : Colors.grey.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    statusIcon,
                                                    size: 14 * scale,
                                                    color: statusColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    statusText,
                                                    style: AppFonts.roboto(
                                                      fontSize: 11 * scale,
                                                      height: 14 / 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: cs.onSurface.withOpacity(
                                                  0.12,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Mode',
                                                  style: AppFonts.roboto(
                                                    fontSize: 11 * scale,
                                                    height: 14 / 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: cs.onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  mode,
                                                  style: AppFonts.roboto(
                                                    fontSize: 13 * scale,
                                                    height: 18 / 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: cs.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: cs.onSurface.withOpacity(
                                                  0.12,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Type',
                                                  style: AppFonts.roboto(
                                                    fontSize: 11 * scale,
                                                    height: 14 / 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: cs.onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  type,
                                                  style: AppFonts.roboto(
                                                    fontSize: 13 * scale,
                                                    height: 18 / 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: cs.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: cs.onSurface.withOpacity(0.12),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '# Reference',
                                            style: AppFonts.roboto(
                                              fontSize: 11 * scale,
                                              height: 14 / 11,
                                              fontWeight: FontWeight.w500,
                                              color: cs.onSurface.withOpacity(
                                                0.6,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            reference,
                                            style: AppFonts.roboto(
                                              fontSize: 13 * scale,
                                              height: 18 / 13,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: padding,
            right: padding,
            top: 0,
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? OpenVtsColors.panelDark
                  : OpenVtsColors.panelLight,
              child: const SuperAdminHomeAppBar(
                title: 'Payments',
                leadingIcon: Icons.credit_card,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBar(
              title: 'Payments',
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

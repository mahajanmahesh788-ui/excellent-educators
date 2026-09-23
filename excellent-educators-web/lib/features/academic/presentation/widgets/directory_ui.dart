import 'dart:async';

import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class DirectoryToolbar extends StatefulWidget {
  const DirectoryToolbar({
    super.key,
    required this.searchHint,
    required this.onSearchChanged,
    this.searchQuery = '',
    this.levelItems,
    this.selectedLevelId,
    this.onLevelChanged,
    this.levelLabel = AppStrings.level,
    this.statusItems,
    this.selectedStatus,
    this.onStatusChanged,
    this.attentionItems,
    this.selectedAttention,
    this.onAttentionChanged,
    this.attentionLabel = AppStrings.needsAttention,
    this.total,
    this.page,
    this.perPage,
    this.onPageChanged,
  });

  final String searchHint;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<DropdownMenuItem<String>>? levelItems;
  final String? selectedLevelId;
  final ValueChanged<String?>? onLevelChanged;
  final String levelLabel;
  final List<DropdownMenuItem<String>>? statusItems;
  final String? selectedStatus;
  final ValueChanged<String?>? onStatusChanged;
  final List<DropdownMenuItem<String>>? attentionItems;
  final String? selectedAttention;
  final ValueChanged<String?>? onAttentionChanged;
  final String attentionLabel;
  final int? total;
  final int? page;
  final int? perPage;
  final ValueChanged<int>? onPageChanged;

  @override
  State<DirectoryToolbar> createState() => _DirectoryToolbarState();
}

class _DirectoryToolbarState extends State<DirectoryToolbar> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(DirectoryToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_searchFocusNode.hasFocus && widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
      _searchController.selection = TextSelection.collapsed(offset: widget.searchQuery.length);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => widget.onSearchChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    final showPagination = widget.total != null &&
        widget.perPage != null &&
        widget.page != null &&
        widget.onPageChanged != null &&
        widget.total! > widget.perPage!;
    final lastPage = showPagination ? (widget.total! / widget.perPage!).ceil() : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth < 640;
            return Wrap(
          spacing: 8,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: fullWidth ? constraints.maxWidth : 280,
              child: _ToolbarLabeledField(
                label: AppStrings.search,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),
            if (widget.levelItems != null && widget.onLevelChanged != null)
              _ToolbarDropdown<String?>(
                label: widget.levelLabel,
                width: fullWidth ? constraints.maxWidth : 200,
                value: widget.selectedLevelId,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text(AppStrings.allLevels)),
                  ...widget.levelItems!,
                ],
                onChanged: widget.onLevelChanged,
              ),
            if (widget.statusItems != null && widget.onStatusChanged != null)
              _ToolbarDropdown<String?>(
                label: AppStrings.status2,
                width: fullWidth ? constraints.maxWidth : 140,
                value: widget.selectedStatus,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text(AppStrings.all)),
                  ...widget.statusItems!,
                ],
                onChanged: widget.onStatusChanged,
              ),
            if (widget.attentionItems != null && widget.onAttentionChanged != null)
              _ToolbarDropdown<String?>(
                label: widget.attentionLabel,
                width: fullWidth ? constraints.maxWidth : 220,
                value: widget.selectedAttention,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text(AppStrings.allStudents)),
                  ...widget.attentionItems!,
                ],
                onChanged: widget.onAttentionChanged,
              ),
          ],
            );
          },
        ),
        if (showPagination) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${widget.total} total · page ${widget.page} of $lastPage',
                style: const TextStyle(color: Brand.muted, fontSize: 12),
              ),
              const Spacer(),
              IconButton(
                tooltip: AppStrings.previousPage,
                onPressed: widget.page! > 1 ? () => widget.onPageChanged!(widget.page! - 1) : null,
                icon: const Icon(Icons.chevron_left),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: AppStrings.nextPage,
                onPressed: widget.page! < lastPage ? () => widget.onPageChanged!(widget.page! + 1) : null,
                icon: const Icon(Icons.chevron_right),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ToolbarLabeledField extends StatelessWidget {
  const _ToolbarLabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Brand.muted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _ToolbarDropdown<T> extends StatelessWidget {
  const _ToolbarDropdown({
    required this.label,
    required this.width,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final double width;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _ToolbarLabeledField(
        label: label,
        child: DropdownButtonFormField<T>(
          key: ValueKey(value),
          isExpanded: true,
          initialValue: value,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class DetailSection extends StatelessWidget {
  const DetailSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE6DCCB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(isMobile ? 12 : 14, isMobile ? 10 : 12, isMobile ? 12 : 14, isMobile ? 8 : 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE6DCCB))),
            ),
            child: Text(
              title,
              style: TextStyle(color: Brand.navy, fontWeight: FontWeight.w700, fontSize: isMobile ? 14 : 15),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 12 : 14, isMobile ? 8 : 10, isMobile ? 12 : 14, isMobile ? 10 : 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Brand.muted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(label, style: const TextStyle(color: Brand.muted, fontSize: 13)),
                ),
                Expanded(
                  child: Text(value, style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
    );
  }
}

class ActiveFilterBanner extends StatelessWidget {
  const ActiveFilterBanner({
    super.key,
    required this.label,
    required this.onClear,
  });

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFFBF6EA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: Brand.gold),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.filter_alt, size: 16, color: Brand.goldDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Filter: $label',
                  style: const TextStyle(color: Brand.navy, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(AppStrings.clear, style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttentionCard extends StatelessWidget {
  const AttentionCard({
    super.key,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final needsAttention = count > 0;
    return Material(
      color: needsAttention ? const Color(0xFFFBF6EA) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        side: BorderSide(color: needsAttention ? Brand.gold : const Color(0xFFE6DCCB)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 14,
            vertical: isMobile ? 8 : 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Brand.navy,
                    fontSize: isMobile ? 12.5 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: needsAttention ? Brand.goldDark : Brand.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 16 : 18,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: isMobile ? 16 : 18,
                color: needsAttention ? Brand.goldDark : Brand.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 900;
    final wide = width >= 900;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: wide ? 4 : (isTablet ? 4 : 2),
      mainAxisSpacing: isMobile ? 6 : 8,
      crossAxisSpacing: isMobile ? 6 : 8,
      mainAxisExtent: isMobile ? 58 : (isTablet ? 64 : null),
      childAspectRatio: 2.4,
      children: children,
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
    this.accentColor,
    this.subtitle,
    this.badge,
  });

  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? accentColor;
  final String? subtitle;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final cardContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 14,
        vertical: isMobile ? 6 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: isMobile ? 14 : 16, color: accentColor ?? Brand.muted),
                SizedBox(width: isMobile ? 4 : 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: accentColor ?? Brand.muted,
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                badge!,
              ] else if (onTap != null) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: isMobile ? 12 : 14,
                  color: (accentColor ?? Brand.muted).withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: Brand.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 15 : 22,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      color: Brand.muted,
                      fontSize: isMobile ? 10 : 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        side: BorderSide(
          color: accentColor != null ? accentColor!.withValues(alpha: 0.35) : const Color(0xFFE6DCCB),
        ),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              hoverColor: (accentColor ?? Brand.gold).withValues(alpha: 0.08),
              child: cardContent,
            )
          : cardContent,
    );
  }
}

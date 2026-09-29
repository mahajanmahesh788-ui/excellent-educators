import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqItem {
  const FaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

class FaqCategory {
  const FaqCategory({
    required this.title,
    required this.items,
  });

  final String title;
  final List<FaqItem> items;
}

class FaqCategoryView extends StatefulWidget {
  const FaqCategoryView({
    super.key,
    required this.body,
    this.supportEmail = 'Excellenteducator555@gmail.com',
    this.supportPhone = '+91 85589 51555',
  });

  final String body;
  final String supportEmail;
  final String supportPhone;

  @override
  State<FaqCategoryView> createState() => _FaqCategoryViewState();
}

class _FaqCategoryViewState extends State<FaqCategoryView> {
  String _searchQuery = '';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  // Stores expanded question keys: "categoryIndex_itemIndex"
  final Set<String> _expandedKeys = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FaqCategory> _parseFaq(String rawBody) {
    final lines = rawBody.split('\n');
    final categories = <FaqCategory>[];

    String currentCategory = 'General Questions';
    final currentItems = <FaqItem>[];

    String? currentQ;
    final answerBuffer = StringBuffer();

    void flushCurrentQA() {
      if (currentQ != null) {
        final a = answerBuffer.toString().trim();
        if (a.isNotEmpty) {
          currentItems.add(FaqItem(question: currentQ!, answer: a));
        }
        currentQ = null;
        answerBuffer.clear();
      }
    }

    void flushCategory() {
      flushCurrentQA();
      if (currentItems.isNotEmpty) {
        categories.add(FaqCategory(
          title: currentCategory,
          items: List<FaqItem>.from(currentItems),
        ));
        currentItems.clear();
      }
    }

    final categoryHeaderRegex = RegExp(
      r'^(?:\d+[\.\)]\s+|#{1,3}\s+|Category:\s*)([^\n]+)$',
      caseSensitive: false,
    );

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.toLowerCase().startsWith('last updated:')) {
        continue;
      }

      // Check if it's a category header
      final catMatch = categoryHeaderRegex.firstMatch(line);
      final isNumberedCategory = RegExp(r'^\d+\.\s+[A-Za-z]').hasMatch(line);

      if ((catMatch != null || isNumberedCategory) &&
          !line.toLowerCase().startsWith('q:') &&
          !line.toLowerCase().startsWith('a:')) {
        flushCategory();
        var catName = catMatch?.group(1) ?? line;
        catName = catName.replaceAll(RegExp(r'^\d+[\.\)]\s*'), '').trim();
        currentCategory = catName;
        continue;
      }

      // Check if it's a question
      if (line.startsWith(RegExp(r'^Q\s*:\s*', caseSensitive: false)) ||
          line.startsWith(RegExp(r'^\*\*Q\s*:\s*\*\*', caseSensitive: false))) {
        flushCurrentQA();
        currentQ = line
            .replaceFirst(RegExp(r'^\*\*Q\s*:\s*\*\*\s*', caseSensitive: false), '')
            .replaceFirst(RegExp(r'^Q\s*:\s*', caseSensitive: false), '')
            .trim();
        continue;
      }

      // Check if it's an answer
      if (line.startsWith(RegExp(r'^A\s*:\s*', caseSensitive: false)) ||
          line.startsWith(RegExp(r'^\*\*A\s*:\s*\*\*', caseSensitive: false))) {
        final ansText = line
            .replaceFirst(RegExp(r'^\*\*A\s*:\s*\*\*\s*', caseSensitive: false), '')
            .replaceFirst(RegExp(r'^A\s*:\s*', caseSensitive: false), '')
            .trim();
        answerBuffer.writeln(ansText);
        continue;
      }

      // Continuation of answer
      if (currentQ != null) {
        answerBuffer.writeln(line);
      }
    }

    flushCategory();
    return categories;
  }

  IconData _iconForCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('admission') || lower.contains('enroll')) {
      return Icons.school_outlined;
    }
    if (lower.contains('academic') || lower.contains('teaching') || lower.contains('method')) {
      return Icons.auto_stories_outlined;
    }
    if (lower.contains('online') || lower.contains('class') || lower.contains('tech')) {
      return Icons.laptop_chromebook_outlined;
    }
    if (lower.contains('fee') || lower.contains('payment') || lower.contains('receipt')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (lower.contains('parent') || lower.contains('progress') || lower.contains('track')) {
      return Icons.family_restroom_outlined;
    }
    if (lower.contains('account') || lower.contains('security') || lower.contains('privacy')) {
      return Icons.verified_user_outlined;
    }
    if (lower.contains('contact') || lower.contains('support') || lower.contains('help')) {
      return Icons.headset_mic_outlined;
    }
    return Icons.help_outline_rounded;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _parseFaq(widget.body);

    if (categories.isEmpty) {
      return SelectableText(
        widget.body,
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: AppColors.textSecondary,
        ),
      );
    }

    final query = _searchQuery.trim().toLowerCase();

    // Filter categories based on category filter and search query
    final filteredCategories = <FaqCategory>[];
    var totalQuestions = 0;

    for (final cat in categories) {
      totalQuestions += cat.items.length;

      if (_selectedCategory != null && cat.title != _selectedCategory) {
        continue;
      }

      if (query.isEmpty) {
        filteredCategories.add(cat);
      } else {
        final matchingItems = cat.items.where((item) {
          return item.question.toLowerCase().contains(query) ||
              item.answer.toLowerCase().contains(query);
        }).toList();

        if (matchingItems.isNotEmpty) {
          filteredCategories.add(FaqCategory(
            title: cat.title,
            items: matchingItems,
          ));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search questions, topics, or keywords (e.g. fees, offline, recording)...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Brand.navy),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('All Topics ($totalQuestions)'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                  selectedColor: Brand.navy,
                  labelStyle: TextStyle(
                    color: _selectedCategory == null ? Colors.white : Brand.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: _selectedCategory == null ? Brand.navy : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              for (final cat in categories) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      _iconForCategory(cat.title),
                      size: 16,
                      color: _selectedCategory == cat.title ? Colors.white : Brand.navy,
                    ),
                    label: Text('${cat.title} (${cat.items.length})'),
                    selected: _selectedCategory == cat.title,
                    onSelected: (_) => setState(() {
                      if (_selectedCategory == cat.title) {
                        _selectedCategory = null;
                      } else {
                        _selectedCategory = cat.title;
                      }
                    }),
                    selectedColor: Brand.navy,
                    labelStyle: TextStyle(
                      color: _selectedCategory == cat.title ? Colors.white : Brand.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _selectedCategory == cat.title ? Brand.navy : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Empty state when search yields no matches
        if (filteredCategories.isEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No questions found matching "$_searchQuery"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Brand.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Try searching for another keyword or browse all topics.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedCategory = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset All Filters'),
                ),
              ],
            ),
          ),
        ] else ...[
          // Render each Category and its Questions
          for (var cIdx = 0; cIdx < filteredCategories.length; cIdx++) ...[
            _CategorySection(
              category: filteredCategories[cIdx],
              categoryIndex: cIdx,
              categoryIcon: _iconForCategory(filteredCategories[cIdx].title),
              expandedKeys: _expandedKeys,
              onToggleItem: (key) {
                setState(() {
                  if (_expandedKeys.contains(key)) {
                    _expandedKeys.remove(key);
                  } else {
                    _expandedKeys.add(key);
                  }
                });
              },
            ),
            const SizedBox(height: 24),
          ],
        ],

        const SizedBox(height: 16),

        // Helpdesk & Inquiries Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Brand.navy,
                Brand.navy.withValues(alpha: 0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Brand.navy.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Still have questions?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Our academic counselors and support desk are always here to assist you.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final digits = widget.supportPhone.replaceAll(RegExp(r'\D'), '');
                      _launchUrl('https://wa.me/$digits?text=Hello%20Excellent%20Educators%2C%20I%20have%20a%20query%20regarding%20courses.');
                    },
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp Us'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    onPressed: () {
                      final digits = widget.supportPhone.replaceAll(RegExp(r'\D'), '');
                      _launchUrl('tel:$digits');
                    },
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: Text(widget.supportPhone),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    onPressed: () => _launchUrl('mailto:${widget.supportEmail}'),
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text('Email Support'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.categoryIndex,
    required this.categoryIcon,
    required this.expandedKeys,
    required this.onToggleItem,
  });

  final FaqCategory category;
  final int categoryIndex;
  final IconData categoryIcon;
  final Set<String> expandedKeys;
  final ValueChanged<String> onToggleItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header Badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Brand.navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(categoryIcon, size: 20, color: Brand.navy),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Brand.navy,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Brand.navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${category.items.length} questions',
                style: const TextStyle(
                  color: Brand.navy,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // List of Expandable Cards
        for (var i = 0; i < category.items.length; i++)
          _FaqExpandableCard(
            item: category.items[i],
            itemKey: '${categoryIndex}_$i',
            isExpanded: expandedKeys.contains('${categoryIndex}_$i'),
            onToggle: () => onToggleItem('${categoryIndex}_$i'),
          ),
      ],
    );
  }
}

class _FaqExpandableCard extends StatelessWidget {
  const _FaqExpandableCard({
    required this.item,
    required this.itemKey,
    required this.isExpanded,
    required this.onToggle,
  });

  final FaqItem item;
  final String itemKey;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? Brand.navy.withValues(alpha: 0.35)
              : Colors.grey.shade200,
          width: isExpanded ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? Brand.navy.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: isExpanded ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onToggle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 1, right: 12),
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? Brand.navy
                            : Brand.navy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Q',
                        style: TextStyle(
                          color: isExpanded ? Colors.white : Brand.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.question,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isExpanded
                              ? Brand.navy
                              : AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isExpanded
                            ? Brand.navy
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade200,
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: SelectableText(
                    item.answer,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

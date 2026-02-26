import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vetting_provider.dart';

import '../theme/app_theme.dart';
import '../models/question.dart';
import '../widgets/modern_header.dart';
import '../widgets/glass_container.dart';

class VettingScreen extends ConsumerStatefulWidget {
  const VettingScreen({super.key});

  @override
  ConsumerState<VettingScreen> createState() => _VettingScreenState();
}

class _VettingScreenState extends ConsumerState<VettingScreen> {
  // Design Variations
  final List<String> _designs = ['Classic', 'Swipe'];
  String _selectedDesign = 'Classic';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vettingProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(vettingProvider.notifier).loadQuestions();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ModernHeader(
                title: 'Vetting',
                subtitle: 'Review Questions',
                actions: [
                  _buildDesignSwitcher(context),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Filter Header and Tabs
                  if (true) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12, left: 4),
                      child: Text(
                        'FILTER QUESTIONS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: AppTheme.modernTextSecondary,
                        ),
                      ),
                    ),
                    _buildStatusTabs(state.statusFilter),
                    const SizedBox(height: 24),
                  ],
                  state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.questions.isEmpty
                      ? _buildEmptyState()
                      : _buildSelectedDesign(state),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: Colors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'All Caught Up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          Text(
            'No questions to vet in this category',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs(String currentFilter) {
    return GlassContainer(
      padding: const EdgeInsets.all(4),
      borderRadius: 16,
      child: Row(
        children: [
          _buildTab('pending', 'Pending', currentFilter == 'pending'),
          _buildTab('approved', 'Approved', currentFilter == 'approved'),
          _buildTab('rejected', 'Rejected', currentFilter == 'rejected'),
        ],
      ),
    );
  }

  Widget _buildTab(String status, String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            ref.read(vettingProvider.notifier).loadQuestions(status: status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.black54,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesignSwitcher(BuildContext context) {
    return _buildDropdown(
      context,
      value: _selectedDesign,
      items: _designs,
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedDesign = value);
        }
      },
      icon: Icons.style_rounded,
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(icon, size: 18),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          isDense: true,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSelectedDesign(VettingState state) {
    switch (_selectedDesign) {
      case 'Swipe':
        return _buildSwipeDesign(state);
      case 'Classic':
      default:
        return _buildClassicDesign(state);
    }
  }

  // --- Classic Design ---
  Widget _buildClassicDesign(VettingState state) {
    final question = state.questions[state.currentIndex];

    return Column(
      children: [
        // Header row with question number and tags
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${state.currentIndex + 1} of ${state.questions.length}',
              style: const TextStyle(
                color: AppTheme.modernTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Wrap(
              spacing: 6,
              children: [
                _buildTag(question.type.toUpperCase(), AppTheme.modernAccent),
                if (question.difficulty != null)
                  _buildTag(
                    question.difficulty!,
                    _difficultyColor(question.difficulty!),
                  ),
                if (question.marks != null)
                  _buildTag('${question.marks} marks', Colors.deepPurple),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Main question card
        GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Question text
              Text(
                question.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.5,
                ),
              ),
              // MCQ Options
              if (question.options != null) ...[
                const SizedBox(height: 24),
                ...['a', 'b', 'c', 'd']
                    .where((k) => question.options!.containsKey(k))
                    .map(
                      (key) => _buildOptionTile(
                        key.toUpperCase(),
                        question.options![key]?.toString() ?? '',
                        question.correctAnswer?.toUpperCase() ==
                            key.toUpperCase(),
                      ),
                    ),
              ],
              // Essay/Short specific
              if (question.evaluationCriteria != null) ...[
                const SizedBox(height: 16),
                _buildQuestionMeta('Evaluation', question.evaluationCriteria!),
              ],
              if (question.wordLimit != null)
                _buildQuestionMeta('Word Limit', '${question.wordLimit}'),
              if (question.expectedPoints != null &&
                  question.expectedPoints!.isNotEmpty)
                _buildQuestionMeta(
                  'Expected Points',
                  question.expectedPoints!.join(', '),
                ),
              if (question.keyPoints != null && question.keyPoints!.isNotEmpty)
                _buildQuestionMeta(
                  'Key Points',
                  question.keyPoints!.join(', '),
                ),
              // Divider
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.black.withOpacity(0.05),
              ),
              const SizedBox(height: 12),
              // Meta info
              _buildQuestionMeta('Subject', question.courseCode ?? 'N/A'),
              _buildQuestionMeta('Topic', question.topic ?? 'N/A'),
              if (question.coMap.isNotEmpty)
                _buildQuestionMeta(
                  'COs',
                  question.coMap.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join(', '),
                ),
              if (question.loList.isNotEmpty)
                _buildQuestionMeta('LOs', question.loList.join(', ')),
              if (question.referenceMaterial != null &&
                  question.referenceMaterial!.isNotEmpty)
                _buildQuestionMeta(
                  'Reference',
                  '${question.referenceMaterial} (Page ${question.referencePage ?? 'N/A'})',
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildNavigationControls(state),
        if (state.statusFilter == 'pending') ...[
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ],
    );
  }

  // --- Swipe Design (Tinder-style) ---
  Widget _buildSwipeDesign(VettingState state) {
    final question = state.questions[state.currentIndex];
    final isPending = state.statusFilter == 'pending';
    return Dismissible(
      key: ValueKey(question.id),
      direction: isPending
          ? DismissDirection.horizontal
          : DismissDirection.none,
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 32),
        child: const Icon(Icons.cancel_outlined, color: Colors.white, size: 40),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF34C759),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 32),
        child: const Icon(
          Icons.check_circle_outline_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ref
              .read(vettingProvider.notifier)
              .vetCurrentQuestion(VettingAction.accept);
        } else {
          ref
              .read(vettingProvider.notifier)
              .vetCurrentQuestion(VettingAction.reject);
        }
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tags row
            Wrap(
              spacing: 6,
              children: [
                _buildTag(question.type.toUpperCase(), Colors.blue),
                if (question.difficulty != null)
                  _buildTag(
                    question.difficulty!,
                    _difficultyColor(question.difficulty!),
                  ),
                if (question.marks != null)
                  _buildTag('${question.marks} marks', Colors.deepPurple),
                _buildTag(
                  state.statusFilter.toUpperCase(),
                  Colors.orange,
                  isOutline: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Question text
            Text(
              question.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            // MCQ Options
            if (question.options != null) ...[
              const SizedBox(height: 20),
              ...['a', 'b', 'c', 'd']
                  .where((k) => question.options!.containsKey(k))
                  .map(
                    (key) => _buildOptionTile(
                      key.toUpperCase(),
                      question.options![key]?.toString() ?? '',
                      question.correctAnswer?.toUpperCase() ==
                          key.toUpperCase(),
                    ),
                  ),
            ],
            // Essay/Short specific
            if (question.evaluationCriteria != null) ...[
              const SizedBox(height: 12),
              _buildQuestionMeta('Evaluation', question.evaluationCriteria!),
            ],
            if (question.wordLimit != null)
              _buildQuestionMeta('Word Limit', '${question.wordLimit}'),
            if (question.expectedPoints != null &&
                question.expectedPoints!.isNotEmpty)
              _buildQuestionMeta(
                'Expected Points',
                question.expectedPoints!.join(', '),
              ),
            if (question.keyPoints != null && question.keyPoints!.isNotEmpty)
              _buildQuestionMeta('Key Points', question.keyPoints!.join(', ')),
            // Divider + meta
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.black.withOpacity(0.05),
            ),
            const SizedBox(height: 10),
            _buildQuestionMeta('Subject', question.courseCode ?? 'N/A'),
            _buildQuestionMeta('Topic', question.topic ?? 'N/A'),
            if (question.coMap.isNotEmpty)
              _buildQuestionMeta(
                'COs',
                question.coMap.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join(', '),
              ),
            if (question.loList.isNotEmpty)
              _buildQuestionMeta('LOs', question.loList.join(', ')),
            if (question.referenceMaterial != null &&
                question.referenceMaterial!.isNotEmpty)
              _buildQuestionMeta(
                'Reference',
                '${question.referenceMaterial} (Page ${question.referencePage ?? 'N/A'})',
              ),
            const SizedBox(height: 12),
            if (isPending)
              const Text(
                'Swipe left to Approve, right to Reject',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black26, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildTag(String text, Color color, {bool isOutline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: isOutline ? Border.all(color: color.withOpacity(0.5)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNavigationControls(VettingState state, {bool isDark = false}) {
    final Color iconColor = isDark ? Colors.white : Colors.black54;
    final Color textColor = isDark ? Colors.white70 : Colors.black45;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: state.currentIndex > 0
              ? () => ref.read(vettingProvider.notifier).previousQuestion()
              : null,
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor),
        ),
        Text(
          '${state.currentIndex + 1} / ${state.questions.length}',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        IconButton(
          onPressed: state.currentIndex < state.questions.length - 1
              ? () => ref.read(vettingProvider.notifier).nextQuestion()
              : null,
          icon: Icon(Icons.arrow_forward_ios_rounded, color: iconColor),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Reject',
                icon: Icons.close_rounded,
                color: const Color(0xFFFF3B30),
                onPressed: () => ref
                    .read(vettingProvider.notifier)
                    .vetCurrentQuestion(VettingAction.reject),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                label: 'Approve',
                icon: Icons.check_rounded,
                color: const Color(0xFF34C759),
                onPressed: () => ref
                    .read(vettingProvider.notifier)
                    .vetCurrentQuestion(VettingAction.accept),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => ref
              .read(vettingProvider.notifier)
              .vetCurrentQuestion(VettingAction.skip),
          child: const Text(
            'Skip for Now',
            style: TextStyle(
              color: AppTheme.modernTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionMeta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(String label, String text, bool isCorrect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xFF34C759).withOpacity(0.1)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF34C759).withOpacity(0.4)
              : Colors.black.withOpacity(0.06),
          width: isCorrect ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCorrect
                  ? const Color(0xFF34C759)
                  : Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: isCorrect ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isCorrect ? const Color(0xFF2D9F46) : Colors.black87,
                fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
          if (isCorrect)
            const Icon(Icons.check_circle, color: Color(0xFF34C759), size: 20),
        ],
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF34C759);
      case 'medium':
        return Colors.orange;
      case 'hard':
        return const Color(0xFFFF3B30);
      default:
        return Colors.grey;
    }
  }
}

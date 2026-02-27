import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_header.dart';
import '../widgets/glass_container.dart';
import '../providers/generation_provider.dart';
import '../providers/courses_provider.dart';
import '../providers/rubrics_provider.dart';
import '../models/course.dart';

import '../services/export_service.dart';
import 'rubric_editor_screen.dart';

class GenerateScreen extends ConsumerStatefulWidget {
  const GenerateScreen({super.key});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  final List<String> _cos = ['CO1', 'CO2', 'CO3', 'CO4', 'CO5'];
  final List<String> _los = ['LO1', 'LO2', 'LO3', 'LO4', 'LO5'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(coursesProvider.notifier).loadCourses();
      ref.read(rubricsProvider.notifier).loadRubrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final genState = ref.watch(generationProvider);
    final courses = ref.watch(coursesProvider);
    final rubState = ref.watch(rubricsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ModernHeader(
              title: 'Generate Paper',
              subtitle: 'AI-Powered Orchestration',
              actions: [
                if (genState.generatedQuestions.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () =>
                        ref.read(generationProvider.notifier).reset(),
                    tooltip: 'Start Over',
                  ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (genState.error != null) _buildErrorCard(genState.error!),

                if (genState.generatedQuestions.isEmpty && !genState.isLoading)
                  ..._buildRubricsPanel(rubState),

                if (genState.generatedQuestions.isEmpty && !genState.isLoading)
                  ..._buildConfigForm(courses, genState)
                else if (genState.isLoading)
                  _buildLoadingState()
                else
                  ..._buildResults(genState),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRubricsPanel(RubricsState rubState) {
    return [
      // Create Rubric Button
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RubricEditorScreen()),
            );
            ref.read(rubricsProvider.notifier).loadRubrics();
          },
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Create Rubric',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.modernAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),

      // Saved Rubrics Section
      _buildSectionHeader('SAVED RUBRICS'),

      // Search bar
      GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Search rubrics...',
            prefixIcon: Icon(Icons.search, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (val) =>
              ref.read(rubricsProvider.notifier).updateSearch(val),
        ),
      ),
      const SizedBox(height: 12),

      // Rubric list
      if (rubState.isLoading)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        )
      else if (rubState.rubrics.isEmpty)
        GlassContainer(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No rubrics yet',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          ),
        )
      else ...[
        ...rubState.rubrics.map(
          (rubric) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassContainer(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.modernAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: AppTheme.modernAccent,
                    size: 20,
                  ),
                ),
                title: Text(
                  rubric.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${rubric.courseCode} · ${rubric.total}Q · ${rubric.questionStyle}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Rubric'),
                            content: const Text(
                              'Are you sure you want to delete this rubric?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          await ref
                              .read(rubricsProvider.notifier)
                              .deleteRubric(rubric.id);
                        }
                      },
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RubricEditorScreen(existingRubric: rubric),
                    ),
                  );
                  ref.read(rubricsProvider.notifier).loadRubrics();
                },
              ),
            ),
          ),
        ),

        // Pagination
        if (rubState.totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: rubState.currentPage > 1
                      ? () => ref
                            .read(rubricsProvider.notifier)
                            .loadRubrics(page: rubState.currentPage - 1)
                      : null,
                ),
                Text(
                  '${rubState.currentPage} / ${rubState.totalPages}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: rubState.currentPage < rubState.totalPages
                      ? () => ref
                            .read(rubricsProvider.notifier)
                            .loadRubrics(page: rubState.currentPage + 1)
                      : null,
                ),
              ],
            ),
          ),
      ],
      const SizedBox(height: 32),
      const Divider(),
      const SizedBox(height: 16),
      _buildSectionHeader('QUICK GENERATE'),
    ];
  }

  List<Widget> _buildConfigForm(
    List<Course> courses,
    GenerationState genState,
  ) {
    return [
      _buildSectionHeader('SUBJECT & MARKS'),
      GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDropdownField(
              'Subject',
              genState.courseCode,
              courses.map((e) => e.code).toList(),
              (val) =>
                  ref.read(generationProvider.notifier).updateCourseCode(val!),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    'Marks per Q',
                    genState.marks,
                    (val) =>
                        ref.read(generationProvider.notifier).updateMarks(val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberField(
                    'Total Questions',
                    genState.total,
                    (val) =>
                        ref.read(generationProvider.notifier).updateTotal(val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTopicSelector(genState),
            const SizedBox(height: 20),
            _buildDropdownField(
              'Question Style',
              genState.questionStyle,
              ['Analytical', 'Theory', 'Hybrid'],
              (val) => ref
                  .read(generationProvider.notifier)
                  .updateQuestionStyle(val!),
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),
      _buildSectionHeader(
        'CO DISTRIBUTION',
        current: genState.coSum,
        target: genState.total,
      ),
      GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: _cos
              .map(
                (co) => _buildDistributionRow(
                  co,
                  genState.coDistribution[co] ?? 0,
                  (genState.coDistribution[co] ?? 0) +
                      genState.coDistribution.entries
                          .where(
                            (e) =>
                                e.key != co && !genState.locks.contains(e.key),
                          )
                          .fold(0, (sum, e) => sum + e.value),
                  genState.locks.contains(co),
                  () => ref.read(generationProvider.notifier).toggleLock(co),
                  (val) => ref
                      .read(generationProvider.notifier)
                      .updateCoDistribution(co, val),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 32),
      _buildSectionHeader(
        'LO DISTRIBUTION',
        current: genState.loSum,
        target: genState.total,
      ),
      GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: _los
              .map(
                (lo) => _buildDistributionRow(
                  lo,
                  genState.loDistribution[lo] ?? 0,
                  (genState.loDistribution[lo] ?? 0) +
                      genState.loDistribution.entries
                          .where(
                            (e) =>
                                e.key != lo && !genState.locks.contains(e.key),
                          )
                          .fold(0, (sum, e) => sum + e.value),
                  genState.locks.contains(lo),
                  () => ref.read(generationProvider.notifier).toggleLock(lo),
                  (val) => ref
                      .read(generationProvider.notifier)
                      .updateLoDistribution(lo, val),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 32),
      _buildSectionHeader(
        'DIFFICULTY',
        current: genState.difficultySum,
        target: genState.total,
      ),
      GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: _difficulties
              .map(
                (diff) => _buildDistributionRow(
                  diff,
                  genState.difficultyDistribution[diff] ?? 0,
                  (genState.difficultyDistribution[diff] ?? 0) +
                      genState.difficultyDistribution.entries
                          .where(
                            (e) =>
                                e.key != diff &&
                                !genState.locks.contains(e.key),
                          )
                          .fold(0, (sum, e) => sum + e.value),
                  genState.locks.contains(diff),
                  () => ref.read(generationProvider.notifier).toggleLock(diff),
                  (val) => ref
                      .read(generationProvider.notifier)
                      .updateDifficultyDistribution(diff, val),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 40),
      _buildGenerateButton(),
    ];
  }

  Widget _buildSectionHeader(String title, {int? current, int? target}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppTheme.modernTextSecondary,
            ),
          ),
          if (current != null && target != null)
            Text(
              '${current == target ? '✓' : ''} $current / $target',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: current == target ? Colors.green : Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: items.isEmpty
              ? null
              : (items.contains(value) ? value : items.first),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            fillColor: Colors.black.withOpacity(0.04),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSmallIconBtn(
              Icons.remove,
              () => onChanged(value > 0 ? value - 1 : 0),
            ),
            Expanded(
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _buildSmallIconBtn(Icons.add, () => onChanged(value + 1)),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallIconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Colors.black54),
      ),
    );
  }

  Widget _buildDistributionRow(
    String label,
    int value,
    int max,
    bool isLocked,
    VoidCallback onLockToggle,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 18,
              color: isLocked ? AppTheme.modernAccent : Colors.black26,
            ),
            onPressed: onLockToggle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            tooltip: isLocked ? 'Unlock' : 'Lock',
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isLocked ? AppTheme.modernAccent : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble() > max ? max.toDouble() : value.toDouble(),
              min: 0,
              max: max > 0
                  ? max.toDouble()
                  : (value > 0 ? value.toDouble() : 1),
              divisions: max > 0 ? max : (value > 0 ? value : 1),
              label: value.toString(),
              activeColor: isLocked ? Colors.black26 : AppTheme.modernAccent,
              onChanged: isLocked ? null : (val) => onChanged(val.toInt()),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.modernAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    final genState = ref.watch(generationProvider);
    final isCoValid = genState.coSum == genState.total;
    final isLoValid = genState.loSum == genState.total;
    final isDiffValid = genState.difficultySum == genState.total;
    final isEnabled = isCoValid && isLoValid && isDiffValid;

    return Column(
      children: [
        if (!isEnabled)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Distributions must sum exactly to ${genState.total}',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEnabled
                ? () => ref.read(generationProvider.notifier).generatePaper()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.modernAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.black.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded),
                SizedBox(width: 12),
                Text(
                  'GENERATE PAPER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 100),
        const CircularProgressIndicator(color: AppTheme.modernAccent),
        const SizedBox(height: 24),
        const Text(
          'Synthesizing Questions...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'RAG Phase in progress. This may take up to 30s.',
          style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 13),
        ),
        const SizedBox(height: 32),
        TextButton.icon(
          onPressed: () =>
              ref.read(generationProvider.notifier).cancelGeneration(),
          icon: const Icon(Icons.stop_circle_rounded, color: Colors.red),
          label: const Text(
            'CANCEL GENERATION',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildResults(GenerationState genState) {
    return [
      _buildSectionHeader('GENERATION SUMMARY'),
      GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSummaryRow(
              'Total Marks',
              '${genState.stats?['total_marks'] ?? 0}',
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),
      _buildSectionHeader('QUESTION PAPER'),
      ...genState.generatedQuestions.asMap().entries.map((entry) {
        final index = entry.key;
        final q = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Q${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.modernAccent,
                          ),
                        ),
                        if (q.topic != null && q.topic!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.modernAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              q.topic!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.modernAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${q.marks} Marks',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (q.referenceMaterial != null &&
                    q.referenceMaterial!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: AppTheme.modernTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${q.referenceMaterial} (Page ${q.referencePage ?? 'N/A'})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.modernTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  q.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (q.options != null && q.options!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...['a', 'b', 'c', 'd']
                      .where((k) => q.options!.containsKey(k))
                      .map(
                        (k) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color:
                                      (q.correctAnswer?.toLowerCase() ==
                                          k.toLowerCase())
                                      ? Colors.green
                                      : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  k.toUpperCase(),
                                  style: TextStyle(
                                    color:
                                        (q.correctAnswer?.toLowerCase() ==
                                            k.toLowerCase())
                                        ? Colors.white
                                        : Colors.black54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  q.options![k].toString(),
                                  style: TextStyle(
                                    color:
                                        (q.correctAnswer?.toLowerCase() ==
                                            k.toLowerCase())
                                        ? Colors.green.shade700
                                        : Colors.black87,
                                    fontWeight:
                                        (q.correctAnswer?.toLowerCase() ==
                                            k.toLowerCase())
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
                if (q.type == 'short' || q.type == 'essay') ...[
                  if (q.correctAnswer != null &&
                      q.correctAnswer!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Model Answer:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q.correctAnswer!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(q.difficulty ?? 'Medium', Colors.blue),
                    _buildTag(q.type.toUpperCase(), Colors.orange),
                    ...q.coMap.keys.map((co) => _buildTag(co, Colors.teal)),
                    ...q.loList.map((lo) => _buildTag(lo, Colors.indigo)),
                    if (q.source == 'AI') _buildTag('AI', Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
      const SizedBox(height: 32),
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => ExportService.generateAndSavePdf(
                genState.courseCode,
                genState.generatedQuestions,
                genState.stats,
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => ExportService.exportToCsv(
                genState.courseCode,
                genState.generatedQuestions,
              ),
              icon: const Icon(Icons.table_chart_rounded),
              label: const Text('CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade800,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => ref.read(generationProvider.notifier).reset(),
        child: const Text('Back to Blueprint'),
      ),
    ];
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTopicSelector(GenerationState genState) {
    final topicsAsync = ref.watch(topicsProvider(genState.courseCode));

    return topicsAsync.when(
      data: (topics) {
        if (topics.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayString = genState.topics.isEmpty
            ? 'Select Topics'
            : '${genState.topics.length} Selected (Tap to edit)';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Topics (Optional)',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showTopicsDialog(context, topics),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayString,
                      style: TextStyle(
                        fontSize: 14,
                        color: genState.topics.isEmpty
                            ? Colors.black54
                            : Colors.black87,
                        fontWeight: genState.topics.isEmpty
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showTopicsDialog(BuildContext context, List<dynamic> topics) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Select Topics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          contentPadding: const EdgeInsets.only(top: 12, bottom: 0),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, child) {
                final currentState = ref.watch(generationProvider);
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: topics.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final topicName = topics[index].name;
                    final isSelected = currentState.topics.contains(topicName);
                    return CheckboxListTile(
                      title: Text(
                        topicName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: isSelected,
                      activeColor: AppTheme.modernAccent,
                      controlAffinity: ListTileControlAffinity.trailing,
                      onChanged: (bool? value) {
                        ref
                            .read(generationProvider.notifier)
                            .toggleTopic(topicName);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'DONE',
                style: TextStyle(
                  color: AppTheme.modernAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

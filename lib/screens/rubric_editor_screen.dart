import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_header.dart';
import '../widgets/glass_container.dart';
import '../models/rubric.dart';
import '../providers/rubrics_provider.dart';
import '../providers/generation_provider.dart';
import '../providers/courses_provider.dart';

class RubricEditorScreen extends ConsumerStatefulWidget {
  final Rubric? existingRubric;
  const RubricEditorScreen({super.key, this.existingRubric});

  @override
  ConsumerState<RubricEditorScreen> createState() => _RubricEditorScreenState();
}

class _RubricEditorScreenState extends ConsumerState<RubricEditorScreen> {
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  final List<String> _cos = ['CO1', 'CO2', 'CO3', 'CO4', 'CO5'];
  final List<String> _los = ['LO1', 'LO2', 'LO3', 'LO4', 'LO5'];

  late String _courseCode;
  late int _marks;
  late int _total;
  late Map<String, int> _coDistribution;
  late Map<String, int> _loDistribution;
  late Map<String, int> _difficultyDistribution;
  late List<String> _topics;
  late String _questionStyle;

  bool _isSaved = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRubric;
    if (r != null) {
      _courseCode = r.courseCode;
      _marks = r.marks;
      _total = r.total;
      _coDistribution = Map.from(r.coDistribution);
      _loDistribution = Map.from(r.loDistribution);
      _difficultyDistribution = Map.from(r.difficultyDistribution);
      _topics = List.from(r.topics);
      _questionStyle = r.questionStyle;
      _isSaved = true;
    } else {
      _courseCode = 'DSA';
      _marks = 1;
      _total = 1;
      _coDistribution = {'CO1': 1, 'CO2': 0, 'CO3': 0, 'CO4': 0, 'CO5': 0};
      _loDistribution = {'LO1': 1, 'LO2': 0, 'LO3': 0, 'LO4': 0, 'LO5': 0};
      _difficultyDistribution = {'Easy': 1, 'Medium': 0, 'Hard': 0};
      _topics = [];
      _questionStyle = 'Analytical';
    }
    Future.microtask(() => ref.read(coursesProvider.notifier).loadCourses());
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Map<String, int> _rebalance(
    Map<String, int> currentDist,
    List<String> allKeys,
    String changedKey,
    int newVal,
    int total,
  ) {
    if (newVal > total) newVal = total;
    if (newVal < 0) newVal = 0;

    final oldVal = currentDist[changedKey] ?? 0;
    if (newVal == oldVal) return currentDist;

    final dist = Map<String, int>.from(currentDist);
    dist[changedKey] = newVal;

    int delta = newVal - oldVal;

    // Keys that can be adjusted (not the changed key)
    final otherKeys = allKeys.where((k) => k != changedKey).toList();

    if (otherKeys.isEmpty) return currentDist;

    if (delta > 0) {
      // Decrease from right to left
      int toSubtract = delta;
      for (int i = otherKeys.length - 1; i >= 0; i--) {
        if (toSubtract <= 0) break;
        String key = otherKeys[i];
        int current = dist[key] ?? 0;

        if (current > 0) {
          int take = current >= toSubtract ? toSubtract : current;
          dist[key] = current - take;
          toSubtract -= take;
        }
      }
      if (toSubtract > 0) {
        dist[changedKey] = (dist[changedKey] ?? 0) - toSubtract;
      }
    } else {
      // Add from left to right, starting after the changed key
      int toAdd = -delta;
      int changedIndex = allKeys.indexOf(changedKey);

      for (int i = 0; i < otherKeys.length; i++) {
        String key = otherKeys[i];
        if (allKeys.indexOf(key) > changedIndex) {
          dist[key] = (dist[key] ?? 0) + toAdd;
          toAdd = 0;
          break;
        }
      }
      if (toAdd > 0 && otherKeys.isNotEmpty) {
        String key = otherKeys.first;
        dist[key] = (dist[key] ?? 0) + toAdd;
      }
    }

    return dist;
  }

  void _updateCo(String co, int val) {
    setState(() {
      _coDistribution = _rebalance(_coDistribution, _cos, co, val, _total);
    });
    _markChanged();
  }

  void _updateLo(String lo, int val) {
    setState(() {
      _loDistribution = _rebalance(_loDistribution, _los, lo, val, _total);
    });
    _markChanged();
  }

  void _updateDiff(String d, int val) {
    setState(() {
      _difficultyDistribution = _rebalance(
        _difficultyDistribution,
        _difficulties,
        d,
        val,
        _total,
      );
    });
    _markChanged();
  }

  int get _coSum => _coDistribution.values.fold(0, (a, b) => a + b);
  int get _loSum => _loDistribution.values.fold(0, (a, b) => a + b);
  int get _diffSum => _difficultyDistribution.values.fold(0, (a, b) => a + b);

  Map<String, dynamic> _toJson() => {
    'course_code': _courseCode,
    'marks': _marks,
    'total': _total,
    'co_distribution': _coDistribution,
    'lo_distribution': _loDistribution,
    'difficulty_distribution': _difficultyDistribution,
    'topics': _topics,
    'question_style': _questionStyle,
  };

  Future<void> _handleSave() async {
    final name = await _promptForName();
    if (name == null || name.isEmpty) return;

    final data = _toJson();
    data['name'] = name;

    final saved = await ref.read(rubricsProvider.notifier).createRubric(data);
    if (saved != null && mounted) {
      setState(() {
        _isSaved = true;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rubric saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleSaveAsNew() async {
    final name = await _promptForName();
    if (name == null || name.isEmpty) return;

    final data = _toJson();
    data['name'] = name;

    final saved = await ref.read(rubricsProvider.notifier).createRubric(data);
    if (saved != null && mounted) {
      setState(() {
        _isSaved = true;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved as new rubric'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<String?> _promptForName() async {
    final controller = TextEditingController(
      text: widget.existingRubric?.name ?? '',
    );
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rubric Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter a name...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleGenerate() {
    final gen = ref.read(generationProvider.notifier);
    gen.updateCourseCode(_courseCode);
    gen.updateMarks(_marks);
    gen.updateTotal(_total);
    for (final co in _cos) {
      gen.updateCoDistribution(co, _coDistribution[co] ?? 0);
    }
    for (final lo in _los) {
      gen.updateLoDistribution(lo, _loDistribution[lo] ?? 0);
    }
    for (final d in _difficulties) {
      gen.updateDifficultyDistribution(d, _difficultyDistribution[d] ?? 0);
    }
    gen.updateQuestionStyle(_questionStyle);
    gen.generatePaper();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ModernHeader(
              title: widget.existingRubric != null
                  ? 'Edit Rubric'
                  : 'New Rubric',
              subtitle:
                  widget.existingRubric?.name ??
                  'Configure generation settings',
              actions: [
                if (widget.existingRubric != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                            .deleteRubric(widget.existingRubric!.id);
                        if (mounted) Navigator.pop(context);
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('SUBJECT & MARKS'),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildDropdownField(
                        'Subject',
                        _courseCode,
                        courses.map((e) => e.code).toList(),
                        (val) {
                          setState(() => _courseCode = val!);
                          _markChanged();
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberField('Marks per Q', _marks, (
                              val,
                            ) {
                              setState(() => _marks = val);
                              _markChanged();
                            }),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildNumberField(
                              'Total Questions',
                              _total,
                              (val) {
                                setState(() => _total = val);
                                _markChanged();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownField(
                        'Question Style',
                        _questionStyle,
                        ['Analytical', 'Theory', 'Hybrid'],
                        (val) {
                          setState(() => _questionStyle = val!);
                          _markChanged();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // CO Distribution
                _buildSectionHeader(
                  'CO DISTRIBUTION',
                  current: _coSum,
                  target: _total,
                ),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: _cos
                        .map(
                          (co) => _buildDistRow(
                            co,
                            _coDistribution[co] ?? 0,
                            _total,
                            (val) {
                              _updateCo(co, val);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // LO Distribution
                _buildSectionHeader(
                  'LO DISTRIBUTION',
                  current: _loSum,
                  target: _total,
                ),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: _los
                        .map(
                          (lo) => _buildDistRow(
                            lo,
                            _loDistribution[lo] ?? 0,
                            _total,
                            (val) {
                              _updateLo(lo, val);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Difficulty Distribution
                _buildSectionHeader(
                  'DIFFICULTY',
                  current: _diffSum,
                  target: _total,
                ),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: _difficulties
                        .map(
                          (d) => _buildDistRow(
                            d,
                            _difficultyDistribution[d] ?? 0,
                            _total,
                            (val) {
                              _updateDiff(d, val);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 40),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'Generate',
                        color: AppTheme.modernAccent,
                        onPressed: _handleGenerate,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _isSaved && !_hasChanges
                          ? _buildActionButton(
                              icon: Icons.check_circle_rounded,
                              label: 'Saved',
                              color: Colors.grey,
                              onPressed: null,
                            )
                          : _isSaved && _hasChanges
                          ? _buildActionButton(
                              icon: Icons.save_as_rounded,
                              label: 'Save as New',
                              color: Colors.orange,
                              onPressed: _handleSaveAsNew,
                            )
                          : _buildActionButton(
                              icon: Icons.save_rounded,
                              label: 'Save',
                              color: Colors.green,
                              onPressed: _handleSave,
                            ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────

  Widget _buildSectionHeader(String title, {int? current, int? target}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
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
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistRow(
    String label,
    int value,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              max: max.toDouble(),
              divisions: max > 0 ? max : 1,
              onChanged: (v) => onChanged(v.round()),
              activeColor: AppTheme.modernAccent,
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey.shade300,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: onPressed != null ? 2 : 0,
        ),
      ),
    );
  }
}

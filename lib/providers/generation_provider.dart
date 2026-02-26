import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../services/api_service.dart';
import 'api_provider.dart';

class GenerationState {
  final String courseCode;
  final int marks;
  final int total;
  final Map<String, int> coDistribution;
  final Map<String, int> loDistribution;
  final Map<String, int> difficultyDistribution;
  final List<String> topics;
  final List<Question> generatedQuestions;
  final Map<String, dynamic>? stats;
  final Set<String> locks;
  final bool isLoading;
  final String? error;

  GenerationState({
    this.courseCode = 'DSA',
    this.marks = 10,
    this.total = 10,
    this.coDistribution = const {
      'CO1': 2,
      'CO2': 2,
      'CO3': 2,
      'CO4': 2,
      'CO5': 2,
    },
    this.loDistribution = const {
      'LO1': 2,
      'LO2': 2,
      'LO3': 2,
      'LO4': 2,
      'LO5': 2,
    },
    this.difficultyDistribution = const {'Easy': 4, 'Medium': 3, 'Hard': 3},
    this.topics = const [],
    this.generatedQuestions = const [],
    this.stats,
    this.locks = const {},
    this.isLoading = false,
    this.error,
  });

  GenerationState copyWith({
    String? courseCode,
    int? marks,
    int? total,
    Map<String, int>? coDistribution,
    Map<String, int>? loDistribution,
    Map<String, int>? difficultyDistribution,
    List<String>? topics,
    List<Question>? generatedQuestions,
    Map<String, dynamic>? stats,
    Set<String>? locks,
    bool? isLoading,
    String? error,
  }) {
    return GenerationState(
      courseCode: courseCode ?? this.courseCode,
      marks: marks ?? this.marks,
      total: total ?? this.total,
      coDistribution: coDistribution ?? this.coDistribution,
      loDistribution: loDistribution ?? this.loDistribution,
      difficultyDistribution:
          difficultyDistribution ?? this.difficultyDistribution,
      topics: topics ?? this.topics,
      generatedQuestions: generatedQuestions ?? this.generatedQuestions,
      stats: stats ?? this.stats,
      locks: locks ?? this.locks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  int get coSum => coDistribution.values.fold(0, (a, b) => a + b);
  int get difficultySum =>
      difficultyDistribution.values.fold(0, (a, b) => a + b);
  int get loSum => loDistribution.values.fold(0, (a, b) => a + b);

  bool get isValid =>
      coSum == total && difficultySum == total && loSum == total;
}

class GenerationNotifier extends Notifier<GenerationState> {
  ApiService get _apiService => ref.read(apiServiceProvider);

  @override
  GenerationState build() => GenerationState();

  void updateCourseCode(String code) =>
      state = state.copyWith(courseCode: code);
  void updateMarks(int marks) => state = state.copyWith(marks: marks);

  void toggleTopic(String topic) {
    final current = List<String>.from(state.topics);
    if (current.contains(topic)) {
      current.remove(topic);
    } else {
      current.add(topic);
    }
    state = state.copyWith(topics: current);
  }

  void updateTotal(int total) {
    state = state.copyWith(
      total: total,
      coDistribution: _initialBalance(state.coDistribution, total),
      loDistribution: _initialBalance(state.loDistribution, total),
      difficultyDistribution: _initialBalance(
        state.difficultyDistribution,
        total,
      ),
    );
  }

  Map<String, int> _initialBalance(Map<String, int> dist, int total) {
    if (dist.isEmpty) return {};
    final newDist = Map<String, int>.from(dist);
    int currentSum = newDist.values.fold(0, (a, b) => a + b);
    if (currentSum == total) return newDist;

    // Simple redistribution: clear and distribute equally, then fix remainder
    int count = newDist.length;
    int base = total ~/ count;
    int remainder = total % count;

    int i = 0;
    for (var key in newDist.keys) {
      newDist[key] = base + (i < remainder ? 1 : 0);
      i++;
    }
    return newDist;
  }

  void toggleLock(String key) {
    final newLocks = Set<String>.from(state.locks);
    if (newLocks.contains(key)) {
      newLocks.remove(key);
    } else {
      newLocks.add(key);
    }
    state = state.copyWith(locks: newLocks);
  }

  Map<String, int> _rebalance(
    Map<String, int> currentDist,
    List<String> allKeys,
    String changedKey,
    int newVal,
    int total,
  ) {
    if (newVal > total) newVal = total;
    final oldVal = currentDist[changedKey] ?? 0;
    if (newVal == oldVal) return currentDist;

    final dist = Map<String, int>.from(currentDist);
    dist[changedKey] = newVal;

    int delta = newVal - oldVal;
    final otherKeys = allKeys
        .where((k) => k != changedKey && !state.locks.contains(k))
        .toList();

    if (otherKeys.isEmpty) {
      // If everything else is locked, revert the change
      return currentDist;
    }

    if (delta > 0) {
      // Subtracting from others
      int toSubtract = delta;

      // We loop to handle cases where some items hit 0 before others
      while (toSubtract > 0) {
        int poolSum = otherKeys.fold(0, (sum, k) => sum + dist[k]!);
        if (poolSum == 0) {
          // Can't subtract anymore, cap the changedKey
          dist[changedKey] = (dist[changedKey] ?? 0) - toSubtract;
          break;
        }

        int absorbed = 0;
        for (final k in otherKeys) {
          int val = dist[k]!;
          if (val == 0) continue;

          // Proportional share
          int share = (val * toSubtract / poolSum).floor();
          if (share == 0 && toSubtract > 0) share = 1;

          int taken = val < share ? val : share;
          dist[k] = val - taken;
          absorbed += taken;
          toSubtract -= taken;
          if (toSubtract <= 0) break;
        }
        if (absorbed == 0) break;
      }
    } else {
      // Adding to others
      int toAdd = delta.abs();
      int share = toAdd ~/ otherKeys.length;
      int rem = toAdd % otherKeys.length;
      for (int i = 0; i < otherKeys.length; i++) {
        dist[otherKeys[i]] =
            (dist[otherKeys[i]] ?? 0) + share + (i < rem ? 1 : 0);
      }
    }

    return dist;
  }

  void updateCoDistribution(String co, int count) {
    state = state.copyWith(
      coDistribution: _rebalance(
        state.coDistribution,
        ['CO1', 'CO2', 'CO3', 'CO4', 'CO5'],
        co,
        count,
        state.total,
      ),
    );
  }

  void updateLoDistribution(String lo, int count) {
    state = state.copyWith(
      loDistribution: _rebalance(
        state.loDistribution,
        ['LO1', 'LO2', 'LO3', 'LO4', 'LO5'],
        lo,
        count,
        state.total,
      ),
    );
  }

  void updateDifficultyDistribution(String difficulty, int count) {
    state = state.copyWith(
      difficultyDistribution: _rebalance(
        state.difficultyDistribution,
        ['Easy', 'Medium', 'Hard'],
        difficulty,
        count,
        state.total,
      ),
    );
  }

  Future<void> generatePaper() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      generatedQuestions: [],
    );

    // Yield to ensure UI updates immediately before starting the request
    await Future.delayed(Duration.zero);

    try {
      final result = await _apiService.generatePaper(
        courseCode: state.courseCode,
        topics: state.topics,
        marks: state.marks,
        total: state.total,
        coDistribution: state.coDistribution,
        loDistribution: state.loDistribution,
        difficultyDistribution: state.difficultyDistribution,
      );

      final List<dynamic> questionsJson = result['paper'] ?? [];
      final questions = questionsJson
          .map((json) => Question.fromJson(json))
          .toList();

      state = state.copyWith(
        generatedQuestions: questions,
        stats: result['stats'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = GenerationState();
  }
}

final generationProvider =
    NotifierProvider<GenerationNotifier, GenerationState>(() {
      return GenerationNotifier();
    });

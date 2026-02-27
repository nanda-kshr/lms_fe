import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
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
  final String questionStyle;

  GenerationState({
    this.courseCode = 'DSA',
    this.marks = 1,
    this.total = 1,
    this.coDistribution = const {
      'CO1': 1,
      'CO2': 0,
      'CO3': 0,
      'CO4': 0,
      'CO5': 0,
    },
    this.loDistribution = const {
      'LO1': 1,
      'LO2': 0,
      'LO3': 0,
      'LO4': 0,
      'LO5': 0,
    },
    this.difficultyDistribution = const {'Easy': 1, 'Medium': 0, 'Hard': 0},
    this.topics = const [],
    this.generatedQuestions = const [],
    this.stats,
    this.locks = const {},
    this.isLoading = false,
    this.error,
    this.questionStyle = 'Analytical',
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
    String? questionStyle,
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
      questionStyle: questionStyle ?? this.questionStyle,
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
  CancelToken? _cancelToken;

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
    if (newVal < 0) newVal = 0;

    final oldVal = currentDist[changedKey] ?? 0;
    if (newVal == oldVal) return currentDist;

    final dist = Map<String, int>.from(currentDist);
    dist[changedKey] = newVal;

    int delta = newVal - oldVal;

    // Keys that can be adjusted (not locked, not the changed key)
    final otherKeys = allKeys
        .where((k) => k != changedKey && !state.locks.contains(k))
        .toList();

    if (otherKeys.isEmpty) {
      // If everything else is locked, we can't balance it, so revert
      return currentDist;
    }

    if (delta > 0) {
      // We increased a slider, so we need to decrease others by `delta`
      int toSubtract = delta;

      // Predictable subtraction: go from right to left (bottom to top visually)
      // to subtract from the "later" items first.
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

      // If we still have `toSubtract` left, it means we hit the floor (0) on all other keys.
      // We must revert the changedKey by the remaining amount so the total stays correct.
      if (toSubtract > 0) {
        dist[changedKey] = (dist[changedKey] ?? 0) - toSubtract;
      }
    } else {
      // We decreased a slider, so we need to increase others by `abs(delta)`
      int toAdd = -delta;

      // Predictable addition: add to the first available key to the right of the changed one
      // If none to the right, add to the first available key from the left.

      int changedIndex = allKeys.indexOf(changedKey);

      // Try keys after the changed key first
      for (int i = 0; i < otherKeys.length; i++) {
        String key = otherKeys[i];
        if (allKeys.indexOf(key) > changedIndex) {
          dist[key] = (dist[key] ?? 0) + toAdd;
          toAdd = 0;
          break;
        }
      }

      // If still not added (e.g. changed the last key), add to the first available
      if (toAdd > 0 && otherKeys.isNotEmpty) {
        String key = otherKeys.first;
        dist[key] = (dist[key] ?? 0) + toAdd;
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

  void updateQuestionStyle(String style) {
    state = state.copyWith(questionStyle: style);
  }

  Future<void> generatePaper() async {
    _cancelToken = CancelToken();
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
        questionStyle: state.questionStyle,
        cancelToken: _cancelToken,
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
      if (e.toString().contains('cancelled')) {
        state = state.copyWith(
          isLoading: false,
          error: 'Generation cancelled by user.',
        );
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    } finally {
      _cancelToken = null;
    }
  }

  void cancelGeneration() {
    _cancelToken?.cancel('Generation cancelled by user.');
    _cancelToken = null;
    state = state.copyWith(
      isLoading: false,
      error: 'Generation cancelled by user.',
    );
  }

  void reset() {
    try {
      _cancelToken?.cancel('Generation cancelled by user.');
    } catch (_) {}
    _cancelToken = null;
    state = GenerationState();
  }
}

final generationProvider =
    NotifierProvider<GenerationNotifier, GenerationState>(() {
      return GenerationNotifier();
    });

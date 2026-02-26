import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../services/api_service.dart';
import 'api_provider.dart';

const int kDefaultDailyLimit = 50;

class VettingState {
  final List<Question> questions;
  final int currentIndex;
  final String statusFilter;
  final bool isLoading;
  final int vettedToday;
  final int remainingVotes;
  final int dailyLimit;

  VettingState({
    this.questions = const [],
    this.currentIndex = 0,
    this.statusFilter = 'pending',
    this.isLoading = false,
    this.vettedToday = 0,
    this.remainingVotes = kDefaultDailyLimit,
    this.dailyLimit = kDefaultDailyLimit,
  });

  VettingState copyWith({
    List<Question>? questions,
    int? currentIndex,
    String? statusFilter,
    bool? isLoading,
    int? vettedToday,
    int? remainingVotes,
    int? dailyLimit,
  }) {
    return VettingState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      statusFilter: statusFilter ?? this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
      vettedToday: vettedToday ?? this.vettedToday,
      remainingVotes: remainingVotes ?? this.remainingVotes,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }
}

class VettingNotifier extends Notifier<VettingState> {
  ApiService get _apiService => ref.read(apiServiceProvider);

  @override
  VettingState build() {
    // Initial load happens after build
    Future.microtask(() => loadQuestions());
    return VettingState();
  }

  Future<void> loadQuestions({String? status}) async {
    // Prevent multiple simultaneous loads
    if (state.isLoading && (status == null || status == state.statusFilter)) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      statusFilter: status ?? state.statusFilter,
    );

    try {
      final result = await _apiService.fetchQuestions(
        status: state.statusFilter,
      );
      state = state.copyWith(
        questions: result['questions'] as List<Question>,
        currentIndex: 0,
        isLoading: false,
        vettedToday: (result['vetted_today'] as int?) ?? 0,
        remainingVotes: (result['remaining_votes'] as int?) ?? 0,
        dailyLimit: (result['daily_limit'] as int?) ?? kDefaultDailyLimit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void nextQuestion() {
    if (state.questions.isEmpty) return;
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  Future<void> vetCurrentQuestion(
    VettingAction action, {
    String? reason,
  }) async {
    if (state.questions.isEmpty) return;
    if (state.currentIndex >= state.questions.length) return;

    final currentQuestion = state.questions[state.currentIndex];

    try {
      await _apiService.vetQuestion(currentQuestion.id, action, reason: reason);

      // Update local state by removing the vetted question
      final updatedQuestions = List<Question>.from(state.questions)
        ..removeAt(state.currentIndex);

      int nextIndex = state.currentIndex;
      if (nextIndex >= updatedQuestions.length && updatedQuestions.isNotEmpty) {
        nextIndex = updatedQuestions.length - 1;
      } else if (updatedQuestions.isEmpty) {
        nextIndex = 0;
      }

      state = state.copyWith(
        questions: updatedQuestions,
        currentIndex: nextIndex,
      );
    } catch (e) {
      rethrow;
    }
  }
}

final vettingProvider = NotifierProvider<VettingNotifier, VettingState>(() {
  return VettingNotifier();
});

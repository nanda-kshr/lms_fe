import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rubric.dart';
import '../services/api_service.dart';
import 'api_provider.dart';

class RubricsState {
  final List<Rubric> rubrics;
  final int totalPages;
  final int currentPage;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  RubricsState({
    this.rubrics = const [],
    this.totalPages = 1,
    this.currentPage = 1,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  RubricsState copyWith({
    List<Rubric>? rubrics,
    int? totalPages,
    int? currentPage,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return RubricsState(
      rubrics: rubrics ?? this.rubrics,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RubricsNotifier extends Notifier<RubricsState> {
  ApiService get _apiService => ref.read(apiServiceProvider);

  @override
  RubricsState build() => RubricsState();

  Future<void> loadRubrics({int page = 1, String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _apiService.getRubrics(
        search: search ?? state.searchQuery,
        page: page,
        limit: 10,
      );
      final List<dynamic> dataJson = result['data'] ?? [];
      final rubrics = dataJson.map((j) => Rubric.fromJson(j)).toList();
      state = state.copyWith(
        rubrics: rubrics,
        totalPages: result['totalPages'] ?? 1,
        currentPage: page,
        searchQuery: search ?? state.searchQuery,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateSearch(String query) {
    loadRubrics(page: 1, search: query);
  }

  Future<Rubric?> createRubric(Map<String, dynamic> data) async {
    try {
      final result = await _apiService.createRubric(data);
      await loadRubrics(page: state.currentPage);
      return Rubric.fromJson(result);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<Rubric?> updateRubric(String id, Map<String, dynamic> data) async {
    try {
      final result = await _apiService.updateRubric(id, data);
      await loadRubrics(page: state.currentPage);
      return Rubric.fromJson(result);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> deleteRubric(String id) async {
    try {
      await _apiService.deleteRubric(id);
      await loadRubrics(page: state.currentPage);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final rubricsProvider = NotifierProvider<RubricsNotifier, RubricsState>(() {
  return RubricsNotifier();
});

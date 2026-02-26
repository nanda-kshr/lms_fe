import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';

final analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.fetchSystemAnalytics();
});

final trendsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.fetchTrends();
});

final selectedCourseProvider =
    NotifierProvider<SelectedCourseNotifier, String?>(
      SelectedCourseNotifier.new,
    );

class SelectedCourseNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? code) {
    state = code;
  }
}

final coursesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.fetchCourses();
});

final courseAnalyticsProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final courseCode = ref.watch(selectedCourseProvider);
  if (courseCode == null) return null;
  final apiService = ref.read(apiServiceProvider);
  return apiService.fetchCourseAnalytics(courseCode);
});

final facultyDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
      final apiService = ref.read(apiServiceProvider);
      return apiService.fetchFacultyDetails(id);
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../models/topic.dart';
import 'api_provider.dart';

// ── Courses Provider ───────────────────────────────────

class CoursesNotifier extends Notifier<List<Course>> {
  @override
  List<Course> build() {
    return [];
  }

  Future<void> loadCourses() async {
    try {
      final data = await ref.read(apiServiceProvider).fetchCourses();
      state = data.map((json) => Course.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addCourse(Map<String, dynamic> data) async {
    try {
      final newCourseJson = await ref
          .read(apiServiceProvider)
          .createCourse(data);
      final newCourse = Course.fromJson(newCourseJson);
      state = [...state, newCourse];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCourse(String id, Map<String, dynamic> data) async {
    try {
      final updatedJson = await ref
          .read(apiServiceProvider)
          .updateCourse(id, data);
      final updatedCourse = Course.fromJson(updatedJson);
      state = [
        for (final course in state)
          if (course.id == id) updatedCourse else course,
      ];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      await ref.read(apiServiceProvider).deleteCourse(id);
      state = state.where((c) => c.id != id).toList();
    } catch (e) {
      rethrow;
    }
  }
}

final coursesProvider = NotifierProvider<CoursesNotifier, List<Course>>(() {
  return CoursesNotifier();
});

// ── Topics Provider ────────────────────────────────────

// Using autoDispose so we don't cache stale topics when switching courses
final topicsProvider = FutureProvider.autoDispose.family<List<Topic>, String>((
  ref,
  courseId,
) async {
  final data = await ref.read(apiServiceProvider).fetchTopics(courseId);
  return data.map((json) => Topic.fromJson(json)).toList();
});

// We need a way to mutate topics, so we might need a Notifier or just API calls + invalidate
// Since topicsProvider is a FutureProvider, we can just invalidate it to refetch.

class TopicsController {
  final Ref ref;
  TopicsController(this.ref);

  Future<void> addTopic(String courseId, Map<String, dynamic> data) async {
    await ref.read(apiServiceProvider).addTopic(courseId, data);
    ref.invalidate(topicsProvider(courseId));
  }

  Future<void> updateTopic(
    String courseId,
    String topicId,
    Map<String, dynamic> data,
  ) async {
    await ref.read(apiServiceProvider).updateTopic(courseId, topicId, data);
    ref.invalidate(topicsProvider(courseId));
  }

  Future<void> deleteTopic(String courseId, String topicId) async {
    await ref.read(apiServiceProvider).deleteTopic(courseId, topicId);
    ref.invalidate(topicsProvider(courseId));
  }
}

final topicsControllerProvider = Provider((ref) => TopicsController(ref));

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';

final coursesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return apiService.fetchCourses();
});

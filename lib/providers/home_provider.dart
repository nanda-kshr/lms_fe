import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';

final userStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final stats = await apiService.fetchUserVettingStats();

  return {
    'approved': stats['approved'] as int,
    'rejected': stats['rejected'] as int,
    'incompletions': stats['incompletions'] as int,
    'total':
        (stats['approved'] as int) +
        (stats['rejected'] as int) +
        (stats['incompletions'] as int),
  };
});

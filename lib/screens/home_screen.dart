import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_header.dart';
import '../widgets/glass_container.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import 'courses/course_list_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh stats
          return ref.refresh(userStatsProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ModernHeader(
                title: 'Dashboard',
                subtitle: 'Welcome Back',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    color: Colors.black54,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ref.read(authProvider.notifier).logout();
                              },
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=12',
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),
                  _buildSummaryCard(context, ref),
                  const SizedBox(height: 32),
                  const Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: AppTheme.modernTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(context, ref),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vetting Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.modernAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: AppTheme.modernAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error: $err'),
            data: (stats) {
              final total = stats['total'] ?? 0;
              final approved = stats['approved'] ?? 0;
              final rejected = stats['rejected'] ?? 0;
              final incompletions = stats['incompletions'] ?? 0;

              return Column(
                children: [
                  _buildProgressBar(
                    'Approved',
                    '$approved',
                    total > 0 ? approved / total : 0,
                    const Color(0xFF34C759),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressBar(
                    'Rejected',
                    '$rejected',
                    total > 0 ? rejected / total : 0,
                    const Color(0xFFFF3B30),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressBar(
                    'Incompletions',
                    '$incompletions',
                    total > 0 ? incompletions / total : 0,
                    const Color(0xFF5856D6), // Purple for incompletions
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    String label,
    String count,
    double value,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              count,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                flex: (value * 100).toInt(),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: ((1 - value) * 100).toInt(),
                child: const SizedBox(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildActionItem(
          Icons.cloud_upload_rounded,
          'Upload Questions',
          'Import from CSV',
          Colors.blue,
          () => ref.read(navigationProvider.notifier).setIndex(1),
        ),
        const SizedBox(height: 12),
        _buildActionItem(
          Icons.check_circle_rounded,
          'Vet Questions',
          'Review pending items',
          Colors.green,
          () => ref.read(navigationProvider.notifier).setIndex(2),
        ),
        const SizedBox(height: 12),
        _buildActionItem(
          Icons.auto_awesome_rounded,
          'Generate Questions',
          'AI-powered creation',
          Colors.purple,
          () => ref.read(navigationProvider.notifier).setIndex(3),
        ),
        const SizedBox(height: 12),
        _buildActionItem(
          Icons.analytics_rounded,
          'View Analytics',
          'Performance metrics',
          Colors.orange,
          () => ref.read(navigationProvider.notifier).setIndex(4),
        ),
        const SizedBox(height: 12),
        _buildActionItem(
          Icons.library_books_rounded,
          'Manage Courses',
          'Edit curriculum & topics',
          Colors.indigo,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CourseListScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.black45, fontSize: 13),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.black26,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

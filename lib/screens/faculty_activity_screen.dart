import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_header.dart';
import '../widgets/glass_container.dart';
import '../providers/analytics_provider.dart';

class FacultyActivityScreen extends ConsumerWidget {
  const FacultyActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: ModernHeader(
              title: 'Faculty Activity',
              subtitle: 'Performance Rankings',
              showBackButton: true,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            sliver: analyticsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
              data: (data) {
                final List<dynamic> faculty = List.from(data['faculty']);

                // Sort by total approved descending
                faculty.sort((a, b) {
                  final approvedA = (a['approved'] as num).toInt();
                  final approvedB = (b['approved'] as num).toInt();
                  return approvedB.compareTo(approvedA);
                });

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final f = faculty[index];
                    final uploads = f['uploads'] as int;
                    final approved = f['approved'] as int;
                    final userId = f['userId'] as String;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassContainer(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => FacultyDetailsDialog(
                                facultyId: userId,
                                facultyName: f['name'],
                              ),
                            );
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.modernAccent
                                  .withOpacity(0.1),
                              child: Text(
                                f['name'][0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.modernAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              f['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '$uploads Uploads • $approved Approved',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${uploads > 0 ? ((approved / uploads) * 100).toStringAsFixed(0) : 0}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  'Success',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.modernTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: faculty.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FacultyDetailsDialog extends ConsumerWidget {
  final String facultyId;
  final String facultyName;

  const FacultyDetailsDialog({
    super.key,
    required this.facultyId,
    required this.facultyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(facultyDetailsProvider(facultyId));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GlassContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    facultyName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.modernTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            detailsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (data) {
                final stats = data['monthly_stats'] as List<dynamic>;
                return Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSummaryStats(data),
                        const SizedBox(height: 24),
                        const Text(
                          'Monthly Performance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.modernTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...stats.map((s) => _buildMonthlyStatRow(s)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats(Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          'Total Uploads',
          '${data['total_uploads']}',
          Colors.blue,
        ),
        _buildStatItem(
          'Approval Rate',
          '${(data['lifetime_approval_rate'] as num).toStringAsFixed(1)}%',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.modernTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyStatRow(Map<String, dynamic> stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            stat['month'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.modernTextPrimary,
            ),
          ),
          Row(
            children: [
              _buildPill(
                '${stat['uploads']} Up',
                Colors.blue.withOpacity(0.1),
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildPill(
                '${stat['approved']} App',
                Colors.green.withOpacity(0.1),
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textCol,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

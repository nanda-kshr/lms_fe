import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'faculty_activity_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_header.dart';
import '../widgets/glass_container.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.refresh(analyticsProvider.future),
              ref.refresh(trendsProvider.future),
              if (ref.read(selectedCourseProvider) != null)
                ref.refresh(courseAnalyticsProvider.future),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: ModernHeader(
                  title: 'Analytics',
                  subtitle: 'Performance Overview',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('OVERVIEW'),
                    _buildOverviewCard(data['overview']),
                    const SizedBox(height: 24),
                    _buildSectionHeader('TRENDS'),
                    const TrendsChart(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('COURSE ANALYTICS'),
                    const CourseAnalyticsSection(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('CONTENT HEALTH'),
                    _buildContentHealthCard(data['content']),
                    const SizedBox(height: 24),
                    _buildSectionHeader('FACULTY ACTIVITY'),
                    _buildFacultyActivityButton(context),
                    const SizedBox(height: 24),
                    _buildAccuracyBar(data['overview']['approval_rate']),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: AppTheme.modernTextSecondary,
        ),
      ),
    );
  }

  Widget _buildOverviewCard(Map<String, dynamic> overview) {
    final total = (overview['total_questions'] as num).toInt();
    final approved = (overview['approved_questions'] as num).toInt();
    final pending = (overview['pending_questions'] as num).toInt();
    final rejected = (overview['rejected_questions'] as num).toInt();
    final ai = (overview['ai_generated_questions'] as num).toInt();
    final approvalRate = (overview['approval_rate'] as num).toDouble();

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildStatRow(
            'Uploaded',
            total.toString(),
            1.0,
            AppGradients.welcomeBlue,
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            'Approved',
            approved.toString(),
            total > 0 ? approved / total : 0,
            AppGradients.approve,
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            'AI Generated',
            ai.toString(),
            total > 0 ? ai / total : 0,
            const LinearGradient(
              colors: [Color(0xFFCE93D8), Color(0xFFAB47BC)],
            ),
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            'Rejected',
            rejected.toString(),
            total > 0 ? rejected / total : 0,
            AppGradients.reject,
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(
                '${approvalRate.toStringAsFixed(1)}%',
                'Approval Rate',
                Colors.blue,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.black.withOpacity(0.05),
              ),
              _buildMetric(
                (pending > 0 ? 'Pending' : 'All Clear'),
                'Vetting Status',
                pending > 0 ? Colors.orange : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentHealthCard(Map<String, dynamic> content) {
    final coData = content['by_co'] as Map<String, dynamic>;
    final diffData = content['by_difficulty'] as Map<String, dynamic>;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'CO Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.modernTextPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: coData.entries.map((e) {
                  final index = coData.keys.toList().indexOf(e.key);
                  final colors = [
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.red,
                    Colors.cyan,
                  ];
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: (e.value as num).toDouble(),
                    title: e.key,
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Difficulty Level',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.modernTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...diffData.entries.map((e) {
            final total = diffData.values.fold(0, (a, b) => a + (b as int));
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildStatRow(
                e.key,
                e.value.toString(),
                total > 0 ? (e.value as int) / total : 0,
                e.key == 'Hard'
                    ? AppGradients.reject
                    : (e.key == 'Medium'
                          ? AppGradients.welcomeBlue
                          : AppGradients.approve),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFacultyActivityButton(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FacultyActivityScreen(),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'View Rankings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.modernTextPrimary,
                  ),
                ),
                Text(
                  'Detailed faculty performance stats',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.modernTextSecondary,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.modernAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    double percent,
    Gradient gradient,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.modernTextPrimary,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.modernTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: percent.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -1,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.modernTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyBar(num approvalRate) {
    final rate = approvalRate.toDouble();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppGradients.approve,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34C759).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'System Accuracy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 32,
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

class TrendsChart extends ConsumerWidget {
  const TrendsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(trendsProvider);

    return GlassContainer(
      child: trendsAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => SizedBox(
          height: 200,
          child: Center(child: Text('Failed to load trends')),
        ),
        data: (data) {
          final trends = data['trends'] as List<dynamic>;
          if (trends.isEmpty) {
            return const SizedBox(
              height: 200,
              child: Center(child: Text('No trend data available')),
            );
          }

          // Parse data
          final points = trends.asMap().entries.map((e) {
            return FlSpot(
              e.key.toDouble(),
              (e.value['uploaded'] as num).toDouble(),
            );
          }).toList();

          final approvedPoints = trends.asMap().entries.map((e) {
            return FlSpot(
              e.key.toDouble(),
              (e.value['approved'] as num).toDouble(),
            );
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '30 Day Content Trends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.modernTextPrimary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: points,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.1),
                        ),
                      ),
                      LineChartBarData(
                        spots: approvedPoints,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Uploaded', Colors.blue),
                  const SizedBox(width: 16),
                  _buildLegendItem('Approved', Colors.green),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.modernTextSecondary,
          ),
        ),
      ],
    );
  }
}

class CourseAnalyticsSection extends ConsumerWidget {
  const CourseAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCourse = ref.watch(selectedCourseProvider);
    final courseDataAsync = ref.watch(courseAnalyticsProvider);

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subject Performance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.modernTextPrimary,
                ),
              ),
              // Use a simple dropdown for now, assuming courses logic exists or needs to be fetched
              // For MVP, we can hardcode a few or fetch from API.
              // Simplest is to just show "Select Course" if null.
              _buildCourseDropdown(context, ref, selectedCourse),
            ],
          ),
          const SizedBox(height: 24),
          if (selectedCourse == null)
            const SizedBox(
              height: 150,
              child: Center(child: Text('Select a course to view details')),
            )
          else
            courseDataAsync.when(
              loading: () => const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (data) {
                if (data == null) {
                  return const SizedBox.shrink();
                }

                final total = (data['total_questions'] as num).toInt();
                final approved = (data['approved_questions'] as num).toInt();
                final rate = (data['approval_rate'] as num).toDouble();
                final byCo = data['by_co'] as Map<String, dynamic>;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat('Total', '$total', Colors.blue),
                        _buildMiniStat('Approved', '$approved', Colors.green),
                        _buildMiniStat(
                          'Rate',
                          '${rate.toStringAsFixed(0)}%',
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 150,
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final keys = byCo.keys.toList();
                                  if (val.toInt() >= 0 &&
                                      val.toInt() < keys.length) {
                                    return Text(
                                      keys[val.toInt()],
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: byCo.entries.toList().asMap().entries.map((
                            e,
                          ) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: (e.value.value as num).toDouble(),
                                  color: AppTheme.modernAccent,
                                  width: 12,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCourseDropdown(
    BuildContext context,
    WidgetRef ref,
    String? selected,
  ) {
    final coursesAsync = ref.watch(coursesProvider);

    return coursesAsync.when(
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (err, stack) => const SizedBox(),
      data: (courses) {
        return DropdownButton<String>(
          value: selected,
          hint: const Text('Select'),
          underline: const SizedBox(),
          items: courses.map((c) {
            return DropdownMenuItem<String>(
              value: c['code'],
              child: Text(
                c['code'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
          onChanged: (val) {
            ref.read(selectedCourseProvider.notifier).select(val);
          },
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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
}

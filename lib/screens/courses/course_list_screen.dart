import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/courses_provider.dart';
import '../../models/course.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/glass_container.dart';
import 'course_edit_screen.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(coursesProvider.notifier).loadCourses());
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: AppTheme.modernBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ModernHeader(
              title: 'Manage Courses',
              subtitle: 'Curriculum & Topics',
              showBackButton: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  color: Colors.black54,
                  onPressed: () =>
                      ref.refresh(coursesProvider.notifier).loadCourses(),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            sliver: courses.isEmpty
                ? const SliverFillRemaining(
                    child: Center(child: Text('No courses found')),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final course = courses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCourseCard(context, course),
                      );
                    }, childCount: courses.length),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CourseEditScreen()),
          );
        },
        backgroundColor: AppTheme.modernAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Course', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return GlassContainer(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          course.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              course.code,
              style: const TextStyle(
                color: AppTheme.modernAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (course.description != null && course.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  course.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseEditScreen(course: course),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () => _confirmDelete(context, course),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseEditScreen(course: course),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete "${course.name}"? This will also delete all associated topics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(coursesProvider.notifier)
                    .deleteCourse(course.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

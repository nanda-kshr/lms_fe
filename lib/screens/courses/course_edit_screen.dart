import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/courses_provider.dart';
import '../../models/course.dart';
import '../../models/topic.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/glass_container.dart';

class CourseEditScreen extends ConsumerStatefulWidget {
  final Course? course;

  const CourseEditScreen({super.key, this.course});

  @override
  ConsumerState<CourseEditScreen> createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends ConsumerState<CourseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course?.name ?? '');
    _codeController = TextEditingController(text: widget.course?.code ?? '');
    _descController = TextEditingController(
      text: widget.course?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim(),
        'description': _descController.text.trim(),
      };

      if (widget.course == null) {
        await ref.read(coursesProvider.notifier).addCourse(data);
      } else {
        await ref
            .read(coursesProvider.notifier)
            .updateCourse(widget.course!.id, data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Topics Logic ─────────────────────────────────────

  void _showTopicDialog({Topic? topic}) {
    final nameController = TextEditingController(text: topic?.name ?? '');
    final descController = TextEditingController(
      text: topic?.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(topic == null ? 'Add Topic' : 'Edit Topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Topic Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
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
                final data = {
                  'name': nameController.text.trim(),
                  'description': descController.text.trim(),
                };

                if (topic == null) {
                  await ref
                      .read(topicsControllerProvider)
                      .addTopic(widget.course!.id, data);
                } else {
                  await ref
                      .read(topicsControllerProvider)
                      .updateTopic(widget.course!.id, topic.id, data);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving topic: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTopic(Topic topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text('Are you sure you want to delete "${topic.name}"?'),
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
                    .read(topicsControllerProvider)
                    .deleteTopic(widget.course!.id, topic.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting topic: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.modernBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ModernHeader(
              title: widget.course == null ? 'New Course' : 'Edit Course',
              subtitle: widget.course?.code ?? 'Create a new curriculum',
              showBackButton: true,
              onBack: () => Navigator.pop(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCourseForm(),
                if (widget.course != null) ...[
                  const SizedBox(height: 32),
                  _buildTopicsSection(),
                ],
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _isLoading
          ? null
          : (widget.course !=
                    null // Only show simple save button if mostly just editing details
                ? FloatingActionButton.extended(
                    onPressed: _saveCourse,
                    backgroundColor: AppTheme.modernAccent,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : FloatingActionButton.extended(
                    onPressed: _saveCourse,
                    backgroundColor: AppTheme.modernAccent,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Create Course',
                      style: TextStyle(color: Colors.white),
                    ),
                  )),
    );
  }

  Widget _buildCourseForm() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Course Code (e.g. CS101)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsSection() {
    final topicsAsync = ref.watch(topicsProvider(widget.course!.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Topics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.modernTextPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppTheme.modernAccent,
              ),
              onPressed: () => _showTopicDialog(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        topicsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text(
            'Error loading topics: $err',
            style: const TextStyle(color: Colors.red),
          ),
          data: (topics) {
            if (topics.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No topics added yet.'),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final topic = topics[index];
                return GlassContainer(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.modernAccent.withOpacity(0.1),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppTheme.modernAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      topic.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: topic.description != null
                        ? Text(topic.description!)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.blue,
                          ),
                          onPressed: () => _showTopicDialog(topic: topic),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _confirmDeleteTopic(topic),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

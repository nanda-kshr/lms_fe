import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/csv_template_service.dart';

import '../widgets/modern_header.dart';
import '../widgets/glass_container.dart';
import '../providers/vetting_provider.dart';
import '../providers/api_provider.dart'; // Added
import 'recent_uploads_screen.dart';

enum UploadType { questions, syllabus, content }

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  bool _isUploading = false;
  bool _isLoadingMetadata = false;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _topics = [];

  String? _selectedCourseCode;
  String? _selectedCourseId;
  String? _selectedTopicName;

  List<Map<String, dynamic>> _uploads = [];
  bool _isLoadingUploads = false;

  UploadType _uploadType = UploadType.questions;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    _fetchUploads();
  }

  Future<void> _fetchUploads() async {
    setState(() => _isLoadingUploads = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final uploads = await apiService.fetchUserUploads();
      if (mounted) {
        setState(() {
          _uploads = uploads;
          _isLoadingUploads = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUploads = false);
        // Silently fail or show snackbar? Silent is better for init
        print('Failed to load uploads: $e');
      }
    }
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoadingMetadata = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final courses = await apiService.fetchCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoadingMetadata = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMetadata = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load courses: $e')));
      }
    }
  }

  Future<void> _fetchTopics(String courseId) async {
    setState(() => _isLoadingMetadata = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final topics = await apiService.fetchTopics(courseId);
      if (mounted) {
        setState(() {
          _topics = topics;
          _isLoadingMetadata = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMetadata = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load topics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_fetchCourses(), _fetchUploads()]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: ModernHeader(title: 'Upload', subtitle: 'Add Questions'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader('STEP 1: GET TEMPLATE'),
                  _buildTemplateCard(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader('STEP 2: SELECT CATEGORY'),
                  _buildCategoryCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('STEP 3: UPLOAD TYPE'),
                  _buildTypeSelector(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('STEP 4: UPLOAD FILE'),
                  _buildUploadArea(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader('HISTORY'),
                  _buildHistoryItem(),
                ]),
              ),
            ),
          ],
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

  Widget _buildTemplateCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.modernAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppTheme.modernAccent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CSV Template',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Download our template to format your questions correctly',
                      style: TextStyle(
                        color: AppTheme.modernTextSecondary,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppGradients.downloadBlue,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppGradients.downloadBlue.colors.last.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      title: const Text('Select Template Type'),
                      children: TemplateType.values.map((type) {
                        return SimpleDialogOption(
                          onPressed: () async {
                            Navigator.pop(context);
                            final path =
                                await CsvTemplateService.downloadTemplate(type);
                            if (context.mounted) {
                              if (path != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Template saved to $path'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Failed to download template',
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.table_chart_outlined,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  CsvTemplateService.getTemplateName(type),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Download Template',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: _isLoadingMetadata && _courses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCourseDropdown(),
                const SizedBox(height: 16),
                _buildTopicDropdown(),
              ],
            ),
    );
  }

  Widget _buildCourseDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.modernTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCourseId,
              hint: const Text('Select Course'),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              items: _courses.map((course) {
                return DropdownMenuItem<String>(
                  value: course['_id'],
                  child: Text('${course['code']} - ${course['name']}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCourseId = value;
                    final course = _courses.firstWhere(
                      (c) => c['_id'] == value,
                    );
                    _selectedCourseCode = course['code'];
                    _selectedTopicName = null;
                    _topics = [];
                  });
                  _fetchTopics(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Topic',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.modernTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTopicName,
              hint: const Text('Select Topic'),
              isExpanded: true,
              icon: _isLoadingMetadata
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.keyboard_arrow_down_rounded),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              items: _topics.map((topic) {
                return DropdownMenuItem<String>(
                  value: topic['name'],
                  child: Text(topic['name']),
                );
              }).toList(),
              onChanged: _selectedCourseId == null
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTopicName = value;
                        });
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 8) / 3;
          return Row(
            children: [
              _buildTypeOption(
                UploadType.questions,
                'Questions',
                Icons.quiz_outlined,
                width,
              ),
              _buildTypeOption(
                UploadType.syllabus,
                'Syllabus',
                Icons.list_alt_rounded,
                width,
              ),
              _buildTypeOption(
                UploadType.content,
                'Material',
                Icons.book_outlined,
                width,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeOption(
    UploadType type,
    String label,
    IconData icon,
    double width,
  ) {
    final isSelected = _uploadType == type;
    return GestureDetector(
      onTap: () => setState(() => _uploadType = type),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.modernAccent : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea(BuildContext context) {
    bool isEnabled = false;

    if (_uploadType == UploadType.questions) {
      isEnabled = _selectedCourseCode != null && _selectedTopicName != null;
    } else {
      isEnabled = _selectedCourseCode != null;
    }

    String title = 'Upload CSV File';
    String subtitle = 'Tap to select file from your device';
    IconData icon = Icons.cloud_upload_rounded;
    Color color = const Color(0xFF34C759);

    switch (_uploadType) {
      case UploadType.questions:
        title = 'Upload Questions (CSV)';
        if (!isEnabled) {
          subtitle = 'Select Course & Topic first';
        }
        break;
      case UploadType.syllabus:
        title = 'Upload Syllabus (PDF/CSV)';
        color = Colors.orange;
        icon = Icons.list_alt_rounded;
        if (!isEnabled) {
          subtitle = 'Select Course first';
        }
        break;
      case UploadType.content:
        title = 'Upload Content (PDF)';
        color = Colors.blue;
        icon = Icons.book_rounded;
        if (!isEnabled) {
          subtitle = 'Select Course first';
        }
        break;
    }

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (_isUploading || !isEnabled)
                ? null
                : () => _handleUpload(context),
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isUploading)
                  const CircularProgressIndicator(color: Colors.white)
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpload(BuildContext context) async {
    if (_uploadType == UploadType.questions &&
        (_selectedCourseCode == null || _selectedTopicName == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Course and Topic first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } else if (_selectedCourseCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Course first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<String> allowedExtensions = ['csv'];
    if (_uploadType == UploadType.syllabus) {
      allowedExtensions = ['pdf', 'csv'];
    } else if (_uploadType == UploadType.content) {
      allowedExtensions = ['pdf'];
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      setState(() => _isUploading = true); // Start Loading

      try {
        final apiService = ref.read(apiServiceProvider);

        if (_uploadType == UploadType.questions) {
          await apiService.uploadQuestions(
            file,
            courseCode: _selectedCourseCode,
            topic: _selectedTopicName,
          );
        } else {
          await apiService.uploadMaterial(
            file,
            courseCode: _selectedCourseCode!,
            type: _uploadType == UploadType.syllabus ? 'SYLLABUS' : 'CONTENT',
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload successful! Processing started.'),
              backgroundColor: Colors.green,
            ),
          );
          if (_uploadType == UploadType.questions) {
            ref.refresh(vettingProvider.notifier).loadQuestions();
          }
          _fetchUploads();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false); // Stop Loading
        }
      }
    }
  }

  Widget _buildHistoryItem() {
    if (_isLoadingUploads) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_uploads.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            'No recent uploads',
            style: TextStyle(color: Colors.black45),
          ),
        ),
      );
    }

    return GlassContainer(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.history_rounded,
            color: Colors.blue,
            size: 28,
          ),
        ),
        title: const Text(
          'View Recent Uploads',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: const Text(
          'Check status of previous imports',
          style: TextStyle(color: Colors.black45, fontSize: 13),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.black26,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecentUploadsScreen(),
            ),
          );
        },
      ),
    );
  }
}

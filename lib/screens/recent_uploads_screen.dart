import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_header.dart';
import '../widgets/glass_container.dart';
import '../providers/api_provider.dart';

class RecentUploadsScreen extends ConsumerStatefulWidget {
  const RecentUploadsScreen({super.key});

  @override
  ConsumerState<RecentUploadsScreen> createState() =>
      _RecentUploadsScreenState();
}

class _RecentUploadsScreenState extends ConsumerState<RecentUploadsScreen> {
  List<Map<String, dynamic>> _uploads = [];
  bool _isLoading = true;
  bool _isQuestions = true;

  @override
  void initState() {
    super.initState();
    _fetchUploads();
  }

  Future<void> _fetchUploads() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final uploads = _isQuestions
          ? await apiService.fetchUserUploads()
          : await apiService.fetchUserMaterials();
      if (mounted) {
        setState(() {
          _uploads = uploads;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load uploads: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchUploads,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: ModernHeader(
                title: 'History',
                subtitle: 'Your Uploads',
                showBackButton: true,
                onBack: () => Navigator.pop(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildTypeToggle(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              sliver: _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _uploads.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Text(
                          _isQuestions
                              ? 'No question uploads found'
                              : 'No materials found',
                          style: const TextStyle(color: Colors.black45),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _isQuestions
                            ? _buildUploadCard(_uploads[index])
                            : _buildMaterialCard(_uploads[index]);
                      }, childCount: _uploads.length),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(Map<String, dynamic> upload) {
    final date =
        DateTime.tryParse(upload['uploaded_at'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat.yMMMd().add_jm().format(date);
    final course = upload['course_code'] ?? 'Unknown Course';
    final topic = upload['topic'] ?? 'Unknown Topic';
    final approved = upload['approved_count'] ?? 0;
    final rejected = upload['rejected_count'] ?? 0;
    final pending = upload['pending_count'] ?? 0;
    final total = upload['total_questions'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$course - $topic',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDeleteButton(() => _handleDeleteQuestion(upload['_id'])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(
                  Icons.check_circle_rounded,
                  Colors.green,
                  '$approved',
                ),
                const SizedBox(width: 12),
                _buildStatusChip(Icons.cancel_rounded, Colors.red, '$rejected'),
                const SizedBox(width: 12),
                _buildStatusChip(
                  Icons.hourglass_bottom_rounded,
                  Colors.orange,
                  '$pending',
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.modernAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$total Qs',
                    style: const TextStyle(
                      color: AppTheme.modernAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    final date =
        DateTime.tryParse(material['createdAt'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat.yMMMd().add_jm().format(date);
    final fileName = material['original_name'] ?? 'Unknown File';
    final course = material['course_code'] ?? 'Unknown Course';
    final type = material['type'] ?? 'CONTENT';
    final isProcessed = material['is_processed'] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$course • $type',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDeleteButton(
                  () => _handleDeleteMaterial(material['_id']),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isProcessed ? Colors.green : Colors.orange)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isProcessed ? 'Processed' : 'Processing',
                    style: TextStyle(
                      color: isProcessed ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildToggleOption(true, 'Questions'),
          _buildToggleOption(false, 'Materials'),
        ],
      ),
    );
  }

  Widget _buildToggleOption(bool isQuestions, String label) {
    final isSelected = _isQuestions == isQuestions;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_isQuestions != isQuestions) {
            setState(() {
              _isQuestions = isQuestions;
              _isLoading = true;
              _uploads = [];
            });
            _fetchUploads();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
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
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.modernAccent : Colors.black45,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(VoidCallback onDelete) {
    return IconButton(
      icon: const Icon(
        Icons.delete_outline_rounded,
        color: Colors.redAccent,
        size: 20,
      ),
      onPressed: onDelete,
    );
  }

  Future<void> _handleDeleteQuestion(String uploadId) async {
    final confirm = await _showDeleteConfirmation('questions');
    if (confirm == true) {
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.deleteQuestionUpload(uploadId);
        _fetchUploads();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  Future<void> _handleDeleteMaterial(String id) async {
    final confirm = await _showDeleteConfirmation('material');
    if (confirm == true) {
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.deleteMaterial(id);
        _fetchUploads();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(String type) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete these $type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, Color color, String count) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

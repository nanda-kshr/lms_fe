import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vetting_provider.dart';
import '../theme/app_theme.dart';
import '../models/question.dart';
import 'package:intl/intl.dart';

class VettingScreen extends ConsumerWidget {
  const VettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vettingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'FILTER QUESTIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.black54,
            ),
          ),
        ),
        _buildStatusTabs(ref, state.statusFilter),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.questions.isEmpty
              ? const Center(child: Text('No questions to vet'))
              : _buildQuestionContent(ref, state),
        ),
      ],
    );
  }

  Widget _buildStatusTabs(WidgetRef ref, String currentFilter) {
    return Row(
      children: [
        _buildTab(ref, 'pending', 'Pending', '3', currentFilter == 'pending'),
        _buildTab(
          ref,
          'approved',
          'Approved',
          '1',
          currentFilter == 'approved',
        ),
        _buildTab(
          ref,
          'rejected',
          'Rejected',
          '1',
          currentFilter == 'rejected',
        ),
        _buildTab(ref, 'skipped', 'Skipped', '1', currentFilter == 'skipped'),
      ],
    );
  }

  Widget _buildTab(
    WidgetRef ref,
    String status,
    String label,
    String count,
    bool isActive,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            ref.read(vettingProvider.notifier).loadQuestions(status: status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryBlue : Colors.black12,
            border: Border(
              right: const BorderSide(color: Colors.black12, width: 0.5),
              bottom: BorderSide(
                color: isActive ? Colors.transparent : Colors.black12,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count,
                style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.black38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionContent(WidgetRef ref, VettingState state) {
    final question = state.questions[state.currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Question ${state.currentIndex + 1} of ${state.questions.length}',
            style: const TextStyle(color: Colors.black38, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  question.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildQuestionMeta('Subject', question.courseCode ?? 'N/A'),
                _buildQuestionMeta('Topic', question.topic ?? 'N/A'),
                _buildQuestionMeta('Uploaded by', question.uploadedBy),
                _buildQuestionMeta('Date', _formatDate(question.uploadedAt)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavButton(
                icon: Icons.chevron_left,
                label: 'Previous',
                onPressed: state.currentIndex > 0
                    ? () =>
                          ref.read(vettingProvider.notifier).previousQuestion()
                    : null,
              ),
              _buildNavButton(
                icon: Icons.chevron_right,
                label: 'Next',
                onPressed: state.currentIndex < state.questions.length - 1
                    ? () => ref.read(vettingProvider.notifier).nextQuestion()
                    : null,
                isRight: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            label: 'Approve',
            icon: Icons.thumb_up_alt_outlined,
            gradient: AppGradients.approve,
            onPressed: () => ref
                .read(vettingProvider.notifier)
                .vetCurrentQuestion(VettingAction.accept),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Reject',
            icon: Icons.thumb_down_alt_outlined,
            gradient: AppGradients.reject,
            onPressed: () => ref
                .read(vettingProvider.notifier)
                .vetCurrentQuestion(VettingAction.reject),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Skip for Now',
            icon: Icons.skip_next_outlined,
            gradient: AppGradients.skip,
            onPressed: () => ref
                .read(vettingProvider.notifier)
                .vetCurrentQuestion(VettingAction.skip),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuestionMeta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black38, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isRight = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: onPressed == null ? Colors.black26 : Colors.blue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Row(
        children: isRight
            ? [Text(label), const SizedBox(width: 8), Icon(icon, size: 20)]
            : [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }
}

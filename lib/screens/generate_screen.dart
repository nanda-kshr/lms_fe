import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  int _selectedCO = -1;

  final List<String> _courseOutcomes = [
    'CO1: Understand basic programming concepts',
    'CO2: Apply data structures in problem solving',
    'CO3: Analyze algorithm complexity',
    'CO4: Design efficient algorithms',
    'CO5: Evaluate software quality metrics',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('SELECT COURSE OUTCOME'),
          _buildCOList(),
          const SizedBox(height: 24),
          _buildSectionHeader('HISTORY'),
          _buildHistoryItem(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildCOList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: _courseOutcomes.asMap().entries.map((entry) {
          final index = entry.key;
          final co = entry.value;
          return Column(
            children: [
              RadioListTile<int>(
                value: index,
                groupValue: _selectedCO,
                onChanged: (val) => setState(() => _selectedCO = val!),
                title: Text(
                  co,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                activeColor: AppTheme.primaryBlue,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              if (index < _courseOutcomes.length - 1)
                const Divider(height: 1, indent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryItem() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.psychology_outlined,
            color: Colors.purple,
            size: 24,
          ),
        ),
        title: const Text(
          'Generated Questions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: const Text(
          'View all generated questions',
          style: TextStyle(color: Colors.black38, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        onTap: () {},
      ),
    );
  }
}

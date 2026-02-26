import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'home_screen.dart';
import 'upload_screen.dart';
import 'vetting_screen.dart';
import 'generate_screen.dart';
import 'analytics_screen.dart';
import '../widgets/custom_nav_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final List<Widget> _screens = [
    const HomeScreen(),
    const UploadScreen(),
    const VettingScreen(),
    const GenerateScreen(),
    const AnalyticsScreen(),
  ];

  late final AnimationController _controller;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.reverse && _isVisible) {
      _controller.forward();
      setState(() => _isVisible = false);
    } else if (notification.direction == ScrollDirection.forward &&
        !_isVisible) {
      _controller.reverse();
      setState(() => _isVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          _onScroll(notification);
          return true;
        },
        child: _screens[currentIndex],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(opacity: 1.0 - _controller.value, child: child);
        },
        child: CustomNavBar(
          currentIndex: currentIndex,
          onTap: (index) =>
              ref.read(navigationProvider.notifier).setIndex(index),
        ),
      ),
    );
  }
}

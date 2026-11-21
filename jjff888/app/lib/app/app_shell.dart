import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'glass_bottom_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex() {
    for (var index = 0; index < glassNavItems.length; index++) {
      final destination = glassNavItems[index].location;
      if (destination == '/') {
        if (widget.location == '/') return index;
      } else if (widget.location == destination ||
          widget.location.startsWith('$destination/')) {
        return index;
      }
    }
    final sectionsIndex =
        glassNavItems.indexWhere((item) => item.location == '/sections');
    return sectionsIndex < 0 ? 0 : sectionsIndex;
  }

  bool get _isQuranReader =>
      RegExp(r'^/quran/\d+$').hasMatch(widget.location);

  bool get _isZiyaraReader =>
      RegExp(r'^/visits/volume_[0-9]+$').hasMatch(widget.location);

  String get _fallbackLocation {
    if (widget.location.startsWith('/quran/')) return '/quran';
    if (widget.location.startsWith('/visits/')) return '/visits';
    if (widget.location.startsWith('/book/')) return '/library';
    if (widget.location.startsWith('/visitor-guide')) return '/sections';
    if (widget.location.startsWith('/hadith/local')) return '/hadith';
    return '/';
  }

  void _handleBack(BuildContext context) {
    if (widget.location != '/') {
      context.go(_fallbackLocation);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('أنت في الصفحة الرئيسية.'),
          duration: Duration(milliseconds: 1100),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex();
    final canPop = GoRouter.of(context).canPop();
    return PopScope<Object?>(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: widget.child),
        bottomNavigationBar: _isQuranReader || _isZiyaraReader
            ? null
            : GlassBottomBar(
                items: glassNavItems,
                selectedIndex: selected,
                onSelect: (index) {
                  if (index < 0 || index >= glassNavItems.length) return;
                  final destination = glassNavItems[index].location;
                  if (widget.location != destination) context.go(destination);
                },
              ),
      ),
    );
  }
}

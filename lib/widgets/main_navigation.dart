import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animalitos_lottery/utils/constants.dart';
import 'states/main_navigation_state.dart';

class MainNavigation extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainNavigation({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  MainNavigationState createState() => MainNavigationState();
}

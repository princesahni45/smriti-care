// lib/core/voice/voice_route_tracker.dart
//
// Central route tracker and NavigatorObserver that monitors active routes,
// screen context, and modal popup states for the SmritiCare Voice Assistant.

import 'package:flutter/material.dart';

/// Tracks current route name, screen context, and whether modal sheets are open.
class VoiceRouteTracker extends NavigatorObserver with ChangeNotifier {
  VoiceRouteTracker._();
  static final VoiceRouteTracker instance = VoiceRouteTracker._();

  String _currentRoute = '/';
  bool _isModalOpen = false;

  /// The active route path (e.g., '/', '/games', '/take-me-home').
  String get currentRoute => _currentRoute;

  /// Whether a dialog or modal bottom sheet is currently on top.
  bool get isModalOpen => _isModalOpen;

  void _safeNotifyListeners() {
    final binding = WidgetsBinding.instance;
    if (binding.buildOwner?.debugBuilding ?? false) {
      binding.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  /// Explicitly set the active route (useful for bottom tab switching).
  void setCurrentRoute(String route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      _safeNotifyListeners();
    }
  }

  /// Explicitly update the modal visibility state.
  void setModalOpen(bool open) {
    if (_isModalOpen != open) {
      _isModalOpen = open;
      _safeNotifyListeners();
    }
  }

  /// Whether the active route is a caregiver or admin screen.
  bool get isCaregiverRoute {
    final lower = _currentRoute.toLowerCase();
    return lower.contains('caregiver') ||
        lower.contains('mri') ||
        lower.contains('admin');
  }

  /// Whether the active route is an auth or splash screen.
  bool get isAuthRoute {
    final lower = _currentRoute.toLowerCase();
    return lower == '/role-select' ||
        lower.startsWith('/login') ||
        lower == '/register' ||
        lower == '/splash';
  }

  /// Determines whether the patient-side floating Voice button should be shown.
  bool get shouldShowFloatingButton {
    return !_isModalOpen && !isCaregiverRoute && !isAuthRoute;
  }

  /// Whether the current screen is within the root mobile shell which has a BottomNavigationBar.
  bool get isShellScreenWithBottomNav {
    return _currentRoute == '/' ||
        _currentRoute == '/dashboard' ||
        _currentRoute.startsWith('/dashboard/');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _evaluateRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PopupRoute) {
      _isModalOpen = false;
      _safeNotifyListeners();
    } else if (previousRoute != null) {
      _evaluateRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _evaluateRoute(newRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (previousRoute != null) {
      _evaluateRoute(previousRoute);
    }
  }

  void _evaluateRoute(Route<dynamic> route) {
    if (route is PopupRoute) {
      _isModalOpen = true;
      _safeNotifyListeners();
      return;
    }

    _isModalOpen = false;
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      _currentRoute = name;
      _safeNotifyListeners();
    }
  }
}

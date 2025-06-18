import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/people_list_screen.dart';
import '../screens/task_creation_screen.dart';
import '../screens/settings_screen.dart';
import '../models/task.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final bool isAuthenticated = authProvider.isAuthenticated;
        final bool isLoading = authProvider.isLoading;

        // If still loading, don't redirect
        if (isLoading) {
          return null;
        }

        // If not authenticated and not on login page, redirect to login
        if (!isAuthenticated && state.matchedLocation != '/login') {
          return '/login';
        }

        // If authenticated and on login page, redirect to home
        if (isAuthenticated && state.matchedLocation == '/login') {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder:
              (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const LoginScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
        ),
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          pageBuilder:
              (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const HomeScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
        ),
        GoRoute(
          path: '/people',
          name: 'people',
          pageBuilder:
              (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const PeopleListScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
        ),
        GoRoute(
          path: '/task-creation',
          name: 'task-creation',
          pageBuilder:
              (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const TaskCreationScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
        ),
        GoRoute(
          path: '/task/create',
          name: 'createTask',
          pageBuilder:
              (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const TaskCreationScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
        ),
        GoRoute(
          path: '/task/edit/:taskId',
          name: 'editTask',
          pageBuilder: (context, state) {
            final task = state.extra as Task?;
            return CustomTransitionPage(
              key: state.pageKey,
              child: TaskCreationScreen(task: task),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          },
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder:
              (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
        ),
      ],
    );
  }

  // Legacy getter for backward compatibility
  static GoRouter get router {
    throw UnsupportedError('Use AppRouter.createRouter(authProvider) instead');
  }
}

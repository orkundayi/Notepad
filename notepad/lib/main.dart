import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/person_provider.dart';
import 'providers/responsive_provider.dart';
import 'utils/app_router.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web performans optimizations
  if (kIsWeb) {
    // Disable debug prints in release mode
    if (kReleaseMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
    }
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ResponsiveProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => PersonProvider()),
      ],
      child: Consumer2<AuthProvider, ResponsiveProvider>(
        builder: (context, authProvider, responsiveProvider, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // Screen size değişikliklerini ResponsiveProvider'a bildir
              WidgetsBinding.instance.addPostFrameCallback((_) {
                responsiveProvider.updateScreenSize(
                  Size(constraints.maxWidth, constraints.maxHeight),
                );
              });

              return MaterialApp.router(
                title: 'Task Manager - Professional Web Dashboard',
                theme: AppTheme.lightTheme,
                debugShowCheckedModeBanner: false,
                routerConfig: AppRouter.createRouter(authProvider),
                // Web specific performance optimizations
              );
            },
          );
        },
      ),
    );
  }
}

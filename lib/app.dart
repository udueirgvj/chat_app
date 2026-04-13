// lib/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/profile/profile_screen.dart';

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final loggedIn = auth.isAuthenticated;
        final onAuth = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        final onSplash = state.matchedLocation == '/splash';

        if (onSplash) return null;
        if (!loggedIn && !onAuth) return '/login';
        if (loggedIn && onAuth) return '/home';
        return null;
      },
      refreshListenable: context.read<AuthProvider>(),
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (_, __) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/chat/:chatId',
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ChatScreen(
              chatId: state.pathParameters['chatId']!,
              otherUserId: extra?['otherUserId'] as String? ?? '',
              otherUserName: extra?['otherUserName'] as String? ?? '',
              otherUserPhoto: extra?['otherUserPhoto'] as String? ?? '',
              isGroup: extra?['isGroup'] as bool? ?? false,
            );
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return MaterialApp.router(
      title: 'ChatApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark, // Default dark like Telegram
      routerConfig: _router,
      builder: (context, child) {
        // Rebuild router when auth state changes
        if (auth.status == AuthStatus.initial) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

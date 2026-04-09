import 'package:dart_project/app/theme.dart';
import 'package:dart_project/features/auth/data/local_auth_repository.dart';
import 'package:dart_project/features/auth/domain/auth_session.dart';
import 'package:dart_project/features/auth/presentation/auth_page.dart';
import 'package:dart_project/features/habits/data/local_habits_repository.dart';
import 'package:dart_project/features/habits/presentation/habits_controller.dart';
import 'package:dart_project/features/habits/presentation/habits_page.dart';
import 'package:flutter/material.dart';

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  late final LocalAuthRepository _authRepository;
  HabitsController? _controller;
  AuthSession? _session;
  bool _isBootstrapping = true;

  @override
  void initState() {
    super.initState();
    _authRepository = LocalAuthRepository();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final existingSession = await _authRepository.getCurrentSession();
    if (!mounted) {
      return;
    }

    if (existingSession != null) {
      _setSession(existingSession);
    }

    setState(() {
      _isBootstrapping = false;
    });
  }

  void _setSession(AuthSession session) {
    _controller?.dispose();
    _controller = HabitsController(
      repository: LocalHabitsRepository(userId: session.username),
    );
    _session = session;
  }

  Future<void> _handleAuthenticated(AuthSession session) async {
    setState(() {
      _setSession(session);
    });
  }

  Future<void> _handleLogout() async {
    await _authRepository.signOut();
    if (!mounted) {
      return;
    }

    setState(() {
      _controller?.dispose();
      _controller = null;
      _session = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = _isBootstrapping
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : _session == null
        ? AuthPage(
            repository: _authRepository,
            onAuthenticated: _handleAuthenticated,
          )
        : HabitsPage(
            controller: _controller!,
            username: _session!.username,
            onLogout: _handleLogout,
          );

    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: home,
    );
  }
}

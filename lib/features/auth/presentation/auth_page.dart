import 'package:dart_project/features/auth/data/local_auth_repository.dart';
import 'package:dart_project/features/auth/domain/auth_session.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.repository,
    required this.onAuthenticated,
  });

  final LocalAuthRepository repository;
  final void Function(AuthSession session) onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUpMode = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    final error = _isSignUpMode
        ? await widget.repository.signUp(username: username, password: password)
        : await widget.repository.signIn(
            username: username,
            password: password,
          );

    if (!mounted) {
      return;
    }

    if (error != null) {
      setState(() {
        _isSubmitting = false;
        _error = error;
      });
      return;
    }

    final session = await widget.repository.getCurrentSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (session != null) {
      widget.onAuthenticated(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSignUpMode ? 'Create account' : 'Sign in';
    final subtitle = _isSignUpMode
        ? 'Create an account to track your own habits.'
        : 'Sign in to continue your habit progress.';

    return Scaffold(
      appBar: AppBar(title: const Text('Habit Tracker')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(subtitle),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _usernameController,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        enabled: !_isSubmitting,
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: Text(_isSignUpMode ? 'Sign up' : 'Sign in'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _isSignUpMode = !_isSignUpMode;
                                    _error = null;
                                  });
                                },
                          child: Text(
                            _isSignUpMode
                                ? 'Already have an account? Sign in'
                                : 'Need an account? Sign up',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../controller/app_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin123');
  var _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await AppScope.of(
        context,
      ).login(_usernameController.text, _passwordController.text);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 920 : 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(child: _LoginIntro()),
                            const SizedBox(width: 32),
                            Expanded(
                              child: _LoginForm(
                                formKey: _formKey,
                                usernameController: _usernameController,
                                passwordController: _passwordController,
                                onSubmit: () {
                                  _submit();
                                },
                                errorMessage: app.auth.errorMessage,
                                isSubmitting: _isSubmitting,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _LoginIntro(),
                            const SizedBox(height: 24),
                            _LoginForm(
                              formKey: _formKey,
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              onSubmit: () {
                                _submit();
                              },
                              errorMessage: app.auth.errorMessage,
                              isSubmitting: _isSubmitting,
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

class _LoginIntro extends StatelessWidget {
  const _LoginIntro();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EFE9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.account_balance,
            size: 36,
            color: Color(0xFF235347),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'PQR Cooperative',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Member and Loan Management System',
          style: textTheme.titleMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        const Text(
          'Digitize member records, savings activity, loan processing, repayments, and compliance reports with a Supabase-backed system.',
        ),
        const SizedBox(height: 20),
        const _CredentialHint(
          label: 'Administrator',
          username: 'admin',
          password: 'admin123',
        ),
        const SizedBox(height: 8),
        const _CredentialHint(
          label: 'Treasurer',
          username: 'treasurer',
          password: 'treasurer123',
        ),
      ],
    );
  }
}

class _CredentialHint extends StatelessWidget {
  const _CredentialHint({
    required this.label,
    required this.username,
    required this.password,
  });

  final String label;
  final String username;
  final String password;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $username / $password',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.onSubmit,
    required this.errorMessage,
    required this.isSubmitting,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final String? errorMessage;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sign in',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('usernameField'),
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Username is required.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('passwordField'),
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            onFieldSubmitted: (_) => onSubmit(),
            validator: (value) =>
                value == null || value.isEmpty ? 'Password is required.' : null,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('loginButton'),
            onPressed: isSubmitting ? null : onSubmit,
            icon: const Icon(Icons.login),
            label: Text(isSubmitting ? 'Signing in...' : 'Sign in'),
          ),
        ],
      ),
    );
  }
}

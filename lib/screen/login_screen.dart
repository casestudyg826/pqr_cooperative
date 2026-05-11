import 'package:flutter/material.dart';

import '../controller/app_controller.dart';

enum _AuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin123');

  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _signUpUsernameController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  var _isSubmitting = false;
  var _mode = _AuthMode.signIn;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _signUpUsernameController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignIn() async {
    if (!_signInFormKey.currentState!.validate()) {
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

  Future<void> _submitSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await AppScope.of(context).signUpMember(
        fullName: _fullNameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        username: _signUpUsernameController.text,
        password: _signUpPasswordController.text,
      );
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
                            Expanded(child: _LoginIntro(mode: _mode)),
                            const SizedBox(width: 32),
                            Expanded(
                              child: _AuthPanel(
                                mode: _mode,
                                isSubmitting: _isSubmitting,
                                errorMessage: app.auth.errorMessage,
                                onModeChanged: (mode) {
                                  setState(() => _mode = mode);
                                },
                                signInFormKey: _signInFormKey,
                                usernameController: _usernameController,
                                passwordController: _passwordController,
                                onSignIn: _submitSignIn,
                                signUpFormKey: _signUpFormKey,
                                fullNameController: _fullNameController,
                                addressController: _addressController,
                                phoneController: _phoneController,
                                signUpUsernameController:
                                    _signUpUsernameController,
                                signUpPasswordController:
                                    _signUpPasswordController,
                                signUpConfirmPasswordController:
                                    _signUpConfirmPasswordController,
                                onSignUp: _submitSignUp,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LoginIntro(mode: _mode),
                            const SizedBox(height: 24),
                            _AuthPanel(
                              mode: _mode,
                              isSubmitting: _isSubmitting,
                              errorMessage: app.auth.errorMessage,
                              onModeChanged: (mode) {
                                setState(() => _mode = mode);
                              },
                              signInFormKey: _signInFormKey,
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              onSignIn: _submitSignIn,
                              signUpFormKey: _signUpFormKey,
                              fullNameController: _fullNameController,
                              addressController: _addressController,
                              phoneController: _phoneController,
                              signUpUsernameController:
                                  _signUpUsernameController,
                              signUpPasswordController:
                                  _signUpPasswordController,
                              signUpConfirmPasswordController:
                                  _signUpConfirmPasswordController,
                              onSignUp: _submitSignUp,
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
  const _LoginIntro({required this.mode});

  final _AuthMode mode;

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
        Text(
          mode == _AuthMode.signIn
              ? 'Staff and members can sign in to continue.'
              : 'Create a member account to view your savings balance and apply for loans.',
        ),
        if (mode == _AuthMode.signIn) ...[
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

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.mode,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onModeChanged,
    required this.signInFormKey,
    required this.usernameController,
    required this.passwordController,
    required this.onSignIn,
    required this.signUpFormKey,
    required this.fullNameController,
    required this.addressController,
    required this.phoneController,
    required this.signUpUsernameController,
    required this.signUpPasswordController,
    required this.signUpConfirmPasswordController,
    required this.onSignUp,
  });

  final _AuthMode mode;
  final bool isSubmitting;
  final String? errorMessage;
  final ValueChanged<_AuthMode> onModeChanged;

  final GlobalKey<FormState> signInFormKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onSignIn;

  final GlobalKey<FormState> signUpFormKey;
  final TextEditingController fullNameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController signUpUsernameController;
  final TextEditingController signUpPasswordController;
  final TextEditingController signUpConfirmPasswordController;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<_AuthMode>(
          segments: const [
            ButtonSegment(
              value: _AuthMode.signIn,
              icon: Icon(Icons.login),
              label: Text('Sign in'),
            ),
            ButtonSegment(
              value: _AuthMode.signUp,
              icon: Icon(Icons.person_add_alt_1),
              label: Text('Sign up'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) => onModeChanged(selection.first),
        ),
        const SizedBox(height: 16),
        if (mode == _AuthMode.signIn)
          _SignInForm(
            formKey: signInFormKey,
            usernameController: usernameController,
            passwordController: passwordController,
            onSubmit: onSignIn,
            isSubmitting: isSubmitting,
          )
        else
          _SignUpForm(
            formKey: signUpFormKey,
            fullNameController: fullNameController,
            addressController: addressController,
            phoneController: phoneController,
            usernameController: signUpUsernameController,
            passwordController: signUpPasswordController,
            confirmPasswordController: signUpConfirmPasswordController,
            onSubmit: onSignUp,
            isSubmitting: isSubmitting,
          ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _SignInForm extends StatelessWidget {
  const _SignInForm({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
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
            validator: _required,
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
            validator: _required,
          ),
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

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    required this.formKey,
    required this.fullNameController,
    required this.addressController,
    required this.phoneController,
    required this.usernameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSubmit;
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
            'Create member account',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('signupFullNameField'),
            controller: fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('signupPhoneField'),
            controller: phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('signupAddressField'),
            controller: addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('signupUsernameField'),
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('signupPasswordField'),
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('signupConfirmPasswordField'),
            controller: confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: Icon(Icons.lock_reset_outlined),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required.';
              }
              if (value != passwordController.text) {
                return 'Passwords do not match.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('signupButton'),
            onPressed: isSubmitting ? null : onSubmit,
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(
              isSubmitting ? 'Creating account...' : 'Create account',
            ),
          ),
        ],
      ),
    );
  }
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Required.' : null;

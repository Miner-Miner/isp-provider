// lib/pages/login.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isp_provider/const/route.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final supabase = Supabase.instance.client;
    final res = await supabase.auth.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    ).onError(
      (error, stackTrace) {
        setState(() {
          _isLoading = false;
        });
        throw(error.toString());
      },
    );
    setState(() => _isLoading = false);

    if (res is AuthException) {
      setState(() => _errorMessage = res.toString());
    } else {
      Navigator.pushReplacementNamed(context, homeRoute);
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final supabase = Supabase.instance.client;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter your email to reset password.';
      });
      return;
    }
    await supabase.auth.resetPasswordForEmail(
      email,
    );
    setState(() => _isLoading = false);
    {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Password Reset'),
          content: const Text('Check your email for password reset link.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, registerRoute),
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/page/register.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isp_provider/const/route.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
} 

class _RegisterPageState extends State<RegisterPage> {
  final _email     = TextEditingController();
  final _pass      = TextEditingController();
  final _confirm   = TextEditingController();
  bool _loading    = false;
  String? _error;

  Future<void> _next() async {
    final e = _email.text.trim();
    final p = _pass.text;
    final c = _confirm.text;

    if (e.isEmpty || p.isEmpty || c.isEmpty) {
      setState(() => _error = 'All fields required');
      return;
    }
    if (p != c) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      // maybeSingle() returns Map<String, dynamic>? or throws on HTTP/error
      final existing = await Supabase.instance.client
          .from('user')
          .select('id')
          .eq('email', e)
          .maybeSingle();

      if (existing != null) {
        // found a row → email already taken
        setState(() => _error = 'This email is already registered');
      } else {
        // no row → safe to proceed
        Navigator.pushNamed(
          context,
          registerDetailRoute,
          arguments: {'email': e, 'password': p},
        );
      }
    } catch (err) {
      // network / permission / other error
      setState(() => _error = err.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pass,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirm,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _next,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

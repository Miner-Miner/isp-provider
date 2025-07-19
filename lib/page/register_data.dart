// lib/views/register_data_page.dart

import 'dart:developer';
import 'dart:math' hide log;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isp_provider/const/route.dart';

class RegisterDataPage extends StatefulWidget {
  const RegisterDataPage({super.key});

  @override
  State<RegisterDataPage> createState() => _RegisterDataPageState();
}

class _RegisterDataPageState extends State<RegisterDataPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  bool _loading = false;
  String? _error;

  /// Generates "ECS" + 8 random digits (from 10000000 to 99999999)
  String _generateDeviceId() {
    final rnd = Random.secure();
    final eightDigits = rnd.nextInt(90000000) + 10000000;
    return 'ECS$eightDigits';
  }

  Future<void> _finish(Map args) async {
    final email = args['email'] as String;
    final pass = args['password'] as String;

    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final address = _address.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final supa = Supabase.instance.client;
    String? userId;

    try {
      // 1) Sign up and get user ID
      final authRes = await supa.auth.signUp(email: email, password: pass);
      userId = authRes.user?.id;
      if (userId == null) throw 'User ID not returned after sign-up';
    } on AuthException catch (ae) {
      log('AuthException: ${ae.message}');
      setState(() {
        _error = ae.message;
        _loading = false;
      });
      return;
    } catch (e) {
      log('Unexpected signUp error: $e');
      setState(() {
        _error = 'Failed to sign up: $e';
        _loading = false;
      });
      return;
    }

    // 2) Try inserting profile + device_id with retries on collisions
    const int maxAttempts = 5;
    bool inserted = false;
    for (var attempt = 1; attempt <= maxAttempts && !inserted; attempt++) {
      final deviceId = _generateDeviceId();
      try {
        await supa.from('user').insert({
          'user_id': userId,
          'email': email,
          'name': name,
          'phone': phone,
          'address': address,
          'device_id': deviceId,
          'approved': false,
        });
        inserted = true;
        log('Inserted user with device_id=$deviceId');
      } on PostgrestException catch (e) {
        // Check for unique-constraint violation on device_id
        final msg = e.message.toLowerCase();
        if (msg.contains('duplicate') && msg.contains('device_id')) {
          log('Attempt $attempt: device_id collision, retrying...');
          // loop continues to next attempt
        } else {
          // Some other DB error
          log('Database error on attempt $attempt: ${e.message}');
          setState(() {
            _error = 'Database error: ${e.message}';
            _loading = false;
          });
          return;
        }
      } catch (e) {
        log('Unexpected insertion error: $e');
        setState(() {
          _error = 'Failed to save user data: $e';
          _loading = false;
        });
        return;
      }
    }

    if (!inserted) {
      setState(() {
        _error =
            'Could not generate a unique device ID after $maxAttempts attempts.';
        _loading = false;
      });
      return;
    }

    // 3) Success → Navigate to home
    if (mounted) {
      Navigator.pushReplacementNamed(context, homeRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Expecting arguments: { 'email': ..., 'password': ... }
    final args = ModalRoute.of(context)!.settings.arguments as Map;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : () => _finish(args),
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

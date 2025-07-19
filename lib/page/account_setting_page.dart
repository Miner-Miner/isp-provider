// lib/page/account_settings_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isp_provider/const/route.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});
  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _nameController        = TextEditingController();
  final _phoneController       = TextEditingController();
  final _addressController     = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _loadingData = true;
  bool _saving      = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = 'User not signed in.';
          _loadingData = false;
        });
        return;
      }

      final resp = await client
          .from('user')
          .select('name, phone, address')
          .eq('user_id', userId)
          .maybeSingle();

      if (resp != null) {
        _nameController.text    = resp['name']    ?? '';
        _phoneController.text   = resp['phone']   ?? '';
        _addressController.text = resp['address'] ?? '';
      } else {
        _error = 'Profile not found.';
      }
    } catch (e) {
      _error = 'Failed to load profile: $e';
    } finally {
      setState(() => _loadingData = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error  = null;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw 'User not found.';

      await client
          .from('user')
          .update({
            'name'   : _nameController.text.trim(),
            'phone'  : _phoneController.text.trim(),
            'address': _addressController.text.trim(),
          })
          .eq('user_id', userId);

      if (_newPasswordController.text.isNotEmpty) {
        await client.auth.updateUser(
          UserAttributes(password: _newPasswordController.text),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error  = 'Save failed: $e';
        _saving = false;
      });
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacementNamed(context, loginRoute);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password (leave blank to keep)',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const CircularProgressIndicator()
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

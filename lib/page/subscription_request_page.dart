// lib/page/subscription_request_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionRequestPage extends StatefulWidget {
  final int packageId;

  const SubscriptionRequestPage({super.key, required this.packageId});

  @override
  State<SubscriptionRequestPage> createState() =>
      _SubscriptionRequestPageState();
}

class _SubscriptionRequestPageState extends State<SubscriptionRequestPage> {
  final _accountNameCtrl = TextEditingController();
  File? _slipFile;
  bool _loading = false;
  String? _error;

  Future<void> _pickSlip() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _slipFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final accountName = _accountNameCtrl.text.trim();
    if (accountName.isEmpty || _slipFile == null) {
      setState(() => _error = 'Please enter account name and pick a slip image.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supa = Supabase.instance.client;
      final uid  = supa.auth.currentUser!.id;
      final fileName = 'slips/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 1) Upload slip to Storage bucket "payment_slips"
      await supa.storage
          .from('payment-slips')
          .upload(fileName, _slipFile!, fileOptions: FileOptions(upsert: true));

      // 2) Get public URL
      final publicUrl = supa.storage
          .from('payment- slips')
          .getPublicUrl(fileName);

      // 3) Insert subscription request row
      await supa.from('subscription_requests').insert({
        'user_id'           : uid,
        'package_id'        : widget.packageId,
        'account_name'      : accountName,
        'transfer_image_url': publicUrl,
      });

      // 4) Success—pop back
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription request submitted!')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Make Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Transfer instructions image (hardcoded asset or network)
            Image.asset('assets/transfer_instructions.png',
                height: 180, fit: BoxFit.contain),
            const SizedBox(height: 16),

            TextField(
              controller: _accountNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Account Name',
              ),
            ),
            const SizedBox(height: 12),

            // Slip picker
            _slipFile == null
                ? OutlinedButton.icon(
                    onPressed: _pickSlip,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Slip Image'),
                  )
                : Column(
                    children: [
                      Image.file(_slipFile!, height: 120),
                      TextButton(
                        onPressed: () => setState(() => _slipFile = null),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),

            const Spacer(),

            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Subscribe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

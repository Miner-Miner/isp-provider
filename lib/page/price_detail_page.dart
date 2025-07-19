// lib/page/price_detail_page.dart

import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isp_provider/const/route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PriceDetailPage extends StatefulWidget {
  final Map<String, dynamic> package;
  const PriceDetailPage({super.key, required this.package});

  @override
  State<PriceDetailPage> createState() => _PriceDetailPageState();
}

class _PriceDetailPageState extends State<PriceDetailPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Future<List<Bank>> _banksFuture;
  Bank? _selectedBank;
  Uint8List? _uploadedBytes;
  bool _subscribing = false;

  @override
  void initState() {
    super.initState();
    _banksFuture = _fetchBanks();
  }

  Future<List<Bank>> _fetchBanks() async {
    final data = await _supabase
        .from('bank')
        .select('id, name, account, image_url')
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Bank.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _pickUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _uploadedBytes = result.files.first.bytes;
      });
    }
  }

  Future<void> _subscribe() async {
    log("Clicked");
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bank first.')),
      );
      return;
    }
    if (_uploadedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a proof image.')),
      );
      return;
    }

    setState(() => _subscribing = true);

    try {
      // 1) Upload proof image
      final key = 'proof_${DateTime.now().millisecondsSinceEpoch}.png';
      await _supabase.storage
          .from('subscription-proofs')
          .uploadBinary(key, _uploadedBytes!,
            fileOptions: const FileOptions(upsert: true))
          .onError((error, stackTrace) => throw(error.toString()),);

      // 2) Get public URL
      final publicUrl = _supabase
          .storage
          .from('subscription-proofs')
          .getPublicUrl(key);

      final authUser = _supabase.auth.currentUser;
      if (authUser == null) throw 'Not logged in';

      // 2) Look up your profile row ID in `public.user`
      final profile = await _supabase
          .from('user')
          .select('id')
          .eq('user_id', authUser.id)
          .maybeSingle();

      if (profile == null || profile['id'] == null) {
        throw 'User profile not found';
      }
      final profileId = profile['id'] as String;

      // 3) Insert using the PROFILE ID
      final pkgId = widget.package['id'] as String;
      await _supabase.from('subscription').insert({
        'user_id'    : profileId,
        'package_id' : pkgId,
        'payment_url': publicUrl,
        'status' : 'pending',
      }).onError((error, stackTrace) => throw(error.toString()),);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription created!')),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        homeRoute,
        (route) => false,
      );
      // You might navigate away or reset state here.

    } catch (e) {
      log(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription failed: $e')),
      );
    } finally {
      setState(() => _subscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkg       = widget.package;
    final name      = pkg['name']        as String? ?? '';
    final lifetime  = pkg['lifetime']    as String? ?? '';
    final priceNum  = pkg['price']       as num?    ?? 0;
    final price     = priceNum.toString();
    final desc      = pkg['description'] as String? ?? 'No description';
    final createdAt = pkg['created_at']  as String? ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ---- package header ----
          Text(name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Duration: $lifetime', style: const TextStyle(fontSize: 16)),
          Text('Price: $price', style: const TextStyle(fontSize: 16)),
          const Divider(height: 24),

          // ---- description ----
          Text(desc),
          const SizedBox(height: 24),

          // ---- bank selector ----
          FutureBuilder<List<Bank>>(
            future: _banksFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final banks = snap.data ?? [];
              return DropdownButton<Bank>(
                hint: const Text('Select Bank'),
                isExpanded: true,
                value: _selectedBank,
                items: banks.map((b) => DropdownMenuItem(
                  value: b,
                  child: Text(b.name),
                )).toList(),
                onChanged: (b) => setState(() => _selectedBank = b),
              );
            },
          ),
          const SizedBox(height: 12),

          // ---- selected bank ----
          if (_selectedBank != null) ...[
            Text('Account: ${_selectedBank!.account}'),
            const SizedBox(height: 8),
            Image.network(_selectedBank!.imageUrl, height: 120, fit: BoxFit.contain),
            const SizedBox(height: 24),
          ],

          // ---- upload proof ----
          ElevatedButton.icon(
            onPressed: _pickUploadImage,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Image'),
          ),
          if (_uploadedBytes != null) ...[
            const SizedBox(height: 12),
            Image.memory(_uploadedBytes!, height: 150, fit: BoxFit.contain),
            const SizedBox(height: 24),
          ],

          // ---- subscribe ----
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _subscribing ? null : _subscribe,
              child: _subscribing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Subscribe'),
            ),
          ),

        ]),
      ),
    );
  }
}

class Bank {
  final String id, name, account, imageUrl;
  Bank({
    required this.id,
    required this.name,
    required this.account,
    required this.imageUrl,
  });
  factory Bank.fromMap(Map<String, dynamic> m) => Bank(
      id: m['id'] as String,
      name: m['name'] as String,
      account: m['account'] as String,
      imageUrl: m['image_url'] as String,
  );
}

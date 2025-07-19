// lib/page/info_tab.dart

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InfoTab extends StatelessWidget {
  const InfoTab({super.key});

  Future<String> _fetchSubscriptionInfo() async {
    final supa = Supabase.instance.client;
    final authUser = supa.auth.currentUser;
    if (authUser == null) return '';

    // Look up our profile row
    
    String sub = '';
    await supa
      .from('user')
      .select('package_expiry')
      .eq('user_id', authUser.id)
      .maybeSingle()
      .then((value) {
        sub = value?['package_expiry'] as String? ?? '';
        log(value.toString());
      },);
      log(sub);

    return sub;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _fetchSubscriptionInfo(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        final info = snap.data;
        log(info!);
        if (info.isEmpty) {
          return const Center(
            child: Text(
              'No subscription currently exists.',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final String expiry = info;
        DateTime? expDate;
        try {
          expDate = DateTime.parse(expiry).toLocal();
        } catch (_) {
          expDate = null;
        }

        final expiryText = expDate != null
            ? '${expDate.year}-${expDate.month.toString().padLeft(2,'0')}-'
              '${expDate.day.toString().padLeft(2,'0')}'
            : 'Invalid date';

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Plan:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Expires on:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                expiryText,
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}

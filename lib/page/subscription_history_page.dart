// lib/page/subscription_history_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionHistoryPage extends StatefulWidget {
  const SubscriptionHistoryPage({super.key});

  @override
  State<SubscriptionHistoryPage> createState() =>
      _SubscriptionHistoryPageState();
}

class _SubscriptionHistoryPageState extends State<SubscriptionHistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyFuture;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) throw 'Not signed in';

    // first look up profile row ID in public.user
    final prof = await _supabase
        .from('user')
        .select('id')
        .eq('user_id', authUser.id)
        .maybeSingle();
    final profileId = prof?['id'] as String?;
    if (profileId == null) throw 'User profile not found';

    // now load subscriptions for that profile
    final resp = await _supabase
        .from('subscription')
        .select(r'''
          id,
          created_at,
          status,
          package:package_id ( name, price, lifetime )
        ''')
        .eq('user_id', profileId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(resp as List);
  }

  String _formatDate(String raw) {
    final d = DateTime.parse(raw).toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
           '${d.day.toString().padLeft(2, '0')} '
           '${d.hour.toString().padLeft(2, '0')}:'
           '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final history = snap.data!;
          if (history.isEmpty) {
            return const Center(child: Text('No subscriptions found.'));
          }
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (ctx, i) {
              final row = history[i];
              final package = row['package'] as Map<String, dynamic>;
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(package['name'] as String),
                  subtitle: Text(
                    'Subscribed on ${_formatDate(row['created_at'] as String)}\n'
                    'Status: ${row['status']}',
                  ),
                  trailing: Text('${package['price']}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// lib/page/setting_tab.dart
import 'package:flutter/material.dart';
import 'package:isp_provider/const/route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingTab extends StatelessWidget {
  const SettingTab({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacementNamed(context, loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, subscriptionHistoryRoute);
            },
            child: const Text('Subscription History'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, accountSettingsRoute);
            },
            child: const Text('Account Settings'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, complaintFormRoute); // ✅ New Button
            },
            child: const Text('Complaint Form'),
          ),
          const Spacer(), // Pushes logout to bottom
          ElevatedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

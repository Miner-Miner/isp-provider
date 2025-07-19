// lib/main.dart
import 'package:flutter/material.dart';
import 'package:isp_provider/page/account_setting_page.dart';
import 'package:isp_provider/page/complaint_page.dart';
import 'package:isp_provider/page/price_detail_page.dart';
import 'package:isp_provider/page/subscription_history_page.dart';
import 'package:isp_provider/page/subscription_request_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isp_provider/const/route.dart';
import 'package:isp_provider/page/login.dart';
import 'package:isp_provider/page/register.dart';
import 'package:isp_provider/page/register_data.dart';
import 'package:isp_provider/page/home.dart';
import 'package:isp_provider/const/keys.dart';
import 'package:isp_provider/const/urls.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  // Supabase persists session automatically. No manual re-login needed.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Use AuthGate to handle auto-login on app start
      home: const AuthGate(),
      routes: {
        loginRoute: (context) => const LoginPage(),
        homeRoute: (context) => const HomePage(),
        registerRoute: (context) => const RegisterPage(),
        registerDetailRoute: (context) => const RegisterDataPage(),
        subscriptionHistoryRoute: (_) => const SubscriptionHistoryPage(),
        accountSettingsRoute:    (_) => const AccountSettingsPage(),
        packageDetailRoute      : (ctx) => PriceDetailPage(
          package: ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>
        ),
        subscriptionRequestRoute: (ctx) => SubscriptionRequestPage(
          packageId: ModalRoute.of(ctx)!.settings.arguments as int
        ),
        complaintFormRoute: (context) => const ComplaintFormPage(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // User has a valid session
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}
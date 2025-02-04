import 'package:flutter/material.dart';
import 'package:isp_provider/const/keys.dart';
import 'package:isp_provider/const/urls.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Countries',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final storage = SupabaseClient(url, anonKey).storage;
  final _future = Supabase.instance.client
      .from('Users')
      .insert(
        [
          {
            "name" : "name 1",
            "phone" : 123456,
            "email" : "email 1",
            "address" : "address 1",
          },
          {
            "name" : "name 2",
            "phone" : 234567,
            "email" : "email 2",
            "address" : "address 2",
          },
          {
            "name" : "name 3",
            "phone" : 345678,
            "email" : "email 3",
            "address" : "address 3",
          },
        ]
      );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          return TextButton(onPressed: () {
          }, child: Text("Click to upload"));
        },
      ),
    );
  }
}
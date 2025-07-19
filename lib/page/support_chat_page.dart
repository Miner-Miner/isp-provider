// lib/page/support_chat_user.dart

import 'dart:async';
import 'dart:developer';
import 'dart:ffi';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportChatUserPage extends StatefulWidget {
  const SupportChatUserPage({super.key});

  @override
  State<SupportChatUserPage> createState() => _SupportChatUserPageState();
}

class _SupportChatUserPageState extends State<SupportChatUserPage> {
  final _supabase = Supabase.instance.client;
  String? _profileId;    // your own public.user.id
  List<Map<String, dynamic>> _chat = [];
  final _ctrl = TextEditingController();
  String _message = "Waiting...";
  DateTime lastChatTime = DateTime.now();
  bool _loading = true;
  Isolate? _isolate;
  ReceivePort? _receivePort;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _initUserChat();
    _startIsolate();
  }

  Future<void> _initUserChat() async {
    // 1) find your profile row
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final prof = await _supabase
        .from('user')
        .select('id')
        .eq('email', user.email!)
        .maybeSingle();
    if (prof == null) {
      setState(() => _loading = false);
      return;
    }
    _profileId = prof['id'] as String;

    // 2) load or create chat
    final row = await _supabase
      .from('support_chat')
      .select('chat, update_timestamp')
      .eq('user', _profileId.toString())
      .maybeSingle();
    if (row == null) {
      await _supabase
        .from('support_chat')
        .insert({'user': _profileId})
        .select('update_timestamp')
        .maybeSingle();
      _chat = [];
    } else {
      _chat = (row['chat'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    }

    setState(() => _loading = false);
    _scrollToBottom();
    _startIsolate();
  }

  void _startIsolate() async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_heavyWork, _receivePort!.sendPort);

    _receivePort!.listen((data) {
      setState(() {
        _message = data;
        if(_message.toString().toLowerCase() == "done"){
          _pollNew();
        }
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pollNew() async {
    if (_chat.isEmpty) {
      lastChatTime = DateTime.now();
      final row = await _supabase
      .from('support_chat')
      .select('chat')
      .eq('user', _profileId.toString())
      .maybeSingle();
      if (row == null) {
        await _supabase
          .from('support_chat')
          .insert({'user': _profileId})
          .select('update_timestamp')
          .maybeSingle();
        _chat = [];
      } else {
        _chat = (row['chat'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      }
    } else {
      final last = _chat.last['send_time'] as String;
      // Format is "YYYY/MM/DD HH:mm:ss"
      final parts = last.split(' ');
      final dateParts = parts[0].split('/');
      final timeParts = parts[1].split(':');
      lastChatTime = DateTime.utc(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    }

    // 2) Fetch the full chat[] from Supabase
    final row = await _supabase
        .from('support_chat')
        .select('chat')
        .eq('user', _profileId.toString())
        .maybeSingle();

    if (row == null) return;

    final raw = (row['chat'] as List<dynamic>).cast<Map<String, dynamic>>();

    // 3) Filter to only entries with send_time > lastChatTime
    final newMessages = raw.where((m) {
      final send = m['send_time'] as String;
      final parts = send.split(' ');
      final d = parts[0].split('/');
      final t = parts[1].split(':');
      final msgTime = DateTime.utc(
        int.parse(d[0]),
        int.parse(d[1]),
        int.parse(d[2]),
        int.parse(t[0]),
        int.parse(t[1]),
        int.parse(t[2]),
      );
      return msgTime.isAfter(lastChatTime);
    });

    // 4) Append and rebuild
    if (newMessages.isNotEmpty) {
      setState(() {
        _chat.addAll(newMessages);
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendUser() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _profileId == null) return;

    final now = DateTime.now().toUtc();
    final sendTime = 
      '${now.year}/${now.month.toString().padLeft(2, '0')}/'
      '${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}';

    final entry = {
      'sender': 'user',
      'message': text,
      'send_time': sendTime,
    };
    _chat.add(entry);

    await _supabase
      .from('support_chat')
      .update({'chat': _chat})
      .eq('user', _profileId.toString())
      .select('update_timestamp')
      .maybeSingle();

    _ctrl.clear();
    setState(() {});
    _scrollToBottom(); 
  }

  static void _heavyWork(SendPort sendPort) {
    int count = 0;
    Timer.periodic(Duration(seconds: 1), (timer) {
      count++;
      sendPort.send("Tick from isolate: $count");
      if (count >= 5) {
        sendPort.send("Done");
        count=0;
      }
    });
  }

  void _stopIsolate() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    setState(() {
      _message = "Stopped";
    });
  }

  @override
  void dispose() {
    _stopIsolate();
    _scrollCtrl.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Support Chat')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_profileId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Support Chat')),
        body: const Center(child: Text('No profile found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Support Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(8),
              itemCount: _chat.length,
              itemBuilder: (_, i) {
                final m = _chat[i];
                final isUser = m['sender'] == 'user';
                final align = isUser ? Alignment.centerLeft : Alignment.centerRight;
                final bg = isUser ? Colors.grey[300] : Colors.blueAccent.withOpacity(0.8);
                final tc = isUser ? Colors.black87 : Colors.white;
                return Align(
                  alignment: align,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(m['message'] as String, style: TextStyle(color: tc)),
                        const SizedBox(height: 4),
                        Text(m['send_time'] as String,
                            style: TextStyle(fontSize: 10, color: tc.withOpacity(0.7))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Type a message'))),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendUser),
              ],
            ),
          ),
        ],
      ),
    );
  }

}


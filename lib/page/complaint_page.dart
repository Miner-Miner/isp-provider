import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintFormPage extends StatefulWidget {
  const ComplaintFormPage({super.key});

  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final _title = TextEditingController();
  final _detail = TextEditingController();
  String _selectedType = 'Technical';
  bool _sending = false;
  String? _error;

  final List<String> _types = ['Connection Error', 'Billing Error', 'Red Light Alert', 'Service Request', 'Other'];

  Future<void> _submitComplaint() async {
    final title = _title.text.trim();
    final detail = _detail.text.trim();
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (title.isEmpty || detail.isEmpty || userId == null) {
      setState(() => _error = 'Please fill all fields.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.from('complaint').insert({
        'user_id': userId,
        'title': title,
        'type': _selectedType,
        'detail': detail,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to submit complaint: $e';
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit a Complaint')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Complaint Title'),
            ),
            const SizedBox(height: 12),
            const Text('Complaint Type:'),
            Column(
              children: _types.map((type) {
                return RadioListTile(
                  title: Text(type),
                  value: type,
                  groupValue: _selectedType,
                  onChanged: (val) {
                    setState(() {
                      _selectedType = val!;
                    });
                  },
                );
              }).toList(),
            ),
            TextField(
              controller: _detail,
              decoration:
                  const InputDecoration(labelText: 'Complaint Details'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _submitComplaint,
                child: _sending
                    ? const CircularProgressIndicator()
                    : const Text('Submit Complaint'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

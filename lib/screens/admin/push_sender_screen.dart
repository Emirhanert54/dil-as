import 'package:flutter/material.dart';

import '../../services/push_request_service.dart';

class PushSenderScreen extends StatefulWidget {
  const PushSenderScreen({super.key});

  @override
  State<PushSenderScreen> createState() => _PushSenderScreenState();
}

class _PushSenderScreenState extends State<PushSenderScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başlık ve mesaj boş olamaz.'),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await PushRequestService.sendAdminBroadcast(
        title: title,
        body: body,
      );

      if (!mounted) return;

      _titleController.clear();
      _bodyController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim gönderme isteği oluşturuldu.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const gradient = [
      Color(0xFF6C63FF),
      Color(0xFF8E2DE2),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bildirim Gönder',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF0F2F5),
              Color(0xFFEDEBFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Text(
                        '📢',
                        style: TextStyle(fontSize: 28),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Buradan tüm kullanıcılara genel bildirim gönderebilirsin.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Bildirim başlığı',
                  hintText: 'Örn: DİL-AS seni bekliyor!',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _bodyController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Mesaj',
                  hintText: 'Örn: Bugün kısa bir etkinlik yapıp yıldız kazanabilirsin.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _send,
                  icon: _loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.notifications_active_rounded),
                  label: Text(
                    _loading ? 'Gönderiliyor...' : 'Tüm Kullanıcılara Gönder',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gradient.first,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
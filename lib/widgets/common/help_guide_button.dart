import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';

class HelpGuidePageData {
  final String emoji;
  final String title;
  final String description;

  const HelpGuidePageData({
    required this.emoji,
    required this.title,
    required this.description,
  });
}

class HelpGuideButton extends StatelessWidget {
  final String guideTitle;
  final List<HelpGuidePageData> pages;
  final List<Color>? fixedGradient;

  const HelpGuideButton({
    super.key,
    required this.guideTitle,
    required this.pages,
    this.fixedGradient,
  });

  factory HelpGuideButton.student() {
    return const HelpGuideButton(
      guideTitle: 'Öğrenci Rehberi',
      pages: [
        HelpGuidePageData(
          emoji: '🎮',
          title: 'Etkinlikleri Oyna',
          description:
          'Tüm Etkinliklere Git butonuna basarak oyunları açabilirsin. Her bölümde soruları çözerek ilerlersin.',
        ),
        HelpGuidePageData(
          emoji: '⭐',
          title: 'Yıldız Kazan',
          description:
          'Etkinlikleri tamamladıkça yıldız kazanırsın. Günlük görevleri yaparsan ekstra yıldız alabilirsin.',
        ),
        HelpGuidePageData(
          emoji: '🚀',
          title: 'Sticker Topla',
          description:
          'Kazandığın yıldızlarla mağazadan sticker alabilir ve profilinde aktif sticker seçebilirsin.',
        ),
        HelpGuidePageData(
          emoji: '📩',
          title: 'Ödev ve Mesajları Takip Et',
          description:
          'Bekleyen ödevlerini ve öğretmeninden gelen mesajları ana ekrandaki karttan görebilirsin.',
        ),
      ],
    );
  }

  factory HelpGuideButton.teacher() {
    return const HelpGuideButton(
      guideTitle: 'Öğretmen Rehberi',
      fixedGradient: [
        Color(0xFF172033),
        Color(0xFF4454D6),
      ],
      pages: [
        HelpGuidePageData(
          emoji: '🏫',
          title: 'Sınıfını Yönet',
          description:
          'Sınıf bölümünden öğrencilerini takip edebilir ve sınıf listeni düzenleyebilirsin.',
        ),
        HelpGuidePageData(
          emoji: '📝',
          title: 'Ödev Gönder',
          description:
          'Ödevler bölümünden öğrencilere etkinlik atayabilir, tamamlanma durumlarını takip edebilirsin.',
        ),
        HelpGuidePageData(
          emoji: '📢',
          title: 'Mesaj Gönder',
          description:
          'Mesajlar bölümünden tüm sınıfa ya da seçtiğin öğrencilere duyuru ve tebrik mesajı gönderebilirsin.',
        ),
        HelpGuidePageData(
          emoji: '📊',
          title: 'Gelişimi İncele',
          description:
          'Raporlardan öğrencilerin tamamladığı etkinlikleri ve gelişim durumlarını görebilirsin.',
        ),
      ],
    );
  }

  factory HelpGuideButton.parent() {
    return const HelpGuideButton(
      guideTitle: 'Ebeveyn Rehberi',
      fixedGradient: [
        Color(0xFF172033),
        Color(0xFF3F51B5),
      ],
      pages: [
        HelpGuidePageData(
          emoji: '👨‍👩‍👧',
          title: 'Çocuğunu Takip Et',
          description:
          'Ana ekranda çocuğunun yıldızlarını, görevlerini ve ilerlemesini görebilirsin.',
        ),
        HelpGuidePageData(
          emoji: '📈',
          title: 'Gelişim Raporu',
          description:
          'Gelişim raporundan çocuğunun hangi etkinlikleri tamamladığını takip edebilirsin.',
        ),
        HelpGuidePageData(
          emoji: '🎯',
          title: 'Günlük İlerleme',
          description:
          'Günlük görevler ve tamamlanan etkinlikler sayesinde çocuğunun düzenli çalışmasını izleyebilirsin.',
        ),
        HelpGuidePageData(
          emoji: '💬',
          title: 'Bilgilendirmeleri Kontrol Et',
          description:
          'Öğretmen mesajlarını ve uygulama bildirimlerini takip ederek gelişmelerden haberdar olabilirsin.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Yardım',
      icon: const Icon(
        Icons.help_outline_rounded,
        color: Colors.white,
      ),
      onPressed: () {
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.45),
          builder: (_) => _HelpGuideDialog(
            guideTitle: guideTitle,
            pages: pages,
            fixedGradient: fixedGradient,
          ),
        );
      },
    );
  }
}

class _HelpGuideDialog extends StatefulWidget {
  final String guideTitle;
  final List<HelpGuidePageData> pages;
  final List<Color>? fixedGradient;

  const _HelpGuideDialog({
    required this.guideTitle,
    required this.pages,
    this.fixedGradient,
  });

  @override
  State<_HelpGuideDialog> createState() => _HelpGuideDialogState();
}

class _HelpGuideDialogState extends State<_HelpGuideDialog> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == widget.pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      Navigator.pop(context);
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_index == 0) return;

    _controller.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final gradient = widget.fixedGradient ?? provider.currentTheme.gradient;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 430,
          maxHeight: 560,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.30),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.guideTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.pages.length,
                  onPageChanged: (value) {
                    setState(() {
                      _index = value;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = widget.pages[index];

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  gradient.first.withOpacity(0.18),
                                  gradient.last.withOpacity(0.18),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                page.emoji,
                                style: const TextStyle(fontSize: 46),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: gradient.first,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.pages.length,
                        (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? gradient.first
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _index == 0 ? null : _back,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: gradient.first,
                          side: BorderSide(
                            color: gradient.first.withOpacity(0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text(
                          'GERİ',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gradient.first,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(
                          _isLast ? 'BAŞLA' : 'İLERİ',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
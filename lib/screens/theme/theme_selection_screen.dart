import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../repositories/theme_repository.dart';
import '../../widgets/common/themed_background.dart';
// 👈 PREMİUM EKRAN İMPORTU (Bunu eklemeyi unutma!)
import '../../widgets/common/premium_upgrade_dialog.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currentTheme = provider.currentTheme;
    final themes = ThemeRepository.themes;
    final isPremium = provider.isPremium; // 👈 Premium kontrolünü buraya çektik

    return Scaffold(
      backgroundColor: currentTheme.background,
      appBar: AppBar(
        title: const Text(
          "TEMA SEÇİMİ",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            fontSize: 17,
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: currentTheme.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ThemedBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
          children: [
            _ThemeHeaderCard(
              mascotEmoji: provider.currentMascot.emoji,
              themeTitle: currentTheme.title,
              gradient: currentTheme.gradient,
            ),

            const SizedBox(height: 16),

            ...themes.map((theme) {
              final selected = provider.activeThemeId == theme.id;

              // 👈 KİLİT MANTIĞI: Sadece "Uzay Teması" ücretsiz, gerisi kilitli!
              final isLocked = !isPremium && theme.title != 'Uzay Teması';

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ThemeCard(
                  emoji: theme.emoji,
                  title: theme.title,
                  description: theme.description,
                  gradient: theme.gradient,
                  selected: selected,
                  isLocked: isLocked, // 👈 Kilit durumunu karta yolluyoruz
                  onTap: () async {
                    // Eğer kilitliyse temayı değiştirme, satın alma ekranını fırlat!
                    if (isLocked) {
                      showDialog(
                        context: context,
                        builder: (context) => const PremiumUpgradeDialog(),
                      );
                      return; // Alt satırlara inip temayı değiştirmesini engelliyoruz
                    }

                    // Kilitli değilse (veya premiumsa) normal tema değiştirme işlemi
                    final messenger = ScaffoldMessenger.of(context);
                    final appProvider = context.read<AppProvider>();

                    messenger.clearSnackBars();

                    await appProvider.setActiveTheme(theme);

                    if (!context.mounted) return;

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text("${theme.title} seçildi!"),
                        backgroundColor: theme.gradient.first,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ThemeHeaderCard extends StatelessWidget {
  final String mascotEmoji;
  final String themeTitle;
  final List<Color> gradient;

  const _ThemeHeaderCard({
    required this.mascotEmoji,
    required this.themeTitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
        border: Border.all(
          color: gradient.first.withOpacity(0.16),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.40),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                mascotEmoji,
                style: const TextStyle(fontSize: 34),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Aktif Tema",
                  style: TextStyle(
                    color: gradient.first,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  themeTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Aşağıdan uygulamanın görünümünü değiştirebilirsin.",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final List<Color> gradient;
  final bool selected;
  final bool isLocked; // 👈 Karta kilit durumunu alıyoruz
  final VoidCallback onTap;

  const _ThemeCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.gradient,
    required this.selected,
    required this.isLocked, // 👈 Require ettik
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: selected ? 1.02 : 1.0,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: selected
                    ? Colors.white.withOpacity(0.95)
                    : Colors.white.withOpacity(0.24),
                width: selected ? 3 : 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(selected ? 0.30 : 0.18),
                  blurRadius: selected ? 18 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Opacity(
              opacity: isLocked ? 0.85 : 1.0, // 👈 Kilitliyse biraz mat görünsün
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -14,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Positioned(
                    right: 38,
                    top: -20,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.24),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.30),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.92),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 👈 SAĞ TARAFTAKİ İKON (Kilitliyse kilit ikonu, değilse seçim dairesi çıkar)
                      if (isLocked)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18), // Kilit ikonu arka planı
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        )
                      else
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : Colors.white.withOpacity(0.16),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.85),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            selected
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            color: selected ? gradient.first : Colors.white,
                            size: selected ? 24 : 20,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
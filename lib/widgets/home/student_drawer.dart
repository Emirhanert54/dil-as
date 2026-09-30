import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pages/login_page.dart';
import '../../providers/app_provider.dart';
import '../../repositories/reward_repository.dart';
import '../../screens/shop/sticker_album_screen.dart';
import '../../screens/shop/sticker_shop_screen.dart';
import '../../screens/student/student_workspace.dart';
import '../../screens/theme/theme_selection_screen.dart';
import '../../screens/student/child_onboarding_dialog.dart';
import '../../core/responsive.dart';
import '../common/premium_upgrade_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final theme = u.currentTheme;

    final themeStickers = RewardRepository.stickersForTheme(u.activeThemeId);
    final ownedThemeStickerCount =
        themeStickers.where((sticker) => u.ownsSticker(sticker.id)).length;
    final r = AppResponsive.of(context);

    final drawerWidth = r.responsiveValue(
      phonePortrait: 310,
      phoneLandscape: 300,
      tabletPortrait: 360,
      tabletLandscape: 340,
      largeTabletPortrait: 390,
      largeTabletLandscape: 360,
    );
    return SizedBox(
        width: drawerWidth,
        child: Drawer(
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.gradient.first.withOpacity(0.18),
                Colors.white,
                theme.gradient.last.withOpacity(0.12),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              _DrawerHeader(
                name: u.name,
                className: u.className,
                stars: u.stars,
                mascotEmoji: u.currentMascot.emoji,
                mascotTitle: u.currentMascot.title,
                themeTitle: theme.title,
                gradient: theme.gradient,
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                  children: [
                    _DrawerMenuItem(
                      icon: Icons.assignment_turned_in_rounded,
                      title: "Ödevlerim & Mesajlarım",
                      subtitle: "Ödevlerini ve mesajlarını gör",
                      gradient: [
                        theme.gradient.first,
                        theme.gradient.last,
                      ],
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentWorkSpace(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    _DrawerMenuItem(
                      icon: Icons.storefront_rounded,
                      title: "Yıldız Mağazası",
                      subtitle: "${u.stars} yıldızın var",
                      gradient: [
                        theme.gradient.first,
                        theme.gradient.last,
                      ],
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StickerShopScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    _DrawerMenuItem(
                      icon: Icons.collections_bookmark_rounded,
                      title: "Koleksiyon Albümüm",
                      subtitle:
                      "$ownedThemeStickerCount/${themeStickers.length} sticker toplandı",
                      gradient: [
                        theme.gradient.last,
                        theme.gradient.first,
                      ],
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StickerAlbumScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    _DrawerMenuItem(
                      icon: Icons.palette_rounded,
                      title: "Tema Seçimi",
                      subtitle: theme.title,
                      gradient: [
                        theme.gradient.first,
                        theme.gradient.last,
                      ],
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ThemeSelectionScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ParentTeacherControlButton(
                      gradient: theme.gradient,
                      onTap: () {
                        final rootNavigator = Navigator.of(
                          context,
                          rootNavigator: true,
                        );

                        Navigator.pop(context);

                        Future.delayed(
                          const Duration(milliseconds: 220),
                              () {
                            rootNavigator.push(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(
                                  showBackToStudent: true,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                    _PremiumUpgradeButton(gradient: theme.gradient),
                    const SizedBox(height: 12), // İki buton arasına boşluk

                    _ProfileActionsButton(
                      gradient: theme.gradient,
                      onTap: () {
                        final overlayContext =
                            Navigator.of(context, rootNavigator: true).overlay?.context ?? context;

                        Navigator.pop(context);

                        Future.delayed(
                          const Duration(milliseconds: 220),
                              () {
                            if (!overlayContext.mounted) return;
                            showChildProfileActionsSheet(overlayContext, theme.gradient);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
        ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final String name;
  final String className;
  final int stars;
  final String mascotEmoji;
  final String mascotTitle;
  final String themeTitle;
  final List<Color> gradient;

  const _DrawerHeader({
    required this.name,
    required this.className,
    required this.stars,
    required this.mascotEmoji,
    required this.mascotTitle,
    required this.themeTitle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.24),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.55),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    mascotEmoji,
                    style: const TextStyle(fontSize: 39),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? "Öğrenci" : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      className.isEmpty ? themeTitle : className,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _MiniInfoPill(
                icon: Icons.star_rounded,
                text: "$stars yıldız",
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniInfoPill(
                  icon: Icons.emoji_emotions_rounded,
                  text: mascotTitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfoPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 17,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradient.first.withOpacity(0.95),
                gradient.last.withOpacity(0.88),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.25),
                blurRadius: 13,
                offset: const Offset(0, 7),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.23),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentTeacherControlButton extends StatelessWidget {
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ParentTeacherControlButton({
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: gradient.first.withOpacity(0.20),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ebeveyn / Öğretmen Kontrolü",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Yetişkin hesabı ile giriş yap",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: gradient.first,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _PremiumUpgradeButton extends StatelessWidget {
  final List<Color> gradient;

  const _PremiumUpgradeButton({required this.gradient});

  @override
  Widget build(BuildContext context) {
    // 🚀 Gecikme olmadan doğrudan AppProvider'ın beyninden durumu çekiyoruz!
    final isPremium = context.watch<AppProvider>().isPremium;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isPremium
            ? () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bu hesap zaten Premium! Reklamlar kapalı."),
              backgroundColor: Colors.green,
            ),
          );
        }
            : () {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => const PremiumUpgradeDialog(),
          );
        },
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isPremium
                  ? Colors.green.shade400.withOpacity(0.60)
                  : Colors.amber.shade400.withOpacity(0.60),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: isPremium
                    ? Colors.green.withOpacity(0.15)
                    : Colors.amber.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPremium
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : const [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPremium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? "Premium Hesap" : "Reklamları Kaldır",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPremium ? "Reklamlar tamamen kaldırıldı" : "Premium'a geçiş yap",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPremium)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFFF8F00),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class _LogoutButton extends StatelessWidget {
  final Future<void> Function() onTap;

  const _LogoutButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF5252),
                Color(0xFFD32F2F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.22),
                blurRadius: 13,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Çıkış Yap",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
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
Future<void> showChildProfileActionsSheet(
    BuildContext context,
    List<Color> gradient,
    ) async {
  await showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _ChildProfileActionsSheet(
        rootContext: context,
        gradient: gradient,
      );
    },
  );
}

class _ProfileActionsButton extends StatelessWidget {
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ProfileActionsButton({
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.24),
                blurRadius: 13,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(
                Icons.manage_accounts_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Profil İşlemleri",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildProfileActionsSheet extends StatelessWidget {
  final BuildContext rootContext;
  final List<Color> gradient;

  const _ChildProfileActionsSheet({
    required this.rootContext,
    required this.gradient,
  });

  Future<void> _restoreProfile(BuildContext sheetContext) async {
    Navigator.pop(sheetContext);

    await Future.delayed(
      const Duration(milliseconds: 220),
    );

    if (!rootContext.mounted) return;

    final restored = await showRestoreProfileDialog(rootContext);

    if (restored != true) return;
    if (!rootContext.mounted) return;

    try {
      // 💣 Eski çocuğun premium hafızasını yok et!
      await rootContext.read<AppProvider>().forceResetPremium();

      await rootContext.read<AppProvider>().loadFromFirebase();
    } catch (_) {}

    if (!rootContext.mounted) return;

    ScaffoldMessenger.of(rootContext).showSnackBar(
      const SnackBar(
        content: Text("Profil geri yüklendi."),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _openAdultControl(BuildContext sheetContext) async {
    Navigator.pop(sheetContext);

    await Future.delayed(const Duration(milliseconds: 180));

    if (!rootContext.mounted) return;

    Navigator.push(
      rootContext,
      MaterialPageRoute(
        builder: (_) => const LoginPage(
          showBackToStudent: true,
        ),
      ),
    );
  }

  Future<void> _resetDeviceProfile(BuildContext sheetContext) async {
    Navigator.pop(sheetContext);

    await Future.delayed(
      const Duration(milliseconds: 220),
    );

    if (!rootContext.mounted) return;

    final confirm = await showDialog<bool>(
      context: rootContext,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Bu cihazdaki profili sıfırla?",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            "Bu işlem bu cihazdan mevcut çocuk profilini çıkarır. Eski profili geri getirmek için Oyuncu ID ve Kurtarma Kodu gerekir.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Vazgeç"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text("Sıfırla"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Çıkış yaparken cihazdaki Premium hafızasını sıfırla ki yeni giren bedavaya konmasın! 😂
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', false);
// 💣 Eski çocuğun premium hafızasını yok et!

    await FirebaseAuth.instance.signOut();

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7FF),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Profil İşlemleri",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Profilini geri yükleyebilir veya cihazdaki profili değiştirebilirsin.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(0.58),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            _SheetActionButton(
              icon: Icons.restore_rounded,
              title: "Eski Profilimi Geri Yükle",
              subtitle: "Oyuncu ID ve kurtarma kodu ile aç",
              gradient: gradient,
              onTap: () => _restoreProfile(context),
            ),
            const SizedBox(height: 10),
            _SheetActionButton(
              icon: Icons.admin_panel_settings_rounded,
              title: "Ebeveyn / Öğretmen Kontrolü",
              subtitle: "Yetişkin hesabı ile giriş yap",
              gradient: gradient,
              onTap: () => _openAdultControl(context),
            ),
            const SizedBox(height: 10),
            _SheetActionButton(
              icon: Icons.warning_amber_rounded,
              title: "Bu Cihazdaki Profili Sıfırla",
              subtitle: "Sadece kurtarma kodun varsa kullan",
              gradient: const [
                Color(0xFFFF5252),
                Color(0xFFD32F2F),
              ],
              onTap: () => _resetDeviceProfile(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _SheetActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: gradient.first.withOpacity(0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.2,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.8,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: gradient.first,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
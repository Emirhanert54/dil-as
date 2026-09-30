import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sticker_reward.dart';
import '../../providers/app_provider.dart';
import '../../repositories/reward_repository.dart';
import '../../widgets/common/themed_background.dart';

class StickerAlbumScreen extends StatelessWidget {
  const StickerAlbumScreen({super.key});

  bool _isTablet(BuildContext context) {
    return MediaQuery
        .of(context)
        .size
        .shortestSide >= 600;
  }

  bool _isLandscape(BuildContext context) {
    return MediaQuery
        .of(context)
        .orientation == Orientation.landscape;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = provider.currentTheme;

    final stickers = RewardRepository.stickersForTheme(provider.activeThemeId);
    final ownedStickers = stickers
        .where((sticker) => provider.ownsSticker(sticker.id))
        .toList();

    final lockedStickers = stickers
        .where((sticker) => !provider.ownsSticker(sticker.id))
        .toList();

    final totalCount = stickers.length;
    final ownedCount = ownedStickers.length;
    final progress = totalCount == 0 ? 0.0 : ownedCount / totalCount;

    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final compact = isTablet && isLandscape;

    // 📱 Telefon: 2, 📟 Tablet Dikey: 3, 🖥️ Tablet Yatay: 4 Sütun
    final crossAxisCount = compact ? 4 : (isTablet ? 3 : 2);

    final pagePadding = EdgeInsets.all(compact ? 16 : 18);
    final sectionGap = compact ? 14.0 : 20.0;
    final gridSpacing = compact ? 16.0 : 14.0;
    // Yükseklik dengelendi, yatayda sünmesi engellendi
    final cardHeight = compact ? 220.0 : (isTablet ? 230.0 : 252.0);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text(
          "Koleksiyon Albümüm",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: theme.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: ThemedBackground(
        child: ListView(
          padding: pagePadding,
          children: [
            _AlbumHeaderCard(
              themeTitle: theme.title,
              activeEmoji: provider.currentMascot.emoji,
              activeTitle: provider.currentMascot.title,
              ownedCount: ownedCount,
              totalCount: totalCount,
              progress: progress,
              gradient: theme.gradient,
              compact: compact,
            ),
            SizedBox(height: sectionGap),
            _SectionTitle(
              title: "Topladıklarım",
              subtitle: "Sahip olduğun stickerları buradan aktif yapabilirsin.",
              icon: Icons.check_circle_rounded,
              color: theme.gradient.first,
              compact: compact,
            ),
            SizedBox(height: compact ? 10 : 12),
            if (ownedStickers.isEmpty)
              _EmptyAlbumCard(
                gradient: theme.gradient,
                message: "Henüz sticker toplanmadı.",
                compact: compact,
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ownedStickers.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount, // Dinamik sütun sayısı
                  crossAxisSpacing: gridSpacing,
                  mainAxisSpacing: gridSpacing,
                  mainAxisExtent: cardHeight,
                ),
                itemBuilder: (context, index) {
                  final sticker = ownedStickers[index];
                  final isActive = provider.activeStickerId == sticker.id;

                  return _OwnedStickerCard(
                    sticker: sticker,
                    isActive: isActive,
                    gradient: theme.gradient,
                    compact: compact,
                    onSelect: isActive
                        ? null
                        : () async {
                      final success = await context
                          .read<AppProvider>()
                          .setActiveSticker(sticker);

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).clearSnackBars();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? "${sticker.title} aktif sticker oldu!"
                                : "Bu sticker seçilemedi.",
                          ),
                          backgroundColor: success
                              ? theme.gradient.first
                              : Colors.orange,
                        ),
                      );
                    },
                  );
                },
              ),
            SizedBox(height: compact ? 18 : 24),
            _SectionTitle(
              title: "Kilitli Stickerlar",
              subtitle: "Bu stickerlar mağazadan yıldız ile açılır.",
              icon: Icons.lock_rounded,
              color: Colors.grey.shade700,
              compact: compact,
            ),
            SizedBox(height: compact ? 10 : 12),
            if (lockedStickers.isEmpty)
              _CollectionCompletedCard(
                gradient: theme.gradient,
                compact: compact,
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lockedStickers.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount, // Dinamik sütun sayısı
                  crossAxisSpacing: gridSpacing,
                  mainAxisSpacing: gridSpacing,
                  mainAxisExtent: cardHeight,
                ),
                itemBuilder: (context, index) {
                  final sticker = lockedStickers[index];

                  return _LockedStickerCard(
                    sticker: sticker,
                    compact: compact,
                    gradient: theme
                        .gradient, // Tema rengini kilitli karta gönderdik
                  );
                },
              ),
            SizedBox(height: compact ? 18 : 24),
          ],
        ),
      ),
    );
  }
}
class _AlbumHeaderCard extends StatelessWidget {
  final String themeTitle;
  final String activeEmoji;
  final String activeTitle;
  final int ownedCount;
  final int totalCount;
  final double progress;
  final List<Color> gradient;
  final bool compact;

  const _AlbumHeaderCard({
    required this.themeTitle,
    required this.activeEmoji,
    required this.activeTitle,
    required this.ownedCount,
    required this.totalCount,
    required this.progress,
    required this.gradient,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: compact ? 54 : 62,
                height: compact ? 54 : 62,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.24),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    activeEmoji,
                    style: TextStyle(fontSize: compact ? 30 : 34),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$themeTitle Koleksiyonu",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 16 : 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$ownedCount/$totalCount sticker toplandı",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: compact ? 11.5 : 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Aktif maskot: $activeTitle",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: compact ? 10.5 : 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 11 : 12,
                  vertical: compact ? 7 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.24),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  "%$percent",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 15 : 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 13 : 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: compact ? 8 : 10,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool compact;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 38 : 42,
          height: compact ? 38 : 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: compact ? 22 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: compact ? 11 : 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnedStickerCard extends StatelessWidget {
  final StickerReward sticker;
  final bool isActive;
  final List<Color> gradient;
  final bool compact;
  final Future<void> Function()? onSelect;

  const _OwnedStickerCard({
    required this.sticker,
    required this.isActive,
    required this.gradient,
    required this.compact,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 13 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [gradient.first.withOpacity(0.35), gradient.last.withOpacity(0.35)]
              : [gradient.first.withOpacity(0.20), gradient.last.withOpacity(0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(isActive ? 0.25 : 0.1),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isActive ? Colors.white : gradient.first.withOpacity(0.5),
          width: isActive ? 2.5 : 1.5,
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: compact ? 28 : 30,
              height: compact ? 28 : 30,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.star_rounded : Icons.check_rounded,
                color: isActive ? gradient.first : Colors.white,
                size: compact ? 17 : 18,
              ),
            ),
          ),
          const Spacer(),
          Container(
            width: compact ? 62 : 70,
            height: compact ? 62 : 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                sticker.emoji,
                style: TextStyle(fontSize: compact ? 37 : 42),
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            sticker.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, // BEYAZ YAPILDI
              fontWeight: FontWeight.w900,
              fontSize: compact ? 12.5 : 13,
            ),
          ),
          SizedBox(height: compact ? 4 : 5),
          Text(
            sticker.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85), // BEYAZ YAPILDI
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 10.5,
              height: 1.18,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: compact ? 35 : 36,
            child: ElevatedButton.icon(
              onPressed: onSelect,
              icon: Icon(
                isActive
                    ? Icons.check_circle_rounded
                    : Icons.touch_app_rounded,
                size: 16,
              ),
              label: Text(isActive ? "AKTİF" : "Aktif Yap"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.white : gradient.first,
                foregroundColor: isActive ? gradient.first : Colors.white,
                disabledBackgroundColor: Colors.white.withOpacity(0.2),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 10.5 : 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedStickerCard extends StatelessWidget {
  final StickerReward sticker;
  final bool compact;
  final List<Color> gradient;

  const _LockedStickerCard({
    required this.sticker,
    required this.compact,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 13 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient.first.withOpacity(0.12),
            gradient.last.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: compact ? 28 : 30,
              height: compact ? 28 : 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                color: Colors.white.withOpacity(0.8),
                size: compact ? 16 : 17,
              ),
            ),
          ),
          const Spacer(),
          Opacity(
            opacity: 0.35,
            child: Text(
              sticker.emoji,
              style: TextStyle(fontSize: compact ? 42 : 48),
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            "Kilitli Sticker",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white, // BEYAZ YAPILDI
              fontWeight: FontWeight.w900,
              fontSize: compact ? 12.5 : 13,
            ),
          ),
          SizedBox(height: compact ? 5 : 6),
          Text(
            "${sticker.price} yıldız ile mağazadan açılır.",
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75), // BEYAZ YAPILDI
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : 10.5,
              height: 1.18,
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: compact ? 35 : 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  "KİLİTLİ",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9), // BEYAZ YAPILDI
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
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

class _CollectionCompletedCard extends StatelessWidget {
  final List<Color> gradient;
  final bool compact;

  const _CollectionCompletedCard({
    required this.gradient,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.24),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "🏆",
            style: TextStyle(fontSize: compact ? 40 : 46),
          ),
          const SizedBox(height: 10),
          Text(
            "Koleksiyon Tamamlandı!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 16 : 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Bu temadaki tüm stickerları topladın.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlbumCard extends StatelessWidget {
  final List<Color> gradient;
  final String message;
  final bool compact;

  const _EmptyAlbumCard({
    required this.gradient,
    required this.message,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: gradient.first.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            "📖",
            style: TextStyle(fontSize: compact ? 36 : 42),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 13 : 14,
            ),
          ),
        ],
      ),
    );
  }
}


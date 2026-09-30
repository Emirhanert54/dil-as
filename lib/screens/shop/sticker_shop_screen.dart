import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sticker_reward.dart';
import '../../providers/app_provider.dart';
import '../../repositories/reward_repository.dart';
import '../../widgets/common/themed_background.dart';
import '../../widgets/banner_ad_widget.dart'; // Klasör derinliğine göre '../' sayısını ayarlarsın

class StickerShopScreen extends StatelessWidget {
  const StickerShopScreen({super.key});

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

    final isTablet = _isTablet(context);
    final isLandscape = _isLandscape(context);
    final compact = isTablet && isLandscape;

    // 📱 Telefon: 2, 📟 Tablet Dikey: 3, 🖥️ Tablet Yatay: 4 Sütun
    final crossAxisCount = compact ? 4 : (isTablet ? 3 : 2);

    final horizontalPadding = isTablet ? 18.0 : 18.0;
    final headerMargin = EdgeInsets.fromLTRB(
      horizontalPadding,
      compact ? 14 : 18,
      horizontalPadding,
      compact ? 12 : 18,
    );

    final gridSpacing = compact ? 16.0 : 14.0;
    // Yatayda sünmesini engelledik, dikine alanı kullanmasını sağladık
    final cardHeight = compact ? 215.0 : (isTablet ? 230.0 : 230.0);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text(
          "Yıldız Mağazası",
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
        child: Column(
          children: [
            _ShopHeaderCard(
              stars: provider.stars,
              themeTitle: theme.title,
              gradient: theme.gradient,
              margin: headerMargin,
              compact: compact,
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  18,
                ),
                itemCount: stickers.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount, // Dinamik sütun sayısı
                  crossAxisSpacing: gridSpacing,
                  mainAxisSpacing: gridSpacing,
                  mainAxisExtent: cardHeight,
                ),
                itemBuilder: (context, index) {
                  final sticker = stickers[index];
                  final owned = provider.ownsSticker(sticker.id);
                  final canBuy = provider.stars >= sticker.price;
                  final isActive = provider.activeStickerId == sticker.id;

                  return StickerShopCard(
                    sticker: sticker,
                    owned: owned,
                    canBuy: canBuy,
                    isActive: isActive,
                    compact: compact,
                    themeGradient: theme.gradient,
                    onBuy: owned
                        ? null
                        : () async {
                      final success = await context
                          .read<AppProvider>()
                          .buySticker(sticker);

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).clearSnackBars();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? "${sticker.title} satın alındı!"
                                : "Yıldızın yetersiz veya ödül zaten alınmış.",
                          ),
                          backgroundColor:
                          success ? theme.gradient.first : Colors.orange,
                        ),
                      );
                    },
                    onSelect: owned
                        ? () async {
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
                          backgroundColor:
                          success ? theme.gradient.first : Colors.orange,
                        ),
                      );
                    }
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: BannerReklamWidget(),
      ),
    );
  }
}
class _ShopHeaderCard extends StatelessWidget {
  final int stars;
  final String themeTitle;
  final List<Color> gradient;
  final EdgeInsets margin;
  final bool compact;

  const _ShopHeaderCard({
    required this.stars,
    required this.themeTitle,
    required this.gradient,
    required this.margin,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 50.0 : 58.0;
    final iconFont = compact ? 28.0 : 32.0;
    final padding = compact ? 14.0 : 18.0;

    return Container(
      width: double.infinity,
      margin: margin,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "⭐",
                style: TextStyle(fontSize: iconFont),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Topladığın Yıldızlar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 15 : 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$stars yıldızın var • $themeTitle",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11.5 : 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              "$stars",
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 22 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StickerShopCard extends StatelessWidget {
  final StickerReward sticker;
  final bool owned;
  final bool canBuy;
  final bool isActive;
  final bool compact;
  final List<Color> themeGradient;
  final Future<void> Function()? onBuy;
  final Future<void> Function()? onSelect;

  const StickerShopCard({
    super.key,
    required this.sticker,
    required this.owned,
    required this.canBuy,
    required this.isActive,
    required this.compact,
    required this.themeGradient,
    this.onBuy,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !owned && !canBuy;

    final iconCircleSize = compact ? 58.0 : 66.0;
    final emojiSize = compact ? 36.0 : 42.0;
    final titleSize = compact ? 13.0 : 13.5;
    final descSize = compact ? 10.0 : 10.5;
    final buttonHeight = compact ? 36.0 : 38.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: locked
              ? [themeGradient.first.withOpacity(0.15), themeGradient.last.withOpacity(0.05)]
              : isActive
              ? [themeGradient.first.withOpacity(0.35), themeGradient.last.withOpacity(0.35)]
              : [themeGradient.first.withOpacity(0.25), themeGradient.last.withOpacity(0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: locked
                ? Colors.black.withOpacity(0.05)
                : themeGradient.first.withOpacity(isActive ? 0.2 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: locked
              ? Colors.white.withOpacity(0.15)
              : isActive
              ? Colors.white
              : themeGradient.first.withOpacity(0.5),
          width: isActive ? 2.5 : 1.5,
        ),
      ),
      padding: EdgeInsets.all(compact ? 13 : 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: iconCircleSize,
                height: iconCircleSize,
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
              ),
              Opacity(
                opacity: locked ? 0.4 : 1.0,
                child: Text(
                  sticker.emoji,
                  style: TextStyle(
                    fontSize: emojiSize,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            sticker.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, // BEYAZ YAPILDI
              fontWeight: FontWeight.w900,
              fontSize: titleSize,
            ),
          ),
          SizedBox(height: compact ? 5 : 6),
          Text(
            sticker.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85), // BEYAZ YAPILDI
              fontSize: descSize,
              fontWeight: FontWeight.w700,
              height: 1.20,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: _buildButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    if (isActive) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_rounded, size: 17),
        label: const Text("AKTİF"),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.white.withOpacity(0.9),
          disabledForegroundColor: themeGradient.first,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    if (owned) {
      return ElevatedButton(
        onPressed: onSelect,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeGradient.first,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "Seç",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: canBuy ? onBuy : null,
      icon: const Icon(Icons.star_rounded, size: 17),
      label: Text("${sticker.price}"),
      style: ElevatedButton.styleFrom(
        backgroundColor: canBuy ? Colors.white : Colors.white.withOpacity(0.15),
        foregroundColor: themeGradient.first,
        disabledForegroundColor: Colors.white.withOpacity(0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}


class StickerReward {
  final String id;
  final String themeId;
  final String title;
  final String emoji;
  final String description;
  final int price;
  final bool isStarter;

  const StickerReward({
    required this.id,
    required this.themeId,
    required this.title,
    required this.emoji,
    required this.description,
    required this.price,
    this.isStarter = false,
  });
}
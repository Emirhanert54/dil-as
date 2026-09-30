import '../models/sticker_reward.dart';

class RewardRepository {
  static const StickerReward defaultMascot = StickerReward(
    id: "default_mascot",
    themeId: "default",
    title: "DİL-AS Arkadaş",
    emoji: "🐣",
    description: "Senin ilk öğrenme arkadaşın.",
    price: 0,
    isStarter: true,
  );

  static const List<StickerReward> stickers = [
    // 🚀 UZAY TEMASI
    StickerReward(
      id: "space_starter_roket",
      themeId: "space",
      title: "Başlangıç Roketi",
      emoji: "🚀",
      description: "Uzay temasının ücretsiz başlangıç stickerı.",
      price: 0,
      isStarter: true,
    ),
    StickerReward(
      id: "space_astronot",
      themeId: "space",
      title: "Minik Astronot",
      emoji: "🧑‍🚀",
      description: "Uzay görevlerinin kahramanı.",
      price: 5,
    ),
    StickerReward(
      id: "space_ay",
      themeId: "space",
      title: "Parlak Ay",
      emoji: "🌙",
      description: "Gece yolunu aydınlatır.",
      price: 10,
    ),
    StickerReward(
      id: "space_gezegen",
      themeId: "space",
      title: "Neşeli Gezegen",
      emoji: "🪐",
      description: "Galaksinin renkli gezegeni.",
      price: 20,
    ),
    StickerReward(
      id: "space_yildiz",
      themeId: "space",
      title: "Kayan Yıldız",
      emoji: "🌠",
      description: "Başarılarını parlatır.",
      price: 30,
    ),
    StickerReward(
      id: "space_uydu",
      themeId: "space",
      title: "Uzay Uydusu",
      emoji: "🛰️",
      description: "Bilgiyi uzaya taşır.",
      price: 40,
    ),
    StickerReward(
      id: "space_dunya",
      themeId: "space",
      title: "Mavi Dünya",
      emoji: "🌍",
      description: "Evrenin güzel gezegeni.",
      price: 50,
    ),
    StickerReward(
      id: "space_galaksi",
      themeId: "space",
      title: "Galaksi",
      emoji: "🌌",
      description: "Büyük başarıların galaksisi.",
      price: 60,
    ),

    // 🏎️ ARABA TEMASI
    StickerReward(
      id: "car_starter_araba",
      themeId: "car",
      title: "Başlangıç Arabası",
      emoji: "🚗",
      description: "Araba temasının ücretsiz başlangıç stickerı.",
      price: 0,
      isStarter: true,
    ),
    StickerReward(
      id: "car_yaris_arabasi",
      themeId: "car",
      title: "Yarış Arabası",
      emoji: "🏎️",
      description: "Hızlı ve dikkatli sürücü.",
      price: 5,
    ),
    StickerReward(
      id: "car_trafik_isigi",
      themeId: "car",
      title: "Trafik Işığı",
      emoji: "🚦",
      description: "Kuralları hatırlatır.",
      price: 10,
    ),
    StickerReward(
      id: "car_damali_bayrak",
      themeId: "car",
      title: "Damalı Bayrak",
      emoji: "🏁",
      description: "Yarışı başarıyla tamamladın.",
      price: 20,
    ),
    StickerReward(
      id: "car_direksiyon",
      themeId: "car",
      title: "Direksiyon",
      emoji: "🛞",
      description: "Kontrol sende.",
      price: 30,
    ),
    StickerReward(
      id: "car_taksi",
      themeId: "car",
      title: "Sarı Taksi",
      emoji: "🚕",
      description: "Şehir yollarında gezer.",
      price: 40,
    ),
    StickerReward(
      id: "car_otobus",
      themeId: "car",
      title: "Okul Otobüsü",
      emoji: "🚌",
      description: "Arkadaşlarını taşır.",
      price: 50,
    ),
    StickerReward(
      id: "car_yol_tabelasi",
      themeId: "car",
      title: "Yol Tabelası",
      emoji: "🛣️",
      description: "Doğru yolu gösterir.",
      price: 60,
    ),

    // 🌳 ORMAN TEMASI
    StickerReward(
      id: "forest_starter_aslan",
      themeId: "forest",
      title: "Başlangıç Aslanı",
      emoji: "🦁",
      description: "Orman temasının ücretsiz başlangıç stickerı.",
      price: 0,
      isStarter: true,
    ),
    StickerReward(
      id: "forest_maymun",
      themeId: "forest",
      title: "Sevimli Maymun",
      emoji: "🐵",
      description: "Ormanın eğlenceli dostu.",
      price: 5,
    ),
    StickerReward(
      id: "forest_agac",
      themeId: "forest",
      title: "Orman Ağacı",
      emoji: "🌳",
      description: "Doğanın güçlü sembolü.",
      price: 10,
    ),
    StickerReward(
      id: "forest_kelebek",
      themeId: "forest",
      title: "Renkli Kelebek",
      emoji: "🦋",
      description: "Ormanda neşeyle uçar.",
      price: 20,
    ),
    StickerReward(
      id: "forest_tilki",
      themeId: "forest",
      title: "Akıllı Tilki",
      emoji: "🦊",
      description: "Dikkatli düşünür.",
      price: 30,
    ),
    StickerReward(
      id: "forest_panda",
      themeId: "forest",
      title: "Tatlı Panda",
      emoji: "🐼",
      description: "Sakin ve sevimli dost.",
      price: 40,
    ),
    StickerReward(
      id: "forest_kus",
      themeId: "forest",
      title: "Minik Kuş",
      emoji: "🐦",
      description: "Öğrenirken cıvıldar.",
      price: 50,
    ),
    StickerReward(
      id: "forest_yaprak",
      themeId: "forest",
      title: "Yeşil Yaprak",
      emoji: "🍃",
      description: "Doğanın küçük ödülü.",
      price: 60,
    ),

    // 🌈 GÖKKUŞAĞI TEMASI
    StickerReward(
      id: "rainbow_starter_civciv",
      themeId: "rainbow",
      title: "Başlangıç Civcivi",
      emoji: "🐣",
      description: "Gökkuşağı temasının ücretsiz başlangıç stickerı.",
      price: 0,
      isStarter: true,
    ),
    StickerReward(
      id: "rainbow_gokkusagi",
      themeId: "rainbow",
      title: "Gökkuşağı",
      emoji: "🌈",
      description: "Renkli ve neşeli bir ödül.",
      price: 5,
    ),
    StickerReward(
      id: "rainbow_yildiz",
      themeId: "rainbow",
      title: "Sihirli Yıldız",
      emoji: "🌟",
      description: "Parlayan özel yıldız.",
      price: 10,
    ),
    StickerReward(
      id: "rainbow_kupa",
      themeId: "rainbow",
      title: "Altın Kupa",
      emoji: "🏆",
      description: "Harika başarıların kupası.",
      price: 20,
    ),
    StickerReward(
      id: "rainbow_bulut",
      themeId: "rainbow",
      title: "Pamuk Bulut",
      emoji: "☁️",
      description: "Yumuşacık bir ödül.",
      price: 30,
    ),
    StickerReward(
      id: "rainbow_kalp",
      themeId: "rainbow",
      title: "Neşeli Kalp",
      emoji: "💖",
      description: "Sevgi dolu bir başarı.",
      price: 40,
    ),
    StickerReward(
      id: "rainbow_balon",
      themeId: "rainbow",
      title: "Renkli Balon",
      emoji: "🎈",
      description: "Kutlama zamanı.",
      price: 50,
    ),
    StickerReward(
      id: "rainbow_konfeti",
      themeId: "rainbow",
      title: "Konfeti",
      emoji: "🎉",
      description: "Başarı kutlaması.",
      price: 60,
    ),
  ];

  static List<StickerReward> stickersForTheme(String themeId) {
    return stickers.where((sticker) => sticker.themeId == themeId).toList();
  }

  static StickerReward starterForTheme(String themeId) {
    return stickers.firstWhere(
          (sticker) => sticker.themeId == themeId && sticker.isStarter,
      orElse: () => defaultMascot,
    );
  }

  static StickerReward? findById(String id) {
    try {
      return stickers.firstWhere((sticker) => sticker.id == id);
    } catch (_) {
      if (defaultMascot.id == id) return defaultMascot;
      return null;
    }
  }
}
class GameRepository {
  static const int sessionQuestionCount = 10;

  static List<Map<String, dynamic>> prepareQuestions(
      List<Map<String, dynamic>> source,
      ) {
    return source.map((question) {
      final copy = Map<String, dynamic>.from(question);

      for (final key in ['opts', 'o', 'p', 'l']) {
        if (copy[key] is List) {
          final shuffled = List<dynamic>.from(copy[key]);
          shuffled.shuffle();
          copy[key] = shuffled;
        }
      }

      return copy;
    }).toList();
  }

  static List<Map<String, dynamic>> prepareRandomQuestions(
      List<Map<String, dynamic>> source, {
        int count = sessionQuestionCount,
      }) {
    final copied = source.map((e) => Map<String, dynamic>.from(e)).toList();

    copied.shuffle();

    final safeCount = count.clamp(0, copied.length).toInt();
    final selected = copied.take(safeCount).toList();

    return prepareQuestions(selected);
  }

  static List<Map<String, dynamic>> prepareQuestionsByIds(
      List<Map<String, dynamic>> source,
      List<String> questionIds,
      ) {
    final sourceById = <String, Map<String, dynamic>>{};

    for (final question in source) {
      final id = question['id']?.toString();

      if (id != null && id.trim().isNotEmpty) {
        sourceById[id] = Map<String, dynamic>.from(question);
      }
    }

    final selected = <Map<String, dynamic>>[];

    for (final id in questionIds) {
      final question = sourceById[id];

      if (question != null) {
        selected.add(Map<String, dynamic>.from(question));
      }
    }

    if (selected.isEmpty) {
      return prepareRandomQuestions(source);
    }

    return prepareQuestions(selected);
  }
  static List<String> questionIdsOf(List<Map<String, dynamic>> questions) {
    return questions
        .map((question) => question['id']?.toString() ?? '')
        .where((id) => id.trim().isNotEmpty)
        .toList();
  }

  static Map<String, dynamic>? findLevel({
    required String gameType,
    required String levelTitle,
  }) {
    final levels = getLevels(gameType);

    String clean(String value) {
      return value
          .toLowerCase()
          .replaceAll("ı", "i")
          .replaceAll("ğ", "g")
          .replaceAll("ü", "u")
          .replaceAll("ş", "s")
          .replaceAll("ö", "o")
          .replaceAll("ç", "c")
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    for (final level in levels) {
      final title = level['title']?.toString() ?? '';

      if (clean(title) == clean(levelTitle)) {
        return Map<String, dynamic>.from(level);
      }
    }

    return null;
  }

  static String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll("ı", "i")
        .replaceAll("ğ", "g")
        .replaceAll("ü", "u")
        .replaceAll("ş", "s")
        .replaceAll("ö", "o")
        .replaceAll("ç", "c")
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static Map<String, dynamic> _level({
    required String gameType,
    required String title,
    required String icon,
    required List<Map<String, dynamic>> questions,
  }) {
    final gameSlug = _slug(gameType);
    final levelSlug = _slug(title);

    final preparedQuestions = <Map<String, dynamic>>[];

    for (int i = 0; i < questions.length; i++) {
      preparedQuestions.add({
        'id': '${gameSlug}_${levelSlug}_${i + 1}',
        ...questions[i],
      });
    }

    return {
      'title': title,
      'icon': icon,
      'questions': preparedQuestions,
    };
  }

  static List<Map<String, dynamic>> getLevels(String gameType) {
    switch (gameType) {
      case 'Heceleme':
        return [
          _level(
            gameType: gameType,
            title: "Meyveler",
            icon: "🍎",
            questions: [
              {"w": "ELMA", "p": ["EL", "MA"], "e": "🍎"},
              {"w": "ARMUT", "p": ["AR", "MUT"], "e": "🍐"},
              {"w": "KİRAZ", "p": ["Kİ", "RAZ"], "e": "🍒"},
              {"w": "KARPUZ", "p": ["KAR", "PUZ"], "e": "🍉"},
              {"w": "ÇİLEK", "p": ["Çİ", "LEK"], "e": "🍓"},
              {"w": "MUZ", "p": ["MUZ"], "e": "🍌"},
              {"w": "KAVUN", "p": ["KA", "VUN"], "e": "🍈"},
              {"w": "ÜZÜM", "p": ["Ü", "ZÜM"], "e": "🍇"},
              {"w": "LİMON", "p": ["Lİ", "MON"], "e": "🍋"},
              {"w": "PORTAKAL", "p": ["POR", "TA", "KAL"], "e": "🍊"},
              {"w": "ANANAS", "p": ["A", "NA", "NAS"], "e": "🍍"},
              {"w": "ŞEFTALİ", "p": ["ŞEF", "TA", "Lİ"], "e": "🍑"},
              {"w": "DOMATES", "p": ["DO", "MA", "TES"], "e": "🍅"},
              {"w": "HİNDİSTANCEVİZİ", "p": ["HİN", "DİS", "TAN", "CE", "Vİ", "Zİ"], "e": "🥥"},
              {"w": "ZEYTİN", "p": ["ZEY", "TİN"], "e": "🫒"},
              {"w": "AVOKADO", "p": ["A", "VO", "KA", "DO"], "e": "🥑"},
              {"w": "MANGO", "p": ["MAN", "GO"], "e": "🥭"},
              {"w": "KİVİ", "p": ["Kİ", "Vİ"], "e": "🥝"},
              {"w": "NAR", "p": ["NAR"], "e": "🍎"},
              {"w": "İNCİR", "p": ["İN", "CİR"], "e": "🟣"},
            ],
          ),
          _level(
            gameType: gameType,
            title: "Hayvanlar",
            icon: "🐶",
            questions: [
              {"w": "KEDİ", "p": ["KE", "Dİ"], "e": "🐱"},
              {"w": "KÖPEK", "p": ["KÖ", "PEK"], "e": "🐶"},
              {"w": "BALIK", "p": ["BA", "LIK"], "e": "🐟"},
              {"w": "KUŞ", "p": ["KUŞ"], "e": "🐦"},
              {"w": "ASLAN", "p": ["AS", "LAN"], "e": "🦁"},
              {"w": "FİL", "p": ["FİL"], "e": "🐘"},
              {"w": "ZÜRAFA", "p": ["ZÜ", "RA", "FA"], "e": "🦒"},
              {"w": "TAVŞAN", "p": ["TAV", "ŞAN"], "e": "🐰"},
              {"w": "KAPLUMBAĞA", "p": ["KAP", "LUM", "BA", "ĞA"], "e": "🐢"},
              {"w": "MAYMUN", "p": ["MAY", "MUN"], "e": "🐵"},
              {"w": "AYI", "p": ["A", "YI"], "e": "🐻"},
              {"w": "PANDA", "p": ["PAN", "DA"], "e": "🐼"},
              {"w": "TİLKİ", "p": ["TİL", "Kİ"], "e": "🦊"},
              {"w": "KURT", "p": ["KURT"], "e": "🐺"},
              {"w": "KAPLAN", "p": ["KAP", "LAN"], "e": "🐯"},
              {"w": "İNEK", "p": ["İ", "NEK"], "e": "🐮"},
              {"w": "AT", "p": ["AT"], "e": "🐴"},
              {"w": "KOYUN", "p": ["KO", "YUN"], "e": "🐑"},
              {"w": "ARI", "p": ["A", "RI"], "e": "🐝"},
              {"w": "KELEBEK", "p": ["KE", "LE", "BEK"], "e": "🦋"},
            ],
          ),
          _level(
            gameType: gameType,
            title: "Taşıtlar",
            icon: "🚗",
            questions: [
              {"w": "ARABA", "p": ["A", "RA", "BA"], "e": "🚗"},
              {"w": "UÇAK", "p": ["U", "ÇAK"], "e": "✈️"},
              {"w": "GEMİ", "p": ["GE", "Mİ"], "e": "🚢"},
              {"w": "TREN", "p": ["TREN"], "e": "🚂"},
              {"w": "OTOBÜS", "p": ["O", "TO", "BÜS"], "e": "🚌"},
              {"w": "BİSİKLET", "p": ["Bİ", "SİK", "LET"], "e": "🚲"},
              {"w": "MOTOSİKLET", "p": ["MO", "TO", "SİK", "LET"], "e": "🏍️"},
              {"w": "KAMYON", "p": ["KAM", "YON"], "e": "🚚"},
              {"w": "TRAKTÖR", "p": ["TRAK", "TÖR"], "e": "🚜"},
              {"w": "TAKSİ", "p": ["TAK", "Sİ"], "e": "🚕"},
              {"w": "AMBULANS", "p": ["AM", "BU", "LANS"], "e": "🚑"},
              {"w": "İTFAİYE", "p": ["İT", "FA", "İ", "YE"], "e": "🚒"},
              {"w": "POLİS", "p": ["PO", "LİS"], "e": "🚓"},
              {"w": "METRO", "p": ["MET", "RO"], "e": "🚇"},
              {"w": "TRAMVAY", "p": ["TRAM", "VAY"], "e": "🚊"},
              {"w": "HELİKOPTER", "p": ["HE", "Lİ", "KOP", "TER"], "e": "🚁"},
              {"w": "ROKET", "p": ["RO", "KET"], "e": "🚀"},
              {"w": "SCOOTER", "p": ["SCOO", "TER"], "e": "🛴"},
              {"w": "KAYIK", "p": ["KA", "YIK"], "e": "🛶"},
              {"w": "VAPUR", "p": ["VA", "PUR"], "e": "⛴️"},
            ],
          ),
        ];

      case 'Tanıma':
        return [
          _level(
            gameType: gameType,
            title: "Renkler",
            icon: "🎨",
            questions: [
              {"e": "🔴", "w": "KIRMIZI", "opts": ["KIRMIZI", "MAVİ", "SARI"]},
              {"e": "🔵", "w": "MAVİ", "opts": ["MAVİ", "YEŞİL", "MOR"]},
              {"e": "🟢", "w": "YEŞİL", "opts": ["SİYAH", "YEŞİL", "PEMBE"]},
              {"e": "🟡", "w": "SARI", "opts": ["SARI", "KIRMIZI", "MAVİ"]},
              {"e": "⚫", "w": "SİYAH", "opts": ["SİYAH", "BEYAZ", "TURUNCU"]},
              {"e": "⚪", "w": "BEYAZ", "opts": ["BEYAZ", "SİYAH", "MOR"]},
              {"e": "🟣", "w": "MOR", "opts": ["MOR", "YEŞİL", "SARI"]},
              {"e": "🟠", "w": "TURUNCU", "opts": ["TURUNCU", "PEMBE", "MAVİ"]},
              {"e": "🟤", "w": "KAHVERENGİ", "opts": ["KAHVERENGİ", "SİYAH", "BEYAZ"]},
              {"e": "🌸", "w": "PEMBE", "opts": ["PEMBE", "MOR", "SARI"]},
              {"e": "🌫️", "w": "GRİ", "opts": ["GRİ", "BEYAZ", "YEŞİL"]},
              {"e": "🌊", "w": "MAVİ", "opts": ["MAVİ", "KIRMIZI", "SARI"]},
              {"e": "🍋", "w": "SARI", "opts": ["SARI", "MOR", "SİYAH"]},
              {"e": "🍓", "w": "KIRMIZI", "opts": ["KIRMIZI", "BEYAZ", "YEŞİL"]},
              {"e": "🥦", "w": "YEŞİL", "opts": ["YEŞİL", "MAVİ", "PEMBE"]},
              {"e": "🍊", "w": "TURUNCU", "opts": ["TURUNCU", "SARI", "MOR"]},
              {"e": "🍇", "w": "MOR", "opts": ["MOR", "KIRMIZI", "BEYAZ"]},
              {"e": "🖤", "w": "SİYAH", "opts": ["SİYAH", "PEMBE", "MAVİ"]},
              {"e": "🤍", "w": "BEYAZ", "opts": ["BEYAZ", "SARI", "YEŞİL"]},
              {"e": "🧸", "w": "KAHVERENGİ", "opts": ["KAHVERENGİ", "TURUNCU", "GRİ"]},
            ],
          ),
          _level(
            gameType: gameType,
            title: "Sayılar",
            icon: "🔢",
            questions: [
              {"e": "1️⃣", "w": "BİR", "opts": ["BİR", "İKİ", "ÜÇ"]},
              {"e": "2️⃣", "w": "İKİ", "opts": ["İKİ", "BİR", "DÖRT"]},
              {"e": "3️⃣", "w": "ÜÇ", "opts": ["BEŞ", "ÜÇ", "ALTI"]},
              {"e": "4️⃣", "w": "DÖRT", "opts": ["DÖRT", "İKİ", "SEKİZ"]},
              {"e": "5️⃣", "w": "BEŞ", "opts": ["BEŞ", "ON", "SIFIR"]},
              {"e": "6️⃣", "w": "ALTI", "opts": ["ALTI", "YEDİ", "ÜÇ"]},
              {"e": "7️⃣", "w": "YEDİ", "opts": ["YEDİ", "BEŞ", "DOKUZ"]},
              {"e": "8️⃣", "w": "SEKİZ", "opts": ["SEKİZ", "DÖRT", "ALTI"]},
              {"e": "9️⃣", "w": "DOKUZ", "opts": ["DOKUZ", "ON", "BİR"]},
              {"e": "0️⃣", "w": "SIFIR", "opts": ["SIFIR", "BİR", "İKİ"]},
              {"e": "🔟", "w": "ON", "opts": ["ON", "BEŞ", "YEDİ"]},
              {"e": "11", "w": "ON BİR", "opts": ["ON BİR", "ON", "BİR"]},
              {"e": "12", "w": "ON İKİ", "opts": ["ON İKİ", "İKİ", "ON ÜÇ"]},
              {"e": "13", "w": "ON ÜÇ", "opts": ["ON ÜÇ", "ÜÇ", "ON İKİ"]},
              {"e": "14", "w": "ON DÖRT", "opts": ["ON DÖRT", "DÖRT", "ON BEŞ"]},
              {"e": "15", "w": "ON BEŞ", "opts": ["ON BEŞ", "BEŞ", "ON ALTI"]},
              {"e": "16", "w": "ON ALTI", "opts": ["ON ALTI", "ALTI", "ON YEDİ"]},
              {"e": "17", "w": "ON YEDİ", "opts": ["ON YEDİ", "YEDİ", "ON SEKİZ"]},
              {"e": "18", "w": "ON SEKİZ", "opts": ["ON SEKİZ", "SEKİZ", "ON DOKUZ"]},
              {"e": "19", "w": "ON DOKUZ", "opts": ["ON DOKUZ", "DOKUZ", "YİRMİ"]},
            ],
          ),
          _level(
            gameType: gameType,
            title: "Şekiller",
            icon: "🔺",
            questions: [
              {"e": "⬛", "w": "KARE", "opts": ["KARE", "DAİRE", "ÜÇGEN"]},
              {"e": "🔴", "w": "DAİRE", "opts": ["DAİRE", "YILDIZ", "KARE"]},
              {"e": "🔺", "w": "ÜÇGEN", "opts": ["ÜÇGEN", "DİKDÖRTGEN", "DAİRE"]},
              {"e": "⭐", "w": "YILDIZ", "opts": ["YILDIZ", "KARE", "DAİRE"]},
              {"e": "▭", "w": "DİKDÖRTGEN", "opts": ["DİKDÖRTGEN", "ÜÇGEN", "YILDIZ"]},
              {"e": "💎", "w": "ELMAS", "opts": ["ELMAS", "KARE", "DAİRE"]},
              {"e": "❤️", "w": "KALP", "opts": ["KALP", "YILDIZ", "ÜÇGEN"]},
              {"e": "⬟", "w": "BEŞGEN", "opts": ["BEŞGEN", "KARE", "DAİRE"]},
              {"e": "⬢", "w": "ALTIGEN", "opts": ["ALTIGEN", "ÜÇGEN", "KALP"]},
              {"e": "🔻", "w": "TERS ÜÇGEN", "opts": ["TERS ÜÇGEN", "DAİRE", "KARE"]},
              {"e": "➕", "w": "ARTI", "opts": ["ARTI", "EKSİ", "YILDIZ"]},
              {"e": "➖", "w": "EKSİ", "opts": ["EKSİ", "ARTI", "KARE"]},
              {"e": "⭕", "w": "HALKA", "opts": ["HALKA", "DAİRE", "KALP"]},
              {"e": "🔶", "w": "BAKLAVA", "opts": ["BAKLAVA", "KARE", "ÜÇGEN"]},
              {"e": "🔷", "w": "MAVİ ELMAS", "opts": ["MAVİ ELMAS", "DAİRE", "YILDIZ"]},
              {"e": "◽", "w": "KÜÇÜK KARE", "opts": ["KÜÇÜK KARE", "DAİRE", "KALP"]},
              {"e": "◯", "w": "BOŞ DAİRE", "opts": ["BOŞ DAİRE", "KARE", "ÜÇGEN"]},
              {"e": "🔲", "w": "ÇERÇEVE", "opts": ["ÇERÇEVE", "YILDIZ", "DAİRE"]},
              {"e": "🔳", "w": "KARE ÇERÇEVE", "opts": ["KARE ÇERÇEVE", "KALP", "ARTI"]},
              {"e": "✴️", "w": "PARLAK YILDIZ", "opts": ["PARLAK YILDIZ", "DAİRE", "KARE"]},
            ],
          ),
        ];

      case 'Hız':
      case 'Hızlı Gör':
        return [
          _level(
            gameType: 'Hız',
            title: "Rakamlar",
            icon: "⚡",
            questions: [
              {"t": "0", "o": ["0", "6", "4"]},
              {"t": "1", "o": ["1", "7", "3"]},
              {"t": "2", "o": ["2", "5", "8"]},
              {"t": "3", "o": ["3", "8", "1"]},
              {"t": "4", "o": ["4", "9", "0"]},
              {"t": "5", "o": ["5", "2", "9"]},
              {"t": "6", "o": ["6", "0", "8"]},
              {"t": "7", "o": ["7", "1", "3"]},
              {"t": "8", "o": ["8", "6", "9"]},
              {"t": "9", "o": ["9", "6", "8"]},
              {"t": "10", "o": ["10", "11", "1"]},
              {"t": "11", "o": ["11", "10", "12"]},
              {"t": "12", "o": ["12", "2", "21"]},
              {"t": "13", "o": ["13", "31", "3"]},
              {"t": "14", "o": ["14", "41", "4"]},
              {"t": "15", "o": ["15", "51", "5"]},
              {"t": "16", "o": ["16", "61", "6"]},
              {"t": "17", "o": ["17", "71", "7"]},
              {"t": "18", "o": ["18", "81", "8"]},
              {"t": "19", "o": ["19", "91", "9"]},
            ],
          ),
          _level(
            gameType: 'Hız',
            title: "Harfler",
            icon: "🅰️",
            questions: [
              {"t": "A", "o": ["A", "B", "C"]},
              {"t": "B", "o": ["B", "D", "P"]},
              {"t": "C", "o": ["C", "Ç", "G"]},
              {"t": "Ç", "o": ["Ç", "C", "Ş"]},
              {"t": "D", "o": ["D", "B", "P"]},
              {"t": "E", "o": ["E", "F", "L"]},
              {"t": "F", "o": ["F", "E", "T"]},
              {"t": "G", "o": ["G", "C", "Ğ"]},
              {"t": "Ğ", "o": ["Ğ", "G", "Ü"]},
              {"t": "H", "o": ["H", "K", "N"]},
              {"t": "I", "o": ["I", "İ", "L"]},
              {"t": "İ", "o": ["İ", "I", "E"]},
              {"t": "K", "o": ["K", "R", "S"]},
              {"t": "L", "o": ["L", "I", "T"]},
              {"t": "M", "o": ["M", "N", "W"]},
              {"t": "O", "o": ["O", "Ö", "0"]},
              {"t": "Ö", "o": ["Ö", "O", "Ü"]},
              {"t": "S", "o": ["S", "Ş", "Z"]},
              {"t": "Ş", "o": ["Ş", "S", "Ç"]},
              {"t": "Z", "o": ["Z", "M", "K"]},
            ],
          ),
          _level(
            gameType: 'Hız',
            title: "Semboller",
            icon: "💠",
            questions: [
              {"t": "@", "o": ["@", "#", "&"]},
              {"t": "?", "o": ["?", "!", "+"]},
              {"t": "%", "o": ["%", "&", "@"]},
              {"t": "+", "o": ["+", "-", "="]},
              {"t": "-", "o": ["-", "+", "="]},
              {"t": "=", "o": ["=", "+", "-"]},
              {"t": "#", "o": ["#", "@", "%"]},
              {"t": "&", "o": ["&", "%", "@"]},
              {"t": "!", "o": ["!", "?", ":"]},
              {"t": "*", "o": ["*", "+", "x"]},
              {"t": "/", "o": ["/", "\\", "|"]},
              {"t": "|", "o": ["|", "/", "!"]},
              {"t": ":", "o": [":", ";", "."]},
              {"t": ";", "o": [";", ":", ","]},
              {"t": ".", "o": [".", ",", ":"]},
              {"t": ",", "o": [",", ".", ";"]},
              {"t": "₺", "o": ["₺", "\$", "€"]},
              {"t": "\$", "o": ["\$", "₺", "€"]},
              {"t": "€", "o": ["€", "\$", "₺"]},
              {"t": "✓", "o": ["✓", "x", "+"]},
            ],
          ),
        ];

      case 'Bellek':
        return [
          _level(
            gameType: gameType,
            title: "Doğa",
            icon: "🌳",
            questions: [
              {"n": "Ağaç", "s": "🌳"},
              {"n": "Güneş", "s": "☀️"},
              {"n": "Çiçek", "s": "🌸"},
              {"n": "Ay", "s": "🌙"},
              {"n": "Bulut", "s": "☁️"},
              {"n": "Yağmur", "s": "🌧️"},
              {"n": "Kar", "s": "❄️"},
              {"n": "Gökkuşağı", "s": "🌈"},
              {"n": "Deniz", "s": "🌊"},
              {"n": "Dağ", "s": "⛰️"},
              {"n": "Yaprak", "s": "🍃"},
              {"n": "Kaktüs", "s": "🌵"},
              {"n": "Mantar", "s": "🍄"},
              {"n": "Ateş", "s": "🔥"},
              {"n": "Yıldız", "s": "⭐"},
              {"n": "Dünya", "s": "🌍"},
              {"n": "Tohum", "s": "🌱"},
              {"n": "Gül", "s": "🌹"},
              {"n": "Palmiye", "s": "🌴"},
              {"n": "Rüzgar", "s": "🌬️"},
            ],
          ),
          _level(
            gameType: gameType,
            title: "Yiyecekler",
            icon: "🍔",
            questions: [
              {"n": "Elma", "s": "🍎"},
              {"n": "Ekmek", "s": "🍞"},
              {"n": "Süt", "s": "🥛"},
              {"n": "Peynir", "s": "🧀"},
              {"n": "Yumurta", "s": "🥚"},
              {"n": "Muz", "s": "🍌"},
              {"n": "Çilek", "s": "🍓"},
              {"n": "Karpuz", "s": "🍉"},
              {"n": "Limon", "s": "🍋"},
              {"n": "Havuç", "s": "🥕"},
              {"n": "Mısır", "s": "🌽"},
              {"n": "Patates", "s": "🥔"},
              {"n": "Domates", "s": "🍅"},
              {"n": "Pizza", "s": "🍕"},
              {"n": "Hamburger", "s": "🍔"},
              {"n": "Dondurma", "s": "🍦"},
              {"n": "Pasta", "s": "🎂"},
              {"n": "Bal", "s": "🍯"},
              {"n": "Çorba", "s": "🍲"},
              {"n": "Salata", "s": "🥗"},
            ],
          ),
          _level(
            gameType: gameType,
            title: "Eşyalar",
            icon: "🪑",
            questions: [
              {"n": "Sandalye", "s": "🪑"},
              {"n": "Yatak", "s": "🛏️"},
              {"n": "Kitap", "s": "📖"},
              {"n": "Kalem", "s": "✏️"},
              {"n": "Telefon", "s": "📱"},
              {"n": "Bilgisayar", "s": "💻"},
              {"n": "kol Saati", "s": "⌚"},
              {"n": "Çanta", "s": "🎒"},
              {"n": "Ampul", "s": "💡"},
              {"n": "Anahtar", "s": "🔑"},
              {"n": "Makas", "s": "✂️"},
              {"n": "Fırça", "s": "🖌️"},
              {"n": "Kutu", "s": "📦"},
              {"n": "Kilit", "s": "🔒"},
              {"n": "Televizyon", "s": "📺"},
              {"n": "Kulaklık", "s": "🎧"},
              {"n": "Kamera", "s": "📷"},
              {"n": "Mikrofon", "s": "🎤"},
              {"n": "Top", "s": "⚽"},
              {"n": "Oyuncak", "s": "🧸"},
            ],
          ),
        ];

      case 'Yazma':
        return [
          _level(
            gameType: gameType,
            title: "3 Harfliler",
            icon: "✍️",
            questions: [
              {"w": "TOP", "l": ["T", "O", "P", "A", "K"]},
              {"w": "MUZ", "l": ["M", "U", "Z", "E", "L"]},
              {"w": "KUŞ", "l": ["K", "U", "Ş", "B", "A"]},
              {"w": "KEK", "l": ["K", "E", "K", "S", "M"]},
              {"w": "GÖZ", "l": ["G", "Ö", "Z", "A", "T"]},
              {"w": "BAL", "l": ["B", "A", "L", "M", "O"]},
              {"w": "KOL", "l": ["K", "O", "L", "A", "T"]},
              {"w": "DİL", "l": ["D", "İ", "L", "E", "M"]},
              {"w": "KAŞ", "l": ["K", "A", "Ş", "S", "T"]},
              {"w": "DİŞ", "l": ["D", "İ", "Ş", "S", "K"]},
              {"w": "KAR", "l": ["K", "A", "R", "L", "M"]},
              {"w": "YOL", "l": ["Y", "O", "L", "A", "K"]},
              {"w": "GÜL", "l": ["G", "Ü", "L", "O", "A"]},
              {"w": "ÇAY", "l": ["Ç", "A", "Y", "T", "K"]},
              {"w": "KUM", "l": ["K", "U", "M", "A", "L"]},
              {"w": "MOR", "l": ["M", "O", "R", "A", "L"]},
              {"w": "ABİ", "l": ["B", "İ", "R", "A", "L"]},
              {"w": "KIŞ", "l": ["K", "O", "I", "Ş", "L"]},
              {"w": "CAM", "l": ["M", "C", "R", "A", "L"]},
              {"w": "ELA", "l": ["M", "E", "R", "A", "L"]},
            ],
          ),
          _level(
            gameType: gameType,
            title: "4 Harfliler",
            icon: "✏️",
            questions: [
              {"w": "KAPI", "l": ["K", "A", "P", "I", "L"]},
              {"w": "OKUL", "l": ["O", "K", "U", "L", "M"]},
              {"w": "MAVİ", "l": ["M", "A", "V", "İ", "S"]},
              {"w": "KEDİ", "l": ["K", "E", "D", "İ", "Z"]},
              {"w": "FARE", "l": ["F", "A", "R", "E", "K"]},
              {"w": "SARI", "l": ["S", "A", "R", "I", "K"]},
              {"w": "MASA", "l": ["M", "A", "S", "A", "K"]},
              {"w": "BABA", "l": ["B", "A", "B", "A", "K"]},
              {"w": "ANNE", "l": ["A", "N", "N", "E", "M"]},
              {"w": "DEDE", "l": ["D", "E", "D", "E", "A"]},
              {"w": "NENE", "l": ["N", "E", "N", "E", "K"]},
              {"w": "UÇAK", "l": ["U", "Ç", "A", "K", "L"]},
              {"w": "GEMİ", "l": ["G", "E", "M", "İ", "A"]},
              {"w": "TREN", "l": ["T", "R", "E", "N", "K"]},
              {"w": "OYUN", "l": ["O", "Y", "U", "N", "K"]},
              {"w": "PARK", "l": ["P", "A", "R", "K", "L"]},
              {"w": "KURT", "l": ["K", "U", "R", "T", "A"]},
              {"w": "KAZA", "l": ["K", "A", "Z", "A", "L"]},
              {"w": "YAZI", "l": ["Y", "A", "Z", "I", "K"]},
              {"w": "DADI", "l": ["Y", "A", "D", "I", "D"]},
            ],
          ),
          _level(
            gameType: gameType,
            title: "5 Harfliler",
            icon: "✒️",
            questions: [
              {"w": "ÇOCUK", "l": ["Ç", "O", "C", "U", "K", "A"]},
              {"w": "YEŞİL", "l": ["Y", "E", "Ş", "İ", "L", "A"]},
              {"w": "KİTAP", "l": ["K", "İ", "T", "A", "P", "Z"]},
              {"w": "SEVGİ", "l": ["S", "E", "V", "G", "İ", "R"]},
              {"w": "SİLGİ", "l": ["S", "İ", "L", "G", "İ", "M"]},
              {"w": "KALEM", "l": ["K", "A", "L", "E", "M", "Ş"]},
              {"w": "ÇANTA", "l": ["Ç", "A", "N", "T", "A", "K"]},
              {"w": "KÖPEK", "l": ["K", "Ö", "P", "E", "K", "A"]},
              {"w": "BALIK", "l": ["B", "A", "L", "I", "K", "M"]},
              {"w": "ÇİÇEK", "l": ["Ç", "İ", "Ç", "E", "K", "L"]},
              {"w": "GÜNEŞ", "l": ["G", "Ü", "N", "E", "Ş", "A"]},
              {"w": "BULUT", "l": ["B", "U", "L", "U", "T", "K"]},
              {"w": "KOYUN", "l": ["K", "O", "Y", "U", "N","K"]},
              {"w": "ARABA", "l": ["A", "R", "A", "B", "A", "K"]},
              {"w": "ASLAN", "l": ["A", "S", "L", "A", "N", "K"]},
              {"w": "MUTLU", "l": ["M", "U", "T", "L", "U", "A"]},
              {"w": "OKUMA", "l": ["O", "K", "U", "M", "A", "L"]},
              {"w": "TEYZE", "l": ["T", "Y", "E", "E", "A", "Z"]},
              {"w": "ÇİLEK", "l": ["İ", "K", "Ç", "E", "A", "L"]},
              {"w": "KAVUN", "l": ["O", "K", "V", "U", "A", "N"]},
            ],
          ),
        ];

      case 'Hikaye':
        return [
          _level(
            gameType: gameType,
            title: "Kısa Cümleler",
            icon: "📖",
            questions: [
              {"w": "ALİ EVE GELDİ", "p": ["ALİ", "EVE", "GELDİ"]},
              {"w": "AYŞE TOP OYNADI", "p": ["AYŞE", "TOP", "OYNADI"]},
              {"w": "O KİTAP OKUDU", "p": ["O", "KİTAP", "OKUDU"]},
              {"w": "KEDİ SÜT İÇTİ", "p": ["KEDİ", "SÜT", "İÇTİ"]},
              {"w": "BEN OKULA GİTTİM", "p": ["BEN", "OKULA", "GİTTİM"]},
              {"w": "KUŞ DALDA ÖTTÜ", "p": ["KUŞ", "DALDA", "ÖTTÜ"]},
              {"w": "BABAM EVE GELDİ", "p": ["BABAM", "EVE", "GELDİ"]},
              {"w": "ANNEM KEK YAPTI", "p": ["ANNEM", "KEK", "YAPTI"]},
              {"w": "ÇOCUK SU İÇTİ", "p": ["ÇOCUK", "SU", "İÇTİ"]},
              {"w": "KÖPEK KOŞTU", "p": ["KÖPEK", "KOŞTU"]},
              {"w": "BALIK YÜZDÜ", "p": ["BALIK", "YÜZDÜ"]},
              {"w": "GÜNEŞ DOĞDU", "p": ["GÜNEŞ", "DOĞDU"]},
              {"w": "YAĞMUR YAĞDI", "p": ["YAĞMUR", "YAĞDI"]},
              {"w": "KAR YAĞDI", "p": ["KAR", "YAĞDI"]},
              {"w": "TOP YUVARLANDI", "p": ["TOP", "YUVARLANDI"]},
              {"w": "ELMA DÜŞTÜ", "p": ["ELMA", "DÜŞTÜ"]},
              {"w": "ÇİÇEK AÇTI", "p": ["ÇİÇEK", "AÇTI"]},
              {"w": "TREN GELDİ", "p": ["TREN", "GELDİ"]},
              {"w": "UÇAK UÇTU", "p": ["UÇAK", "UÇTU"]},
              {"w": "BEBEK UYUDU", "p": ["BEBEK", "UYUDU"]},
            ],
          ),
          _level(
            gameType: gameType,
            title: "Orta Cümleler",
            icon: "📚",
            questions: [
              {"w": "BUGÜN HAVA ÇOK GÜZEL", "p": ["BUGÜN", "HAVA", "ÇOK", "GÜZEL"]},
              {"w": "KEDİ SÜTÜ ÇOK SEVER", "p": ["KEDİ", "SÜTÜ", "ÇOK", "SEVER"]},
              {"w": "ANNEM BANA KEK YAPTI", "p": ["ANNEM", "BANA", "KEK", "YAPTI"]},
              {"w": "ALİ PARKTA TOP OYNADI", "p": ["ALİ", "PARKTA", "TOP", "OYNADI"]},
              {"w": "AYŞE BUGÜN KİTAP OKUDU", "p": ["AYŞE", "BUGÜN", "KİTAP", "OKUDU"]},
              {"w": "KÖPEK BAHÇEDE HIZLI KOŞTU", "p": ["KÖPEK", "BAHÇEDE", "HIZLI", "KOŞTU"]},
              {"w": "KUŞ AĞAÇTA GÜZEL ÖTTÜ", "p": ["KUŞ", "AĞAÇTA", "GÜZEL", "ÖTTÜ"]},
              {"w": "BEN BUGÜN OKULA GİTTİM", "p": ["BEN", "BUGÜN", "OKULA", "GİTTİM"]},
              {"w": "ÖĞRETMENİM BİZE MASAL ANLATTI", "p": ["ÖĞRETMENİM", "BİZE", "MASAL", "ANLATTI"]},
              {"w": "ÇOCUKLAR BAHÇEDE OYUN OYNADI", "p": ["ÇOCUKLAR", "BAHÇEDE", "OYUN", "OYNADI"]},
              {"w": "BABAM BANA KALEM ALDI", "p": ["BABAM", "BANA", "KALEM", "ALDI"]},
              {"w": "KARDEŞİM BENİM TOPUMU ALDI", "p": ["KARDEŞİM", "BENİM", "TOPUMU", "ALDI"]},
              {"w": "SARI KEDİ MAMA YEDİ", "p": ["SARI", "KEDİ", "MAMA", "YEDİ"]},
              {"w": "KÜÇÜK KUŞ SU İÇTİ", "p": ["KÜÇÜK", "KUŞ", "SU", "İÇTİ"]},
              {"w": "MAVİ ARABA HIZLI GİTTİ", "p": ["MAVİ", "ARABA", "HIZLI", "GİTTİ"]},
              {"w": "KIRMIZI ELMA YERE DÜŞTÜ", "p": ["KIRMIZI", "ELMA", "YERE", "DÜŞTÜ"]},
              {"w": "ÇİÇEKLER BAHARDA GÜZEL AÇAR", "p": ["ÇİÇEKLER", "BAHARDA", "GÜZEL", "AÇAR"]},
              {"w": "YAĞMURDAN SONRA GÖKKUŞAĞI ÇIKTI", "p": ["YAĞMURDAN", "SONRA", "GÖKKUŞAĞI", "ÇIKTI"]},
              {"w": "AKŞAM OLUNCA AY ÇIKTI", "p": ["AKŞAM", "OLUNCA", "AY", "ÇIKTI"]},
              {"w": "SABAH GÜNEŞ PARLADI", "p": ["SABAH", "GÜNEŞ", "PARLADI"]},
            ],
          ),
          _level(
            gameType: gameType,
            title: "Uzun Cümleler",
            icon: "📜",
            questions: [
              {"w": "BABAM BANA KIRMIZI BİR BİSİKLET ALDI", "p": ["BABAM", "BANA", "KIRMIZI", "BİR", "BİSİKLET", "ALDI"]},
              {"w": "OKULDA ARKADAŞLARIMLA OYUN OYNADIM", "p": ["OKULDA", "ARKADAŞLARIMLA", "OYUN", "OYNADIM"]},
              {"w": "ANNEM AKŞAM YEMEĞİ İÇİN ÇORBA YAPTI", "p": ["ANNEM", "AKŞAM", "YEMEĞİ", "İÇİN", "ÇORBA", "YAPTI"]},
              {"w": "KÜÇÜK KEDİ BAHÇEDE TOPLA OYNADI", "p": ["KÜÇÜK", "KEDİ", "BAHÇEDE", "TOPLA", "OYNADI"]},
              {"w": "BUGÜN ÖĞRETMENİM BANA YENİ KİTAP VERDİ", "p": ["BUGÜN", "ÖĞRETMENİM", "BANA", "YENİ", "KİTAP", "VERDİ"]},
              {"w": "SARI KUŞ AĞACIN ÜSTÜNDE GÜZEL GÜZEL ÖTTÜ", "p": ["SARI", "KUŞ", "AĞACIN", "ÜSTÜNDE", "GÜZEL", "GÜZEL", "ÖTTÜ"]},
              {"w": "KAR YAĞINCA ÇOCUKLAR BAHÇEDE KARDAN ADAM YAPTI", "p": ["KAR", "YAĞINCA", "ÇOCUKLAR", "BAHÇEDE", "KARDAN", "ADAM", "YAPTI"]},
              {"w": "GÜNEŞ AÇINCA PARKTA UZUN SÜRE OYNADIK", "p": ["GÜNEŞ", "AÇINCA", "PARKTA", "UZUN", "SÜRE", "OYNADIK"]},
              {"w": "KIRMIZI ARABA YOLDA YAVAŞÇA İLERLEDİ", "p": ["KIRMIZI", "ARABA", "YOLDA", "YAVAŞÇA", "İLERLEDİ"]},
              {"w": "DENİZDE MAVİ BALIKLAR BİRLİKTE YÜZDÜ", "p": ["DENİZDE", "MAVİ", "BALIKLAR", "BİRLİKTE", "YÜZDÜ"]},
              {"w": "KARDEŞİM BUGÜN OKULDA RESİM YAPTI", "p": ["KARDEŞİM", "BUGÜN", "OKULDA", "RESİM", "YAPTI"]},
              {"w": "BEN SABAH ERKEN KALKIP KAHVALTI YAPTIM", "p": ["BEN", "SABAH", "ERKEN", "KALKIP", "KAHVALTI", "YAPTIM"]},
              {"w": "BAHÇEDEKİ ÇİÇEKLER RENK RENK AÇTI", "p": ["BAHÇEDEKİ", "ÇİÇEKLER", "RENK", "RENK", "AÇTI"]},
              {"w": "ARKADAŞIM BANA GÜZEL BİR HEDİYE VERDİ", "p": ["ARKADAŞIM", "BANA", "GÜZEL", "BİR", "HEDİYE", "VERDİ"]},
              {"w": "ÖĞRETMENİM BİZE YENİ BİR ŞARKI ÖĞRETTİ", "p": ["ÖĞRETMENİM", "BİZE", "YENİ", "BİR", "ŞARKI", "ÖĞRETTİ"]},
              {"w": "KÜTÜPHANEDE SESSİZCE KİTAP OKUDUM", "p": ["KÜTÜPHANEDE", "SESSİZCE", "KİTAP", "OKUDUM"]},
              {"w": "OYUNCAKLARIMI TOPLAYIP ODAMA KOYDUM", "p": ["OYUNCAKLARIMI", "TOPLAYIP", "ODAMA", "KOYDUM"]},
              {"w": "KÖPEĞİM BAHÇEDE MUTLU MUTLU KOŞTU", "p": ["KÖPEĞİM", "BAHÇEDE", "MUTLU", "MUTLU", "KOŞTU"]},
              {"w": "YAĞMUR BİTİNCE DIŞARI ÇIKIP YÜRÜDÜK", "p": ["YAĞMUR", "BİTİNCE", "DIŞARI", "ÇIKIP", "YÜRÜDÜK"]},
              {"w": "AKŞAM AİLEMLE BİRLİKTE MASAL DİNLEDİM", "p": ["AKŞAM", "AİLEMLE", "BİRLİKTE", "MASAL", "DİNLEDİM"]},
            ],
          ),
        ];

      case 'Sesler':
        return [
          _level(
            gameType: gameType,
            title: "Başlangıç Sesi",
            icon: "🔊",
            questions: [
              {"q": "E", "a": "ELMA", "o": ["ELMA", "ARMUT", "MUZ"]},
              {"q": "K", "a": "KALEM", "o": ["KALEM", "SİLGİ", "DEFTER"]},
              {"q": "A", "a": "ARABA", "o": ["ARABA", "OTOBÜS", "BİSİKLET"]},
              {"q": "S", "a": "SU", "o": ["SU", "ÇAY", "KAHVE"]},
              {"q": "M", "a": "MUZ", "o": ["MUZ", "ELMA", "KİRAZ"]},
              {"q": "Ç", "a": "ÇANTA", "o": ["ÇANTA", "KALEM", "KİTAP"]},
              {"q": "B", "a": "BALIK", "o": ["BALIK", "KEDİ", "KUŞ"]},
              {"q": "T", "a": "TOP", "o": ["TOP", "BEBEK", "ARABA"]},
              {"q": "Y", "a": "YATAK", "o": ["YATAK", "MASA", "KAPI"]},
              {"q": "O", "a": "OKUL", "o": ["OKUL", "EV", "PARK"]},
              {"q": "D", "a": "DEFTER", "o": ["DEFTER", "KALEM", "SİLGİ"]},
              {"q": "P", "a": "PARK", "o": ["PARK", "OKUL", "EV"]},
              {"q": "G", "a": "GÜNEŞ", "o": ["GÜNEŞ", "AY", "YILDIZ"]},
              {"q": "L", "a": "LİMON", "o": ["LİMON", "ELMA", "ARMUT"]},
              {"q": "F", "a": "FARE", "o": ["FARE", "KEDİ", "KÖPEK"]},
              {"q": "N", "a": "NAR", "o": ["NAR", "MUZ", "KAVUN"]},
              {"q": "R", "a": "ROKET", "o": ["ROKET", "UÇAK", "GEMİ"]},
              {"q": "H", "a": "HAVUÇ", "o": ["HAVUÇ", "DOMATES", "BİBER"]},
              {"q": "İ", "a": "İNEK", "o": ["İNEK", "AT", "KOYUN"]},
              {"q": "Z", "a": "ZEBRA", "o": ["ZEBRA", "ASLAN", "FİL"]},
            ],
          ),
          _level(
            gameType: gameType,
            title: "Bitiş Sesi",
            icon: "🔉",
            questions: [
              {"q": "K", "a": "ÇİÇEK", "o": ["ÇİÇEK", "MASA", "KAPI"]},
              {"q": "L", "a": "OKUL", "o": ["OKUL", "SINIF", "ÇANTA"]},
              {"q": "Z", "a": "MUZ", "o": ["MUZ", "ELMA", "ARMUT"]},
              {"q": "A", "a": "MASA", "o": ["MASA", "KALEM", "DEFTER"]},
              {"q": "T", "a": "BULUT", "o": ["BULUT", "GÜNEŞ", "AY"]},
              {"q": "R", "a": "ŞEKER", "o": ["ŞEKER", "EKMEK", "SÜT"]},
              {"q": "M", "a": "KALEM", "o": ["KALEM", "SİLGİ", "KİTAP"]},
              {"q": "N", "a": "ASLAN", "o": ["ASLAN", "KEDİ", "BALIK"]},
              {"q": "Ş", "a": "GÜNEŞ", "o": ["GÜNEŞ", "AY", "YILDIZ"]},
              {"q": "E", "a": "FARE", "o": ["FARE", "KUŞ", "AT"]},
              {"q": "İ", "a": "GEMİ", "o": ["GEMİ", "UÇAK", "TREN"]},
              {"q": "P", "a": "TOP", "o": ["TOP", "KÜP", "KUTU"]},
              {"q": "Ç", "a": "SAÇ", "o": ["SAÇ", "EL", "DİŞ"]},
              {"q": "Y", "a": "AY", "o": ["AY", "GÜN", "GECE"]},
              {"q": "U", "a": "SU", "o": ["SU", "ÇAY", "SÜT"]},
              {"q": "I", "a": "KAPI", "o": ["KAPI", "MASA", "KOLTUK"]},
              {"q": "D", "a": "KANAT", "o": ["KANAT", "KUŞ", "BALIK"]},
              {"q": "S", "a": "ANANAS", "o": ["ANANAS", "ELMA", "MUZ"]},
              {"q": "J", "a": "ŞARJ", "o": ["ŞARJ", "GÖK", "GÜL"]},
              {"q": "P", "a": "DOLAP", "o": ["DOLAP", "KAPI", "MASA"]},
            ],
          ),
          _level(
            gameType: gameType,
            title: "İçindeki Ses",
            icon: "🔈",
            questions: [
              {"q": "A", "a": "KAPI", "o": ["KAPI", "ÜTÜ", "SÜT"]},
              {"q": "O", "a": "TOP", "o": ["TOP", "KİLİM", "BERE"]},
              {"q": "Ü", "a": "GÜL", "o": ["GÜL", "KOL", "BAL"]},
              {"q": "E", "a": "KALEM", "o": ["KALEM", "MUZ", "TOP"]},
              {"q": "İ", "a": "KİTAP", "o": ["KİTAP", "ARABA", "SU"]},
              {"q": "U", "a": "BULUT", "o": ["BULUT", "KALEM", "ELMA"]},
              {"q": "M", "a": "ELMA", "o": ["ELMA", "KAPI", "SU"]},
              {"q": "R", "a": "ARABA", "o": ["ARABA", "KEDİ", "SÜT"]},
              {"q": "L", "a": "BALIK", "o": ["BALIK", "TOP", "AY"]},
              {"q": "K", "a": "OKUL", "o": ["OKUL", "EV", "SU"]},
              {"q": "T", "a": "KİTAP", "o": ["KİTAP", "ELMA", "AY"]},
              {"q": "Ş", "a": "YEŞİL", "o": ["YEŞİL", "MAVİ", "SARI"]},
              {"q": "Y", "a": "OYUN", "o": ["OYUN", "KAPI", "ELMA"]},
              {"q": "D", "a": "KEDİ", "o": ["KEDİ", "KUŞ", "AT"]},
              {"q": "N", "a": "ANNE", "o": ["ANNE", "BABA", "DEDE"]},
              {"q": "B", "a": "BABA", "o": ["BABA", "ANNE", "NENE"]},
              {"q": "Ç", "a": "ÇİÇEK", "o": ["ÇİÇEK", "GÜNEŞ", "AY"]},
              {"q": "G", "a": "SİLGİ", "o": ["SİLGİ", "KALEM", "DEFTER"]},
              {"q": "P", "a": "KAPI", "o": ["KAPI", "KOLTUK", "MASA"]},
              {"q": "Z", "a": "MUZ", "o": ["MUZ", "ELMA", "ARMUT"]},
            ],
          ),
        ];

      case 'Okuma':
        return [
          _level(
            gameType: gameType,
            title: "Kolay",
            icon: "👀",
            questions: [
              {"w": "BABA", "a": "BABA", "o": ["BABA", "DEDE", "NENE"]},
              {"w": "ANNE", "a": "ANNE", "o": ["ANNE", "HALA", "TEYZE"]},
              {"w": "EV", "a": "EV", "o": ["EV", "OKUL", "PARK"]},
              {"w": "GÖZ", "a": "GÖZ", "o": ["GÖZ", "KULAK", "BURUN"]},
              {"w": "EL", "a": "EL", "o": ["EL", "AYAK", "KOL"]},
              {"w": "SU", "a": "SU", "o": ["SU", "SÜT", "ÇAY"]},
              {"w": "AY", "a": "AY", "o": ["AY", "GÜN", "YIL"]},
              {"w": "TOP", "a": "TOP", "o": ["TOP", "KÜP", "KUTU"]},
              {"w": "KUŞ", "a": "KUŞ", "o": ["KUŞ", "KEDİ", "KÖPEK"]},
              {"w": "MUZ", "a": "MUZ", "o": ["MUZ", "ELMA", "ARMUT"]},
              {"w": "KEDİ", "a": "KEDİ", "o": ["KEDİ", "KUŞ", "BALIK"]},
              {"w": "KAPI", "a": "KAPI", "o": ["KAPI", "MASA", "KOLTUK"]},
              {"w": "MASA", "a": "MASA", "o": ["MASA", "KAPI", "YATAK"]},
              {"w": "OKUL", "a": "OKUL", "o": ["OKUL", "EV", "PARK"]},
              {"w": "PARK", "a": "PARK", "o": ["PARK", "OKUL", "EV"]},
              {"w": "KAR", "a": "KAR", "o": ["KAR", "YAĞMUR", "GÜNEŞ"]},
              {"w": "GÜL", "a": "GÜL", "o": ["GÜL", "AY", "SU"]},
              {"w": "BAL", "a": "BAL", "o": ["BAL", "SÜT", "SU"]},
              {"w": "YOL", "a": "YOL", "o": ["YOL", "EV", "KAPI"]},
              {"w": "DİŞ", "a": "DİŞ", "o": ["DİŞ", "GÖZ", "EL"]},
            ],
          ),
          _level(
            gameType: gameType,
            title: "Orta",
            icon: "👓",
            questions: [
              {"w": "KARDEŞ", "a": "KARDEŞ", "o": ["KARDEŞ", "ARKADAŞ", "KOMŞU"]},
              {"w": "ÖĞRETMEN", "a": "ÖĞRETMEN", "o": ["ÖĞRETMEN", "DOKTOR", "POLİS"]},
              {"w": "SANDALYE", "a": "SANDALYE", "o": ["SANDALYE", "KOLTUK", "MASA"]},
              {"w": "BİSİKLET", "a": "BİSİKLET", "o": ["BİSİKLET", "ARABA", "TREN"]},
              {"w": "ÇANTA", "a": "ÇANTA", "o": ["ÇANTA", "KALEM", "DEFTER"]},
              {"w": "DEFTER", "a": "DEFTER", "o": ["DEFTER", "SİLGİ", "KİTAP"]},
              {"w": "KALEM", "a": "KALEM", "o": ["KALEM", "ÇANTA", "OKUL"]},
              {"w": "ÇİÇEK", "a": "ÇİÇEK", "o": ["ÇİÇEK", "AĞAÇ", "YAPRAK"]},
              {"w": "GÜNEŞ", "a": "GÜNEŞ", "o": ["GÜNEŞ", "AY", "YILDIZ"]},
              {"w": "BULUT", "a": "BULUT", "o": ["BULUT", "YAĞMUR", "KAR"]},
              {"w": "KÖPEK", "a": "KÖPEK", "o": ["KÖPEK", "KEDİ", "KUŞ"]},
              {"w": "BALIK", "a": "BALIK", "o": ["BALIK", "KEDİ", "AT"]},
              {"w": "ARABA", "a": "ARABA", "o": ["ARABA", "UÇAK", "GEMİ"]},
              {"w": "OTOBÜS", "a": "OTOBÜS", "o": ["OTOBÜS", "TREN", "VAPUR"]},
              {"w": "TAVŞAN", "a": "TAVŞAN", "o": ["TAVŞAN", "ASLAN", "FİL"]},
              {"w": "KAPLAN", "a": "KAPLAN", "o": ["KAPLAN", "KEDİ", "KÖPEK"]},
              {"w": "RENKLİ", "a": "RENKLİ", "o": ["RENKLİ", "SARI", "MAVİ"]},
              {"w": "OYUNCAK", "a": "OYUNCAK", "o": ["OYUNCAK", "KİTAP", "ÇANTA"]},
              {"w": "MUTFAK", "a": "MUTFAK", "o": ["MUTFAK", "ODA", "BAHÇE"]},
              {"w": "BAHÇE", "a": "BAHÇE", "o": ["BAHÇE", "OKUL", "EV"]},
            ],
          ),
          _level(
            gameType: gameType,
            title: "Zor",
            icon: "🕶️",
            questions: [
              {"w": "BİLGİSAYAR", "a": "BİLGİSAYAR", "o": ["BİLGİSAYAR", "TELEVİZYON", "BUZDOLABI"]},
              {"w": "KÜTÜPHANE", "a": "KÜTÜPHANE", "o": ["KÜTÜPHANE", "HASTANE", "POSTANE"]},
              {"w": "ÖĞRENCİ", "a": "ÖĞRENCİ", "o": ["ÖĞRENCİ", "ÖĞRETMEN", "DOKTOR"]},
              {"w": "ARKADAŞ", "a": "ARKADAŞ", "o": ["ARKADAŞ", "KARDEŞ", "KOMŞU"]},
              {"w": "DİKDÖRTGEN", "a": "DİKDÖRTGEN", "o": ["DİKDÖRTGEN", "ÜÇGEN", "DAİRE"]},
              {"w": "GÖKKUŞAĞI", "a": "GÖKKUŞAĞI", "o": ["GÖKKUŞAĞI", "YAĞMUR", "BULUT"]},
              {"w": "KAPLUMBAĞA", "a": "KAPLUMBAĞA", "o": ["KAPLUMBAĞA", "TAVŞAN", "KEDİ"]},
              {"w": "HELİKOPTER", "a": "HELİKOPTER", "o": ["HELİKOPTER", "UÇAK", "ROKET"]},
              {"w": "HASTANE", "a": "HASTANE", "o": ["HASTANE", "OKUL", "PARK"]},
              {"w": "POSTANE", "a": "POSTANE", "o": ["POSTANE", "KÜTÜPHANE", "HASTANE"]},
              {"w": "TELEVİZYON", "a": "TELEVİZYON", "o": ["TELEVİZYON", "TELEFON", "TABLET"]},
              {"w": "BUZDOLABI", "a": "BUZDOLABI", "o": ["BUZDOLABI", "FIRIN", "MASA"]},
              {"w": "PENCERE", "a": "PENCERE", "o": ["PENCERE", "KAPI", "DUVAR"]},
              {"w": "MERDİVEN", "a": "MERDİVEN", "o": ["MERDİVEN", "YOL", "KAPI"]},
              {"w": "OYUNCAKLAR", "a": "OYUNCAKLAR", "o": ["OYUNCAKLAR", "KİTAPLAR", "KALEMLER"]},
              {"w": "ÇİLEKLER", "a": "ÇİLEKLER", "o": ["ÇİLEKLER", "ELMALAR", "MUZLAR"]},
              {"w": "KARANLIK", "a": "KARANLIK", "o": ["KARANLIK", "AYDINLIK", "RENKLİ"]},
              {"w": "MUTLULUK", "a": "MUTLULUK", "o": ["MUTLULUK", "ÜZÜNTÜ", "KORKU"]},
              {"w": "ÇALIŞKAN", "a": "ÇALIŞKAN", "o": ["ÇALIŞKAN", "UYKULU", "YORGUN"]},
              {"w": "BAŞARILI", "a": "BAŞARILI", "o": ["BAŞARILI", "KOLAY", "ZOR"]},
            ],
          ),
        ];

      default:
        return [];
    }
  }
}
import 'package:flutter/material.dart';

import '../../repositories/game_repository.dart';
import '../../pages/student_home.dart';

class ContinueActivityCard extends StatelessWidget {
  final Map<String, dynamic> lastActivity;

  const ContinueActivityCard({
    super.key,
    required this.lastActivity,
  });

  @override
  Widget build(BuildContext context) {
    final gameType = lastActivity['gameType']?.toString() ?? "Etkinlik";
    final levelTitle = lastActivity['levelTitle']?.toString() ?? "Seviye";
    final step = (lastActivity['step'] is int) ? lastActivity['step'] as int : 0;

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () {
        final levels = GameRepository.getLevels(gameType);

        Map<String, dynamic>? selectedLevel;

        for (final level in levels) {
          if (level['title'] == levelTitle) {
            selectedLevel = level;
            break;
          }
        }

        if (selectedLevel == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kaldığın etkinlik bulunamadı."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final questions = GameRepository.prepareQuestions(
          List<Map<String, dynamic>>.from(selectedLevel['questions']),
        );
        final safeStep = step.clamp(0, questions.length - 1).toInt();
        final detailedKey = "$gameType: ${selectedLevel['title']}";

        Widget gameScreen;

        switch (gameType) {
          case 'Heceleme':
            gameScreen = GameSyllable(
              questions: questions,
              gameKey: detailedKey,
              initialStep: safeStep,
            );
            break;

          case 'Tanıma':
            gameScreen = GameRecognition(
              questions: questions,
              gameKey: detailedKey,
              initialStep: safeStep,
            );
            break;

          case 'Hız':
            gameScreen = GameSpeed(
              questions: questions,
              gameKey: detailedKey,
              initialStep: safeStep,
            );
            break;

          case 'Bellek':
            gameScreen = GameMemory(
              questions: questions,
              gameKey: detailedKey,
              initialStep: safeStep,
            );
            break;

          case 'Yazma':
            gameScreen = GameSpelling(
              questions: questions,
              gameKey: detailedKey,
              initialStep: safeStep,
            );
            break;

          case 'Hikaye':
            gameScreen = GameStory(
              questions: questions,
              gameKey: detailedKey,
              initialStep: safeStep,
            );
            break;

          case 'Sesler':
            gameScreen = GameSound(
              questions: questions,
              gameKey: detailedKey,
              initialStep: safeStep,
            );
            break;

          case 'Okuma':
            gameScreen = GameReading(
              questions: questions,
              gameKey: detailedKey,
              initialStep: safeStep,
            );
            break;

          default:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Bu etkinlik türü desteklenmiyor."),
                backgroundColor: Colors.red,
              ),
            );
            return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => gameScreen),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0072FF).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Kaldığın yerden devam et",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$gameType • $levelTitle",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${step + 1}. etkinlik seni bekliyor 🚀",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
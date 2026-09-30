import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../repositories/daily_task_repository.dart';

class HomeDailyTasksCard extends StatefulWidget {
  final void Function(Map<String, dynamic> task) onOpenTask;

  const HomeDailyTasksCard({
    super.key,
    required this.onOpenTask,
  });

  @override
  State<HomeDailyTasksCard> createState() => _HomeDailyTasksCardState();
}

class _HomeDailyTasksCardState extends State<HomeDailyTasksCard> {
  bool _loading = true;
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final tasks = await DailyTaskRepository.ensureDailyTasks(uid: uid);

    if (!mounted) return;

    try {
      await context.read<AppProvider>().loadFromFirebase();
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppProvider>();
    final gradient = u.currentTheme.gradient;

    final completedCount =
        _tasks.where((task) => task['completed'] == true).length;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.76,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.26),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Bugünün Görevleri",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _loading
                              ? "Görevler hazırlanıyor..."
                              : "$completedCount/3 görev tamamlandı",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 12.3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _loading ? "..." : "$completedCount/3",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: _loading
                  ? Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: gradient.first,
                ),
              )
                  : ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(14),
                children: [
                  ..._tasks.map((task) {
                    final completed = task['completed'] == true;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DailyTaskTile(
                        gradient: gradient,
                        task: task,
                        completed: completed,
                        onTap: completed
                            ? null
                            : () {
                          widget.onOpenTask(task);
                        },
                      ),
                    );
                  }),
                  if (completedCount >= 3)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.18),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Harika! Bugünkü görevlerin tamamlandı.",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyTaskTile extends StatelessWidget {
  final List<Color> gradient;
  final Map<String, dynamic> task;
  final bool completed;
  final VoidCallback? onTap;

  const _DailyTaskTile({
    required this.gradient,
    required this.task,
    required this.completed,
    required this.onTap,
  });

  IconData _iconForGame(String gameType) {
    switch (gameType) {
      case "Heceleme":
        return Icons.text_fields_rounded;
      case "Tanıma":
        return Icons.visibility_rounded;
      case "Hız":
        return Icons.flash_on_rounded;
      case "Bellek":
        return Icons.psychology_rounded;
      case "Yazma":
        return Icons.edit_rounded;
      case "Hikaye":
        return Icons.menu_book_rounded;
      case "Sesler":
        return Icons.volume_up_rounded;
      case "Okuma":
        return Icons.auto_stories_rounded;
      default:
        return Icons.play_arrow_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameType = task['gameType']?.toString() ?? "Etkinlik";
    final levelTitle = task['levelTitle']?.toString() ?? "Bölüm";
    final rewardStars = task['rewardStars']?.toString() ?? "2";

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: completed ? Colors.green.withOpacity(0.10) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: completed
                  ? Colors.green.withOpacity(0.22)
                  : gradient.first.withOpacity(0.14),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: completed
                    ? Colors.green.withOpacity(0.06)
                    : gradient.first.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: completed
                      ? const LinearGradient(
                    colors: [
                      Color(0xFF66BB6A),
                      Color(0xFF43A047),
                    ],
                  )
                      : LinearGradient(
                    colors: [
                      gradient.first.withOpacity(0.92),
                      gradient.last.withOpacity(0.92),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  completed ? Icons.check_rounded : _iconForGame(gameType),
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
                      gameType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      levelTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: completed
                      ? Colors.green.withOpacity(0.13)
                      : gradient.first.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: completed ? Colors.green : gradient.first,
                      size: 15,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rewardStars,
                      style: TextStyle(
                        color: completed ? Colors.green : gradient.first,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: completed ? Colors.green : gradient.first,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_utils.dart';
import '../../providers/habit_provider.dart';
import '../widgets/date_selector_strip.dart';
import '../widgets/habit_card.dart';
import 'habit_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getMotivationalMessage(double rate, int completed, int total) {
    if (total == 0) {
      return 'Chưa có thói quen nào được lên lịch cho ngày này.';
    }
    if (rate >= 100.0) {
      return 'Xuất sắc! Bạn đã hoàn thành 100% mục tiêu hôm nay! 🌟';
    }
    if (rate >= 66.0) {
      return 'Sắp về đích rồi! Tiếp tục giữ vững phong độ nhé! 💪';
    }
    if (rate >= 33.0) {
      return 'Bạn đang làm rất tốt, hãy duy trì kỷ luật! 🚀';
    }
    if (completed > 0) {
      return 'Khởi đầu tốt đẹp! Từng bước nhỏ tạo nên thay đổi lớn! 🌱';
    }
    return 'Bắt đầu ngày mới đầy năng lượng và quyết tâm! ☀️';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final selectedDate = provider.selectedDate;
        final habits = provider.habitsForSelectedDate;
        final counts = provider.selectedDateCounts;
        final rate = provider.selectedDateCompletionRate;
        final isToday = DateTimeUtils.isToday(selectedDate);

        // Active dates with completion logs for the strip dots
        final activeLogDates = provider.logs.map((l) => l.completedDate).toSet();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar with date and streak indicator
            SliverAppBar(
              floating: true,
              pinned: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateTimeUtils.formatHeaderDate(selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        isToday ? 'Hôm nay' : DateTimeUtils.getWeekdayFullName(selectedDate.weekday),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (provider.globalBestStreak > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                '${provider.globalBestStreak} ngày',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              actions: [
                if (!isToday)
                  TextButton.icon(
                    onPressed: () {
                      provider.setSelectedDate(DateTime.now());
                    },
                    icon: const Icon(Icons.today, size: 16),
                    label: const Text('Hôm nay'),
                  ),
                IconButton(
                  tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  ),
                  onPressed: () => provider.toggleTheme(),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Horizontal Date Strip
            SliverToBoxAdapter(
              child: DateSelectorStrip(
                selectedDate: selectedDate,
                activeLogDates: activeLogDates,
                onDateSelected: (date) {
                  provider.setSelectedDate(date);
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Daily Summary Progress Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(70),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Circular Progress Indicator
                      CircularPercentIndicator(
                        radius: 38.0,
                        lineWidth: 7.0,
                        animation: true,
                        animateFromLastPercent: true,
                        percent: (rate / 100.0).clamp(0.0, 1.0),
                        center: Text(
                          '${rate.toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Colors.white,
                          ),
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: Colors.white,
                        backgroundColor: Colors.white.withAlpha(60),
                      ),
                      const SizedBox(width: 18),
                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã hoàn thành ${counts.completed}/${counts.scheduled} thói quen',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _getMotivationalMessage(
                                rate,
                                counts.completed,
                                counts.scheduled,
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withAlpha(220),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Habit List Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Danh sách thói quen (${habits.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '${counts.completed} đã xong',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Habit List Items or Empty State
            if (habits.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withAlpha(20),
                          ),
                          child: const Icon(
                            Icons.checklist_rtl_rounded,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Không có thói quen nào!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa có thói quen nào được lên lịch cho ngày này. Hãy tạo thói quen mới để rèn luyện kỷ luật!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HabitFormScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo thói quen đầu tiên'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final habit = habits[index];
                      final isCompleted = provider.isHabitCompleted(habit.id!);
                      final streak = provider.getStreak(habit.id!);

                      return HabitCard(
                        habit: habit,
                        isCompleted: isCompleted,
                        streak: streak,
                        onToggle: () {
                          provider.toggleHabitCompletion(habit.id!, selectedDate);
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HabitFormScreen(habit: habit),
                            ),
                          );
                        },
                        onDelete: () {
                          provider.deleteHabit(habit.id!);
                        },
                      );
                    },
                    childCount: habits.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

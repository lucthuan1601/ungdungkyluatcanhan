import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_utils.dart';
import '../../providers/habit_provider.dart';
import '../widgets/stat_chart_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedViewIndex = 0; // 0: Ngày, 1: Tuần, 2: Tháng

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final bestStreak = provider.globalBestStreak;
        final totalCompletions = provider.totalCompletions;
        final avgRate = provider.averageCompletionRate;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Thống kê tiến độ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                onPressed: () => provider.toggleTheme(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 90),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. Thẻ chỉ số tổng quan nhanh (Overview Metric Cards)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    OverviewMetricCard(
                      title: 'Kỷ lục chuỗi',
                      value: '$bestStreak ngày',
                      subtitle: 'Best Streak',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    OverviewMetricCard(
                      title: 'Tổng hoàn thành',
                      value: '$totalCompletions',
                      subtitle: 'Lượt check-in',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    OverviewMetricCard(
                      title: 'Tỷ lệ TB',
                      value: '${avgRate.toStringAsFixed(0)}%',
                      subtitle: '30 ngày qua',
                      icon: Icons.insights_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. Chế độ xem: Ngày / Tuần / Tháng (SegmentedButton)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Hôm nay'),
                      icon: Icon(Icons.today_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Tuần này'),
                      icon: Icon(Icons.view_week_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text('Tháng này'),
                      icon: Icon(Icons.calendar_month_rounded, size: 18),
                    ),
                  ],
                  selected: {_selectedViewIndex},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedViewIndex = newSelection.first;
                    });
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 3. Nội dung theo từng chế độ xem
              if (_selectedViewIndex == 0)
                _buildDailyView(provider, isDark)
              else if (_selectedViewIndex == 1)
                _buildWeeklyView(provider, isDark)
              else
                _buildMonthlyView(provider, isDark),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // DAILY VIEW
  // -------------------------------------------------------------
  Widget _buildDailyView(HabitProvider provider, bool isDark) {
    final selectedDate = provider.selectedDate;
    final habits = provider.habitsForSelectedDate;
    final counts = provider.selectedDateCounts;
    final rate = provider.selectedDateCompletionRate;

    final completedHabits =
        habits.where((h) => provider.isHabitCompleted(h.id!)).toList();
    final pendingHabits =
        habits.where((h) => !provider.isHabitCompleted(h.id!)).toList();

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Tiến độ ngày ${DateTimeUtils.formatDisplay(selectedDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                CircularPercentIndicator(
                  radius: 70.0,
                  lineWidth: 12.0,
                  animation: true,
                  percent: (rate / 100.0).clamp(0.0, 1.0),
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${rate.toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28.0,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${counts.completed}/${counts.scheduled} xong',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: AppColors.primary,
                  backgroundColor: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _dailyMiniBadge(
                      'Đã xong',
                      '${completedHabits.length}',
                      AppColors.success,
                      Icons.check_circle_outline,
                      isDark,
                    ),
                    _dailyMiniBadge(
                      'Còn lại',
                      '${pendingHabits.length}',
                      AppColors.warning,
                      Icons.pending_outlined,
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Chi tiết danh sách thói quen trong ngày
        if (habits.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chi tiết thói quen hôm nay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ),
          ...habits.map((habit) {
            final isDone = provider.isHabitCompleted(habit.id!);
            final habitColor = Color(habit.colorCode);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: habitColor.withAlpha(30),
                  child: Icon(
                    isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: isDone ? habitColor : (isDark ? Colors.grey : Colors.grey.shade400),
                  ),
                ),
                title: Text(
                  habit.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone
                        ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                ),
                subtitle: Text(
                  DateTimeUtils.formatDaysOfWeekDescription(habit.daysOfWeek),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.success.withAlpha(25) : Colors.grey.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isDone ? 'Hoàn thành' : 'Chưa xong',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDone ? AppColors.success : Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _dailyMiniBadge(
    String label,
    String value,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // WEEKLY VIEW
  // -------------------------------------------------------------
  Widget _buildWeeklyView(HabitProvider provider, bool isDark) {
    final weeklyStats = provider.getWeeklyStats();
    final weeklyRate = provider.getWeeklyCompletionRate();

    final totalScheduled =
        weeklyStats.fold<int>(0, (sum, s) => sum + s.scheduledCount);
    final totalCompleted =
        weeklyStats.fold<int>(0, (sum, s) => sum + s.completedCount);

    return Column(
      children: [
        WeeklyBarChartCard(
          weeklyStats: weeklyStats,
          overallRate: weeklyRate,
        ),

        // Weekly Summary Details
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng kết tuần',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryDetailItem(
                        'Tổng lần lên lịch',
                        '$totalScheduled',
                        isDark,
                      ),
                      _summaryDetailItem(
                        'Tổng lần hoàn thành',
                        '$totalCompleted',
                        isDark,
                      ),
                      _summaryDetailItem(
                        'Tỷ lệ đạt được',
                        '${weeklyRate.toStringAsFixed(1)}%',
                        isDark,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // MONTHLY VIEW
  // -------------------------------------------------------------
  Widget _buildMonthlyView(HabitProvider provider, bool isDark) {
    final monthlyStats = provider.getMonthlyDailyStats();
    final monthlyRate = provider.getMonthlyCompletionRate();
    final habitPerformances = provider.getHabitMonthlyPerformance();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Biểu đồ đường xu hướng kỷ luật
        MonthlyLineChartCard(
          monthlyStats: monthlyStats,
          overallRate: monthlyRate,
        ),

        // Lưới nhiệt độ tháng (Heatmap Calendar)
        MonthlyHeatmapCard(monthlyStats: monthlyStats),

        // Bảng xếp hạng tỷ lệ hoàn thành từng thói quen trong tháng
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'Xếp hạng hiệu suất thói quen trong tháng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),

        if (habitPerformances.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Chưa có dữ liệu thói quen cho tháng này.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
          )
        else
          ...habitPerformances.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final habit = item.habit;
            final habitColor = Color(habit.colorCode);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Rank badge
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? AppColors.accent
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: index == 0
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Title
                        Expanded(
                          child: Text(
                            habit.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        // Streak if any
                        if (item.currentStreak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🔥 ${item.currentStreak}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress Bar
                    LinearPercentIndicator(
                      padding: EdgeInsets.zero,
                      lineHeight: 8.0,
                      percent: (item.completionRate / 100.0).clamp(0.0, 1.0),
                      barRadius: const Radius.circular(4),
                      progressColor: habitColor,
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    const SizedBox(height: 8),
                    // Stats caption
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.completedCount}/${item.scheduledCount} ngày hoàn thành',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          '${item.completionRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: habitColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _summaryDetailItem(
    String label,
    String value,
    bool isDark, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ??
                (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

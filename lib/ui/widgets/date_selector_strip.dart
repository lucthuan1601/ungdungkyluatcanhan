import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_utils.dart';

class DateSelectorStrip extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Set<String> activeLogDates;

  const DateSelectorStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.activeLogDates = const {},
  });

  @override
  State<DateSelectorStrip> createState() => _DateSelectorStripState();
}

class _DateSelectorStripState extends State<DateSelectorStrip> {
  late final ScrollController _scrollController;
  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Generate a window of 21 days: 14 days before today and 6 days after today
    final today = DateTimeUtils.dateOnly(DateTime.now());
    _dates = List.generate(21, (index) {
      return today.subtract(Duration(days: 14 - index));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  void _scrollToSelectedDate() {
    if (!_scrollController.hasClients) return;
    final index = _dates.indexWhere(
      (d) => DateTimeUtils.isSameDay(d, widget.selectedDate),
    );
    if (index != -1) {
      // Each date item width is approx 58 + 8 margin = 66
      final offset = (index * 66.0) - (MediaQuery.of(context).size.width / 2) + 33;
      if (offset > 0) {
        _scrollController.animateTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant DateSelectorStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateTimeUtils.isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _scrollToSelectedDate();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 92,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = DateTimeUtils.isSameDay(date, widget.selectedDate);
          final isToday = DateTimeUtils.isToday(date);
          final dateIso = DateTimeUtils.toIsoDateString(date);
          final hasCompletedLogs = widget.activeLogDates.contains(dateIso);

          return GestureDetector(
            onTap: () => widget.onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isToday
                          ? AppColors.primary.withAlpha(128)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  width: isToday ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Weekday short name (T2, T3... CN)
                  Text(
                    isToday ? 'Hôm nay' : DateTimeUtils.getWeekdayShortName(date.weekday),
                    style: TextStyle(
                      fontSize: isToday ? 10 : 12,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white.withAlpha(230)
                          : (isToday
                              ? AppColors.primary
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Day number
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Completion dot indicator
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasCompletedLogs
                          ? (isSelected ? Colors.white : AppColors.success)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

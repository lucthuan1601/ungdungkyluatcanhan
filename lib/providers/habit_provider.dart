import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_time_utils.dart';
import '../data/models/habit_log_model.dart';
import '../data/models/habit_model.dart';
import '../data/repositories/habit_repository.dart';

class HabitDailyStat {
  final DateTime date;
  final String dayLabel;
  final int scheduledCount;
  final int completedCount;
  final double completionRate;

  HabitDailyStat({
    required this.date,
    required this.dayLabel,
    required this.scheduledCount,
    required this.completedCount,
    required this.completionRate,
  });
}

class HabitPerformanceItem {
  final HabitModel habit;
  final int scheduledCount;
  final int completedCount;
  final double completionRate;
  final int currentStreak;

  HabitPerformanceItem({
    required this.habit,
    required this.scheduledCount,
    required this.completedCount,
    required this.completionRate,
    required this.currentStreak,
  });
}

class HabitProvider extends ChangeNotifier {
  final HabitRepository _repository;
  SharedPreferences? _prefs;

  HabitProvider({HabitRepository? repository})
      : _repository = repository ?? HabitRepository();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  DateTime _selectedDate = DateTimeUtils.dateOnly(DateTime.now());
  DateTime get selectedDate => _selectedDate;

  List<HabitModel> _habits = [];
  List<HabitModel> get habits => _habits;

  List<HabitLogModel> _logs = [];
  List<HabitLogModel> get logs => _logs;

  // Set of habit IDs completed on _selectedDate
  Set<int> _completedHabitIds = {};
  Set<int> get completedHabitIds => _completedHabitIds;

  // Streak cache
  final Map<int, int> _currentStreaks = {};
  final Map<int, int> _bestStreaks = {};

  /// Initialize provider, load theme settings and database records
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();
      _isDarkMode = _prefs?.getBool(AppConstants.prefThemeKey) ?? false;
      await _loadAllData();
    } catch (e) {
      debugPrint('Error initializing HabitProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle dark mode and persist to SharedPreferences
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs?.setBool(AppConstants.prefThemeKey, _isDarkMode);
    notifyListeners();
  }

  /// Set selected date from date selector strip
  void setSelectedDate(DateTime date) {
    _selectedDate = DateTimeUtils.dateOnly(date);
    _updateCompletedHabitsForSelectedDate();
    notifyListeners();
  }

  /// Habits scheduled for the current selected date
  List<HabitModel> get habitsForSelectedDate {
    return _habits
        .where((habit) => habit.isScheduledForDate(_selectedDate))
        .toList();
  }

  /// Check whether a habit is completed on the selected date
  bool isHabitCompleted(int habitId) {
    return _completedHabitIds.contains(habitId);
  }

  /// Get current streak for a habit
  int getStreak(int habitId) {
    return _currentStreaks[habitId] ?? 0;
  }

  /// Get best streak for a habit
  int getBestStreak(int habitId) {
    return _bestStreaks[habitId] ?? 0;
  }

  /// Global best streak across all habits
  int get globalBestStreak {
    if (_bestStreaks.isEmpty) return 0;
    return _bestStreaks.values.fold(0, (max, s) => s > max ? s : max);
  }

  /// Total completions across all habits
  int get totalCompletions {
    final activeHabitIds = _habits.map((h) => h.id).toSet();
    return _logs.where((l) => activeHabitIds.contains(l.habitId)).length;
  }

  /// Daily completion rate for the selected date (0.0 - 100.0%)
  double get selectedDateCompletionRate {
    final scheduled = habitsForSelectedDate.length;
    if (scheduled == 0) return 0.0;
    final completed = habitsForSelectedDate
        .where((h) => _completedHabitIds.contains(h.id))
        .length;
    return (completed / scheduled) * 100.0;
  }

  /// Selected date counts: (completed, scheduled)
  ({int completed, int scheduled}) get selectedDateCounts {
    final scheduled = habitsForSelectedDate.length;
    final completed = habitsForSelectedDate
        .where((h) => _completedHabitIds.contains(h.id))
        .length;
    return (completed: completed, scheduled: scheduled);
  }

  /// Load all habits and logs from repository
  Future<void> _loadAllData() async {
    _habits = await _repository.getAllHabits();
    _logs = await _repository.getAllLogs();
    _updateCompletedHabitsForSelectedDate();
    _recalculateStreaks();
  }

  void _updateCompletedHabitsForSelectedDate() {
    final selectedDateStr = DateTimeUtils.toIsoDateString(_selectedDate);
    _completedHabitIds = _logs
        .where((log) => log.completedDate == selectedDateStr)
        .map((log) => log.habitId)
        .toSet();
  }

  /// Toggle completion of a habit for selectedDate (or specified date)
  Future<void> toggleHabitCompletion(int habitId, [DateTime? targetDate]) async {
    final date = targetDate ?? _selectedDate;
    final dateStr = DateTimeUtils.toIsoDateString(date);

    // Optimistic UI update
    if (DateTimeUtils.isSameDay(date, _selectedDate)) {
      if (_completedHabitIds.contains(habitId)) {
        _completedHabitIds.remove(habitId);
        _logs.removeWhere(
          (l) => l.habitId == habitId && l.completedDate == dateStr,
        );
      } else {
        _completedHabitIds.add(habitId);
        _logs.add(HabitLogModel(habitId: habitId, completedDate: dateStr));
      }
      _recalculateStreaks();
      notifyListeners();
    }

    try {
      await _repository.toggleHabitCompletion(habitId, dateStr);
      // Refresh accurate data from DB
      await _loadAllData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling habit completion: $e');
      // Revert in case of error
      await _loadAllData();
      notifyListeners();
    }
  }

  /// Add a new habit
  Future<int> addHabit(HabitModel habit) async {
    final id = await _repository.insertHabit(habit);
    await _loadAllData();
    notifyListeners();
    return id;
  }

  /// Update an existing habit
  Future<void> updateHabit(HabitModel habit) async {
    await _repository.updateHabit(habit);
    await _loadAllData();
    notifyListeners();
  }

  /// Delete habit by ID
  Future<void> deleteHabit(int habitId) async {
    await _repository.deleteHabit(habitId);
    await _loadAllData();
    notifyListeners();
  }

  /// Recalculates both current streaks and best streaks for each habit
  void _recalculateStreaks() {
    _currentStreaks.clear();
    _bestStreaks.clear();

    final today = DateTimeUtils.dateOnly(DateTime.now());

    // Map habitId -> Set of ISO dates completed
    final habitLogsMap = <int, Set<String>>{};
    for (final log in _logs) {
      habitLogsMap.putIfAbsent(log.habitId, () => <String>{}).add(log.completedDate);
    }

    for (final habit in _habits) {
      if (habit.id == null) continue;
      final habitId = habit.id!;
      final completedDates = habitLogsMap[habitId] ?? <String>{};
      final habitCreatedDate = DateTimeUtils.parseIsoDateString(habit.createdAt);

      // 1. Calculate Current Streak
      int streak = 0;
      DateTime cursor = today;

      // Check today's condition:
      // If today is scheduled and completed -> streak starts at 1, check yesterday
      // If today is scheduled and not completed -> today is still ongoing, check yesterday
      // If today is not scheduled -> check yesterday
      if (habit.isScheduledForDate(today)) {
        final todayStr = DateTimeUtils.toIsoDateString(today);
        if (completedDates.contains(todayStr)) {
          streak = 1;
        }
      }

      // Check preceding scheduled days
      cursor = cursor.subtract(const Duration(days: 1));
      while (cursor.compareTo(habitCreatedDate) >= 0) {
        if (habit.isScheduledForDate(cursor)) {
          final dateStr = DateTimeUtils.toIsoDateString(cursor);
          if (completedDates.contains(dateStr)) {
            streak++;
          } else {
            // Broken streak
            break;
          }
        }
        cursor = cursor.subtract(const Duration(days: 1));
      }
      _currentStreaks[habitId] = streak;

      // 2. Calculate Best Streak across full history
      int best = 0;
      int runningStreak = 0;
      DateTime historyCursor = habitCreatedDate;

      while (historyCursor.compareTo(today) <= 0) {
        if (habit.isScheduledForDate(historyCursor)) {
          final dateStr = DateTimeUtils.toIsoDateString(historyCursor);
          if (completedDates.contains(dateStr)) {
            runningStreak++;
            if (runningStreak > best) {
              best = runningStreak;
            }
          } else {
            runningStreak = 0;
          }
        }
        historyCursor = historyCursor.add(const Duration(days: 1));
      }
      // Ensure best streak is at least current streak
      if (streak > best) best = streak;
      _bestStreaks[habitId] = best;
    }
  }

  // -------------------------------------------------------------
  // STATISTICS CALCULATIONS (Daily, Weekly, Monthly)
  // -------------------------------------------------------------

  /// Calculates Daily Statistics for any given date
  HabitDailyStat getDailyStatForDate(DateTime date) {
    final dateOnly = DateTimeUtils.dateOnly(date);
    final dateStr = DateTimeUtils.toIsoDateString(dateOnly);

    final scheduledHabits =
        _habits.where((h) => h.isScheduledForDate(dateOnly)).toList();
    final scheduledCount = scheduledHabits.length;

    if (scheduledCount == 0) {
      return HabitDailyStat(
        date: dateOnly,
        dayLabel: DateTimeUtils.getWeekdayShortName(dateOnly.weekday),
        scheduledCount: 0,
        completedCount: 0,
        completionRate: 0.0,
      );
    }

    final scheduledIds = scheduledHabits.map((h) => h.id).toSet();
    final completedCount = _logs
        .where(
          (log) =>
              log.completedDate == dateStr && scheduledIds.contains(log.habitId),
        )
        .length;

    final rate = (completedCount / scheduledCount) * 100.0;
    return HabitDailyStat(
      date: dateOnly,
      dayLabel: DateTimeUtils.getWeekdayShortName(dateOnly.weekday),
      scheduledCount: scheduledCount,
      completedCount: completedCount,
      completionRate: rate.clamp(0.0, 100.0),
    );
  }

  /// Calculates Weekly Statistics (7 days: Monday to Sunday)
  List<HabitDailyStat> getWeeklyStats([DateTime? referenceDate]) {
    final weekDays = DateTimeUtils.getWeekDays(referenceDate ?? _selectedDate);
    return weekDays.map((d) => getDailyStatForDate(d)).toList();
  }

  /// Weekly Overall Completion Rate
  double getWeeklyCompletionRate([DateTime? referenceDate]) {
    final weekStats = getWeeklyStats(referenceDate);
    final totalScheduled =
        weekStats.fold<int>(0, (sum, stat) => sum + stat.scheduledCount);
    if (totalScheduled == 0) return 0.0;

    final totalCompleted =
        weekStats.fold<int>(0, (sum, stat) => sum + stat.completedCount);
    return ((totalCompleted / totalScheduled) * 100.0).clamp(0.0, 100.0);
  }

  /// Calculates Monthly Statistics for all days in the month
  List<HabitDailyStat> getMonthlyDailyStats([DateTime? referenceDate]) {
    final days = DateTimeUtils.getDaysInMonth(referenceDate ?? _selectedDate);
    return days.map((d) => getDailyStatForDate(d)).toList();
  }

  /// Monthly Overall Completion Rate (up to today or end of month)
  double getMonthlyCompletionRate([DateTime? referenceDate]) {
    final ref = referenceDate ?? _selectedDate;
    final now = DateTimeUtils.dateOnly(DateTime.now());
    final days = DateTimeUtils.getDaysInMonth(ref);

    // Only count days up to today if looking at current month
    final eligibleDays = (ref.year == now.year && ref.month == now.month)
        ? days.where((d) => d.compareTo(now) <= 0).toList()
        : days;

    int totalScheduled = 0;
    int totalCompleted = 0;

    for (final day in eligibleDays) {
      final stat = getDailyStatForDate(day);
      totalScheduled += stat.scheduledCount;
      totalCompleted += stat.completedCount;
    }

    if (totalScheduled == 0) return 0.0;
    return ((totalCompleted / totalScheduled) * 100.0).clamp(0.0, 100.0);
  }

  /// Performance of each habit during the month
  List<HabitPerformanceItem> getHabitMonthlyPerformance([DateTime? referenceDate]) {
    final ref = referenceDate ?? _selectedDate;
    final now = DateTimeUtils.dateOnly(DateTime.now());
    final days = DateTimeUtils.getDaysInMonth(ref);

    final eligibleDays = (ref.year == now.year && ref.month == now.month)
        ? days.where((d) => d.compareTo(now) <= 0).toList()
        : days;

    final result = <HabitPerformanceItem>[];

    for (final habit in _habits) {
      if (habit.id == null) continue;
      final habitId = habit.id!;

      int scheduledCount = 0;
      int completedCount = 0;

      for (final day in eligibleDays) {
        if (habit.isScheduledForDate(day)) {
          scheduledCount++;
          final dayStr = DateTimeUtils.toIsoDateString(day);
          final hasLog = _logs.any(
            (l) => l.habitId == habitId && l.completedDate == dayStr,
          );
          if (hasLog) {
            completedCount++;
          }
        }
      }

      final rate = scheduledCount == 0
          ? 0.0
          : ((completedCount / scheduledCount) * 100.0).clamp(0.0, 100.0);

      result.add(
        HabitPerformanceItem(
          habit: habit,
          scheduledCount: scheduledCount,
          completedCount: completedCount,
          completionRate: rate,
          currentStreak: getStreak(habitId),
        ),
      );
    }

    // Sort by completionRate descending, then completedCount descending
    result.sort((a, b) {
      final compRate = b.completionRate.compareTo(a.completionRate);
      if (compRate != 0) return compRate;
      return b.completedCount.compareTo(a.completedCount);
    });

    return result;
  }

  /// Average completion rate over all recorded history
  double get averageCompletionRate {
    if (_habits.isEmpty) return 0.0;
    final now = DateTimeUtils.dateOnly(DateTime.now());
    final thirtyDaysAgo = now.subtract(const Duration(days: 29));

    int totalScheduled = 0;
    int totalCompleted = 0;

    DateTime cursor = thirtyDaysAgo;
    while (cursor.compareTo(now) <= 0) {
      final stat = getDailyStatForDate(cursor);
      totalScheduled += stat.scheduledCount;
      totalCompleted += stat.completedCount;
      cursor = cursor.add(const Duration(days: 1));
    }

    if (totalScheduled == 0) return 0.0;
    return ((totalCompleted / totalScheduled) * 100.0).clamp(0.0, 100.0);
  }
}

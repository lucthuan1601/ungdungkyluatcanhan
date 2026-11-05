import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/habit_log_model.dart';
import '../models/habit_model.dart';

class HabitRepository {
  final DatabaseHelper _dbHelper;

  HabitRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Retrieves all active (non-archived) habits
  Future<List<HabitModel>> getAllHabits({bool includeArchived = false}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps;

    if (includeArchived) {
      maps = await db.query(
        AppConstants.habitsTable,
        orderBy: 'id DESC',
      );
    } else {
      maps = await db.query(
        AppConstants.habitsTable,
        where: 'is_archived = 0',
        orderBy: 'id DESC',
      );
    }

    return maps.map((map) => HabitModel.fromMap(map)).toList();
  }

  /// Get habit by ID
  Future<HabitModel?> getHabitById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.habitsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return HabitModel.fromMap(maps.first);
  }

  /// Inserts a new habit
  Future<int> insertHabit(HabitModel habit) async {
    final db = await _dbHelper.database;
    return await db.insert(
      AppConstants.habitsTable,
      habit.toMap(),
    );
  }

  /// Updates an existing habit
  Future<int> updateHabit(HabitModel habit) async {
    final db = await _dbHelper.database;
    return await db.update(
      AppConstants.habitsTable,
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  /// Deletes a habit by id (cascade removes corresponding logs)
  Future<int> deleteHabit(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppConstants.habitsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Toggles habit completion for a specific date:
  /// If a log exists for (habitId, dateStr), removes it; otherwise inserts it.
  Future<void> toggleHabitCompletion(int habitId, String dateStr) async {
    final db = await _dbHelper.database;
    final existing = await db.query(
      AppConstants.habitLogsTable,
      where: 'habit_id = ? AND completed_date = ?',
      whereArgs: [habitId, dateStr],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.delete(
        AppConstants.habitLogsTable,
        where: 'habit_id = ? AND completed_date = ?',
        whereArgs: [habitId, dateStr],
      );
    } else {
      await db.insert(
        AppConstants.habitLogsTable,
        {
          'habit_id': habitId,
          'completed_date': dateStr,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Check whether a habit was completed on a specific date
  Future<bool> isHabitCompletedOnDate(int habitId, String dateStr) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      AppConstants.habitLogsTable,
      where: 'habit_id = ? AND completed_date = ?',
      whereArgs: [habitId, dateStr],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Returns all logs recorded across the app
  Future<List<HabitLogModel>> getAllLogs() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.habitLogsTable,
      orderBy: 'completed_date DESC',
    );
    return maps.map((map) => HabitLogModel.fromMap(map)).toList();
  }

  /// Returns logs for a specific date ('YYYY-MM-DD')
  Future<List<HabitLogModel>> getLogsForDate(String dateStr) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.habitLogsTable,
      where: 'completed_date = ?',
      whereArgs: [dateStr],
    );
    return maps.map((map) => HabitLogModel.fromMap(map)).toList();
  }

  /// Returns all completed dates for a specific habit
  Future<List<String>> getCompletedDatesForHabit(int habitId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.habitLogsTable,
      columns: ['completed_date'],
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'completed_date ASC',
    );
    return maps.map((e) => e['completed_date'] as String).toList();
  }

  /// Retrieves raw data needed for statistical calculation
  Future<Map<String, dynamic>> getStatisticsData() async {
    final habits = await getAllHabits();
    final logs = await getAllLogs();

    return {
      'habits': habits,
      'logs': logs,
    };
  }
}

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_utils.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enforce foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Create habits table
    await db.execute('''
      CREATE TABLE ${AppConstants.habitsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        frequency_type TEXT NOT NULL,
        days_of_week TEXT NOT NULL,
        reminder_time TEXT,
        color_code INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        is_archived INTEGER DEFAULT 0
      )
    ''');

    // 2. Create habit_logs table with cascade delete & unique constraint
    await db.execute('''
      CREATE TABLE ${AppConstants.habitLogsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        completed_date TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES ${AppConstants.habitsTable}(id) ON DELETE CASCADE,
        UNIQUE(habit_id, completed_date)
      )
    ''');

    // 3. Seed initial sample habits and logs for demonstration
    await _seedSampleData(db);
  }

  Future<void> _seedSampleData(Database db) async {
    final now = DateTime.now();
    final twoWeeksAgoStr = DateTimeUtils.toIsoDateString(
      now.subtract(const Duration(days: 14)),
    );

    // Habit 1: Chạy bộ buổi sáng (Daily)
    final habit1Id = await db.insert(AppConstants.habitsTable, {
      'title': 'Chạy bộ 30 phút buổi sáng',
      'description': 'Nâng cao thể lực và sức bền tim mạch',
      'frequency_type': AppConstants.freqDaily,
      'days_of_week': '1,2,3,4,5,6,7',
      'reminder_time': '06:30',
      'color_code': 0xFF059669, // Emerald
      'created_at': twoWeeksAgoStr,
      'is_archived': 0,
    });

    // Habit 2: Đọc sách 20 trang (Daily)
    final habit2Id = await db.insert(AppConstants.habitsTable, {
      'title': 'Đọc sách 20 trang phát triển bản thân',
      'description': 'Mỗi ngày tích lũy thêm kiến thức mới',
      'frequency_type': AppConstants.freqDaily,
      'days_of_week': '1,2,3,4,5,6,7',
      'reminder_time': '21:30',
      'color_code': 0xFF4F46E5, // Indigo
      'created_at': twoWeeksAgoStr,
      'is_archived': 0,
    });

    // Habit 3: Uống đủ 2L nước (Daily)
    final habit3Id = await db.insert(AppConstants.habitsTable, {
      'title': 'Uống đủ 2 lít nước',
      'description': 'Thanh lọc cơ thể và duy trì độ ẩm',
      'frequency_type': AppConstants.freqDaily,
      'days_of_week': '1,2,3,4,5,6,7',
      'reminder_time': '08:00',
      'color_code': 0xFF0284C7, // Sky Blue
      'created_at': twoWeeksAgoStr,
      'is_archived': 0,
    });

    // Habit 4: Học lập trình Flutter (Custom: T2 - T6)
    final habit4Id = await db.insert(AppConstants.habitsTable, {
      'title': 'Học lập trình Flutter',
      'description': 'Luyện tập Clean Architecture và UI/UX',
      'frequency_type': AppConstants.freqCustom,
      'days_of_week': '1,2,3,4,5',
      'reminder_time': '20:00',
      'color_code': 0xFF9333EA, // Purple
      'created_at': twoWeeksAgoStr,
      'is_archived': 0,
    });

    // Seed logs for the past 6 days up to today
    final sampleLogs = <Map<String, dynamic>>[];

    // Habit 1: completed past 5 consecutive days (days 5, 4, 3, 2, 1 ago)
    for (int i = 1; i <= 5; i++) {
      final dateStr = DateTimeUtils.toIsoDateString(
        now.subtract(Duration(days: i)),
      );
      sampleLogs.add({'habit_id': habit1Id, 'completed_date': dateStr});
    }

    // Habit 2: completed past 6 days and today
    for (int i = 0; i <= 6; i++) {
      final dateStr = DateTimeUtils.toIsoDateString(
        now.subtract(Duration(days: i)),
      );
      sampleLogs.add({'habit_id': habit2Id, 'completed_date': dateStr});
    }

    // Habit 3: completed days 1, 2, 3 ago and today
    for (int i in [0, 1, 2, 3]) {
      final dateStr = DateTimeUtils.toIsoDateString(
        now.subtract(Duration(days: i)),
      );
      sampleLogs.add({'habit_id': habit3Id, 'completed_date': dateStr});
    }

    // Habit 4: completed on weekdays during past week
    for (int i = 1; i <= 6; i++) {
      final day = now.subtract(Duration(days: i));
      if (day.weekday <= 5) {
        sampleLogs.add({
          'habit_id': habit4Id,
          'completed_date': DateTimeUtils.toIsoDateString(day),
        });
      }
    }

    final batch = db.batch();
    for (final log in sampleLogs) {
      batch.insert(
        AppConstants.habitLogsTable,
        log,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Closes database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

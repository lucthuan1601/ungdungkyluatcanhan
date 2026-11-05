class AppConstants {
  AppConstants._();

  static const String appName = 'Kỷ Luật Cá Nhân';
  static const String appTagline = 'Theo dõi thói quen & Rèn luyện kỷ luật';

  // Shared Preferences keys
  static const String prefThemeKey = 'is_dark_mode';
  static const String prefFirstRunKey = 'is_first_run';

  // Database
  static const String dbName = 'personal_discipline.db';
  static const int dbVersion = 1;
  static const String habitsTable = 'habits';
  static const String habitLogsTable = 'habit_logs';

  // Frequency
  static const String freqDaily = 'daily';
  static const String freqCustom = 'custom';

  // Weekday Labels (1 = Monday to 7 = Sunday)
  static const Map<int, String> weekdayNames = {
    1: 'Thứ Hai',
    2: 'Thứ Ba',
    3: 'Thứ Tư',
    4: 'Thứ Năm',
    5: 'Thứ Sáu',
    6: 'Thứ Bảy',
    7: 'Chủ Nhật',
  };

  static const Map<int, String> weekdayShortNames = {
    1: 'T2',
    2: 'T3',
    3: 'T4',
    4: 'T5',
    5: 'T6',
    6: 'T7',
    7: 'CN',
  };
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kyluatcanhan/core/constants/app_constants.dart';
import 'package:kyluatcanhan/core/utils/date_time_utils.dart';
import 'package:kyluatcanhan/data/models/habit_log_model.dart';
import 'package:kyluatcanhan/data/models/habit_model.dart';

void main() {
  group('HabitModel & Scheduling Tests', () {
    test('Daily habit is scheduled for all days on or after createdAt', () {
      final habit = HabitModel(
        id: 1,
        title: 'Tập thể dục',
        frequencyType: AppConstants.freqDaily,
        daysOfWeek: '1,2,3,4,5,6,7',
        colorCode: 0xFF4F46E5,
        createdAt: '2026-11-01',
      );

      // Date before creation: should not be scheduled
      final beforeCreation = DateTime(2026, 10, 31);
      expect(habit.isScheduledForDate(beforeCreation), isFalse);

      // Date after creation: should be scheduled
      final onCreation = DateTime(2026, 11, 1);
      expect(habit.isScheduledForDate(onCreation), isTrue);

      final nextWeek = DateTime(2026, 11, 8);
      expect(habit.isScheduledForDate(nextWeek), isTrue);
    });

    test('Custom habit is scheduled only on selected weekdays', () {
      // Monday = 1, Wednesday = 3, Friday = 5
      final habit = HabitModel(
        id: 2,
        title: 'Học bơi',
        frequencyType: AppConstants.freqCustom,
        daysOfWeek: '1,3,5',
        colorCode: 0xFF059669,
        createdAt: '2026-11-01',
      );

      // 2026-11-02 is Monday (weekday = 1)
      final monday = DateTime(2026, 11, 2);
      expect(monday.weekday, 1);
      expect(habit.isScheduledForDate(monday), isTrue);

      // 2026-11-03 is Tuesday (weekday = 2)
      final tuesday = DateTime(2026, 11, 3);
      expect(tuesday.weekday, 2);
      expect(habit.isScheduledForDate(tuesday), isFalse);

      // 2026-11-04 is Wednesday (weekday = 3)
      final wednesday = DateTime(2026, 11, 4);
      expect(wednesday.weekday, 3);
      expect(habit.isScheduledForDate(wednesday), isTrue);
    });

    test('Archived habit is not scheduled for any date', () {
      final habit = HabitModel(
        id: 3,
        title: 'Thói quen cũ',
        frequencyType: AppConstants.freqDaily,
        daysOfWeek: '1,2,3,4,5,6,7',
        colorCode: 0xFF9333EA,
        createdAt: '2026-11-01',
        isArchived: 1,
      );

      final today = DateTime(2026, 11, 5);
      expect(habit.isScheduledForDate(today), isFalse);
    });
  });

  group('Model Serialization Tests', () {
    test('HabitModel toMap and fromMap are symmetrical', () {
      final original = HabitModel(
        id: 10,
        title: 'Đọc sách 30 phút',
        description: 'Phát triển bản thân',
        frequencyType: AppConstants.freqDaily,
        daysOfWeek: '1,2,3,4,5,6,7',
        reminderTime: '21:30',
        colorCode: 0xFF0D9488,
        createdAt: '2026-11-01',
        isArchived: 0,
      );

      final map = original.toMap();
      final restored = HabitModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.frequencyType, original.frequencyType);
      expect(restored.daysOfWeek, original.daysOfWeek);
      expect(restored.reminderTime, original.reminderTime);
      expect(restored.colorCode, original.colorCode);
      expect(restored.createdAt, original.createdAt);
      expect(restored.isArchived, original.isArchived);
    });

    test('HabitLogModel toMap and fromMap are symmetrical', () {
      const log = HabitLogModel(
        id: 5,
        habitId: 10,
        completedDate: '2026-11-05',
      );

      final map = log.toMap();
      final restored = HabitLogModel.fromMap(map);

      expect(restored.id, log.id);
      expect(restored.habitId, log.habitId);
      expect(restored.completedDate, log.completedDate);
    });
  });

  group('Mathematical Formula & Edge Cases', () {
    test('Daily rate handles division by zero when 0 scheduled habits', () {
      final scheduledCount = 0;
      final completedCount = 0;

      final double rate = scheduledCount == 0
          ? 0.0
          : (completedCount / scheduledCount) * 100.0;

      expect(rate, 0.0);
      expect(rate.isNaN, isFalse);
      expect(rate.isInfinite, isFalse);
    });

    test('Daily rate computes accurate percentage when scheduled > 0', () {
      final scheduledCount = 4;
      final completedCount = 3;

      final double rate = (completedCount / scheduledCount) * 100.0;
      expect(rate, 75.0);
    });

    test('DateTimeUtils getWeekDays returns 7 days starting from Monday', () {
      final refDate = DateTime(2026, 11, 5); // Thursday
      final weekDays = DateTimeUtils.getWeekDays(refDate);

      expect(weekDays.length, 7);
      expect(weekDays[0].weekday, DateTime.monday);
      expect(weekDays[6].weekday, DateTime.sunday);
    });
  });
}

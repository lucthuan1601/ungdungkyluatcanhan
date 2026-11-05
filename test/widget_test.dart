import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyluatcanhan/core/constants/app_constants.dart';
import 'package:kyluatcanhan/data/models/habit_model.dart';
import 'package:kyluatcanhan/ui/widgets/habit_card.dart';

void main() {
  testWidgets('HabitCard displays title, streak and triggers callback', (
    WidgetTester tester,
  ) async {
    final habit = HabitModel(
      id: 1,
      title: 'Đọc sách 30 phút',
      description: 'Kiến thức là sức mạnh',
      frequencyType: AppConstants.freqDaily,
      daysOfWeek: '1,2,3,4,5,6,7',
      reminderTime: '21:30',
      colorCode: 0xFF4F46E5,
      createdAt: '2026-11-01',
    );

    bool toggled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HabitCard(
            habit: habit,
            isCompleted: false,
            streak: 5,
            onToggle: () => toggled = true,
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    // Verify title and description are rendered
    expect(find.text('Đọc sách 30 phút'), findsOneWidget);
    expect(find.text('Kiến thức là sức mạnh'), findsOneWidget);

    // Verify streak badge is shown
    expect(find.text('5'), findsOneWidget);

    // Tap check-in button
    await tester.tap(find.byType(GestureDetector).last);
    await tester.pump();

    expect(toggled, isTrue);
  });
}

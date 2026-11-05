class HabitLogModel {
  final int? id;
  final int habitId;
  final String completedDate; // 'YYYY-MM-DD'

  const HabitLogModel({
    this.id,
    required this.habitId,
    required this.completedDate,
  });

  HabitLogModel copyWith({
    int? id,
    int? habitId,
    String? completedDate,
  }) {
    return HabitLogModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'habit_id': habitId,
      'completed_date': completedDate,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory HabitLogModel.fromMap(Map<String, dynamic> map) {
    return HabitLogModel(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      completedDate: map['completed_date'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLogModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          habitId == other.habitId &&
          completedDate == other.completedDate;

  @override
  int get hashCode => id.hashCode ^ habitId.hashCode ^ completedDate.hashCode;
}

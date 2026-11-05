class HabitModel {
  final int? id;
  final String title;
  final String? description;
  final String frequencyType; // 'daily' or 'custom'
  final String daysOfWeek; // '1,2,3,4,5,6,7'
  final String? reminderTime; // 'HH:mm'
  final int colorCode; // 0xFF4F46E5
  final String createdAt; // 'YYYY-MM-DD'
  final int isArchived; // 0 = active, 1 = archived

  const HabitModel({
    this.id,
    required this.title,
    this.description,
    required this.frequencyType,
    required this.daysOfWeek,
    this.reminderTime,
    required this.colorCode,
    required this.createdAt,
    this.isArchived = 0,
  });

  /// Parse daysOfWeek string into a list of integer weekdays (1 = Monday, 7 = Sunday)
  List<int> get scheduledWeekdays {
    if (daysOfWeek.isEmpty) return [];
    return daysOfWeek
        .split(',')
        .where((e) => e.isNotEmpty)
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList();
  }

  /// Checks if this habit is scheduled to be performed on a given date
  bool isScheduledForDate(DateTime date) {
    if (isArchived == 1) return false;

    // The habit only applies from its creation date onwards
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (createdAt.compareTo(dateStr) > 0) {
      return false;
    }

    return scheduledWeekdays.contains(date.weekday);
  }

  HabitModel copyWith({
    int? id,
    String? title,
    String? description,
    String? frequencyType,
    String? daysOfWeek,
    String? reminderTime,
    int? colorCode,
    String? createdAt,
    int? isArchived,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      frequencyType: frequencyType ?? this.frequencyType,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      reminderTime: reminderTime ?? this.reminderTime,
      colorCode: colorCode ?? this.colorCode,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'frequency_type': frequencyType,
      'days_of_week': daysOfWeek,
      'reminder_time': reminderTime,
      'color_code': colorCode,
      'created_at': createdAt,
      'is_archived': isArchived,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      frequencyType: map['frequency_type'] as String,
      daysOfWeek: map['days_of_week'] as String,
      reminderTime: map['reminder_time'] as String?,
      colorCode: map['color_code'] as int,
      createdAt: map['created_at'] as String,
      isArchived: (map['is_archived'] as int?) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          frequencyType == other.frequencyType &&
          daysOfWeek == other.daysOfWeek &&
          reminderTime == other.reminderTime &&
          colorCode == other.colorCode &&
          createdAt == other.createdAt &&
          isArchived == other.isArchived;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      frequencyType.hashCode ^
      daysOfWeek.hashCode ^
      reminderTime.hashCode ^
      colorCode.hashCode ^
      createdAt.hashCode ^
      isArchived.hashCode;
}

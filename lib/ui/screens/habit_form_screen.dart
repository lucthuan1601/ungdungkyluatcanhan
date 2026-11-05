import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habit_provider.dart';

class HabitFormScreen extends StatefulWidget {
  final HabitModel? habit;

  const HabitFormScreen({super.key, this.habit});

  bool get isEdit => habit != null;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late String _frequencyType;
  late Set<int> _selectedDays;
  late int _selectedColorCode;

  bool _hasReminder = false;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    if (h != null) {
      _titleController = TextEditingController(text: h.title);
      _descriptionController = TextEditingController(text: h.description ?? '');
      _frequencyType = h.frequencyType;
      _selectedDays = h.scheduledWeekdays.toSet();
      _selectedColorCode = h.colorCode;

      if (h.reminderTime != null && h.reminderTime!.isNotEmpty) {
        _hasReminder = true;
        _reminderTime = DateTimeUtils.parseTimeString(h.reminderTime);
      } else {
        _hasReminder = false;
        _reminderTime = const TimeOfDay(hour: 7, minute: 30);
      }
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _frequencyType = AppConstants.freqDaily;
      _selectedDays = {1, 2, 3, 4, 5, 6, 7};
      _selectedColorCode = AppColors.habitColorPresets.first;
      _hasReminder = false;
      _reminderTime = const TimeOfDay(hour: 7, minute: 30);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final initial = _reminderTime ?? const TimeOfDay(hour: 7, minute: 30);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'CHỌN GIỜ NHẮC NHỞ',
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_frequencyType == AppConstants.freqCustom && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 ngày trong tuần!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final provider = context.read<HabitProvider>();
    final daysSorted = (_frequencyType == AppConstants.freqDaily)
        ? '1,2,3,4,5,6,7'
        : (_selectedDays.toList()..sort()).join(',');

    final reminderStr =
        _hasReminder && _reminderTime != null
            ? DateTimeUtils.formatTimeOfDay(_reminderTime!)
            : null;

    final todayStr = DateTimeUtils.toIsoDateString(DateTime.now());

    if (widget.isEdit) {
      final updated = widget.habit!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        frequencyType: _frequencyType,
        daysOfWeek: daysSorted,
        reminderTime: reminderStr,
        colorCode: _selectedColorCode,
      );
      await provider.updateHabit(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thói quen thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      final newHabit = HabitModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        frequencyType: _frequencyType,
        daysOfWeek: daysSorted,
        reminderTime: reminderStr,
        colorCode: _selectedColorCode,
        createdAt: todayStr,
      );
      await provider.addHabit(newHabit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo thói quen mới thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Chỉnh sửa thói quen' : 'Tạo thói quen mới',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _onSave,
            icon: const Icon(Icons.check_rounded, color: AppColors.primary),
            label: const Text(
              'Lưu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 1. Tên thói quen
            Text(
              'Tên thói quen *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              maxLength: 50,
              decoration: const InputDecoration(
                hintText: 'VD: Đọc sách 30 phút, Chạy bộ...',
                prefixIcon: Icon(Icons.flag_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên thói quen';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 2. Mô tả chi tiết
            Text(
              'Mô tả / Động lực thực hiện',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Lý do bạn muốn duy trì thói quen này hàng ngày...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // 3. Tần suất thực hiện
            Text(
              'Tần suất lặp lại *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: AppConstants.freqDaily,
                  label: Text('Hàng ngày'),
                  icon: Icon(Icons.calendar_month_rounded),
                ),
                ButtonSegment(
                  value: AppConstants.freqCustom,
                  label: Text('Tùy chỉnh'),
                  icon: Icon(Icons.tune_rounded),
                ),
              ],
              selected: {_frequencyType},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _frequencyType = newSelection.first;
                  if (_frequencyType == AppConstants.freqDaily) {
                    _selectedDays = {1, 2, 3, 4, 5, 6, 7};
                  }
                });
              },
            ),

            if (_frequencyType == AppConstants.freqCustom) ...[
              const SizedBox(height: 14),
              Text(
                'Chọn các ngày trong tuần:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final dayNumber = index + 1; // 1 to 7
                  final isSelected = _selectedDays.contains(dayNumber);
                  return FilterChip(
                    label: Text(DateTimeUtils.getWeekdayShortName(dayNumber)),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withAlpha(50),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(dayNumber);
                        } else {
                          if (_selectedDays.length > 1) {
                            _selectedDays.remove(dayNumber);
                          }
                        }
                      });
                    },
                  );
                }),
              ),
            ],
            const SizedBox(height: 24),

            // 4. Thời gian nhắc nhở
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Nhắc nhở hàng ngày',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _hasReminder
                          ? 'Đã bật nhắc nhở lúc ${_reminderTime != null ? DateTimeUtils.formatTimeOfDay(_reminderTime!) : "07:30"}'
                          : 'Tắt nhắc nhở',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    value: _hasReminder,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _hasReminder = val;
                      });
                    },
                  ),
                  if (_hasReminder) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.access_time_filled_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text('Giờ nhắc nhở'),
                      trailing: FilledButton.tonal(
                        onPressed: _pickReminderTime,
                        child: Text(
                          _reminderTime != null
                              ? DateTimeUtils.formatTimeOfDay(_reminderTime!)
                              : '07:30',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Chọn màu sắc nhận diện
            Text(
              'Màu sắc nhận diện',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppColors.habitColorPresets.map((code) {
                final isSelected = _selectedColorCode == code;
                final color = Color(code);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColorCode = code;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(isSelected ? 160 : 70),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            // Nút Lưu
            FilledButton.icon(
              onPressed: _onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: Text(
                widget.isEdit ? 'Cập nhật thói quen' : 'Lưu thói quen',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

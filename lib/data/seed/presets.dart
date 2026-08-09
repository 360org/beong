import 'package:meta/meta.dart';

/// Preset task — việc có sẵn để chọn nhanh khi tạo task.
///
/// 24 mục theo spec §4.1. Icon key trỏ vào bộ icon dựng sẵn trong app.
@immutable
class TaskPreset {
  const TaskPreset({
    required this.key,
    required this.titleVi,
    required this.titleEn,
    required this.iconKey,
    required this.defaultPoints,
    this.dayPart,
  });

  final String key;
  final String titleVi;
  final String titleEn;
  final String iconKey;
  final int defaultPoints;
  final String? dayPart;
}

const kTaskPresets = <TaskPreset>[
  // --- Buổi sáng ---
  TaskPreset(
    key: 'brush_teeth_morning',
    titleVi: 'Đánh răng buổi sáng',
    titleEn: 'Brush teeth (morning)',
    iconKey: 'tooth',
    defaultPoints: 10,
    dayPart: 'morning',
  ),
  TaskPreset(
    key: 'make_bed',
    titleVi: 'Gấp chăn màn',
    titleEn: 'Make bed',
    iconKey: 'bed',
    defaultPoints: 10,
    dayPart: 'morning',
  ),
  TaskPreset(
    key: 'get_dressed',
    titleVi: 'Mặc quần áo',
    titleEn: 'Get dressed',
    iconKey: 'shirt',
    defaultPoints: 5,
    dayPart: 'morning',
  ),
  TaskPreset(
    key: 'eat_breakfast',
    titleVi: 'Ăn sáng',
    titleEn: 'Eat breakfast',
    iconKey: 'food',
    defaultPoints: 10,
    dayPart: 'morning',
  ),
  TaskPreset(
    key: 'pack_school_bag',
    titleVi: 'Soạn cặp sách',
    titleEn: 'Pack school bag',
    iconKey: 'backpack',
    defaultPoints: 10,
    dayPart: 'morning',
  ),

  // --- Buổi chiều ---
  TaskPreset(
    key: 'homework',
    titleVi: 'Làm bài tập',
    titleEn: 'Do homework',
    iconKey: 'pencil',
    defaultPoints: 25,
    dayPart: 'afternoon',
  ),
  TaskPreset(
    key: 'read_book',
    titleVi: 'Đọc sách 15 phút',
    titleEn: 'Read for 15 minutes',
    iconKey: 'book',
    defaultPoints: 15,
    dayPart: 'afternoon',
  ),
  TaskPreset(
    key: 'practice_music',
    titleVi: 'Tập nhạc',
    titleEn: 'Practice music',
    iconKey: 'music',
    defaultPoints: 20,
    dayPart: 'afternoon',
  ),
  TaskPreset(
    key: 'tidy_room',
    titleVi: 'Dọn phòng',
    titleEn: 'Tidy up room',
    iconKey: 'broom',
    defaultPoints: 15,
    dayPart: 'afternoon',
  ),

  // --- Buổi tối ---
  TaskPreset(
    key: 'brush_teeth_evening',
    titleVi: 'Đánh răng buổi tối',
    titleEn: 'Brush teeth (evening)',
    iconKey: 'tooth',
    defaultPoints: 10,
    dayPart: 'evening',
  ),
  TaskPreset(
    key: 'shower',
    titleVi: 'Tắm rửa',
    titleEn: 'Take a shower',
    iconKey: 'shower',
    defaultPoints: 10,
    dayPart: 'evening',
  ),
  TaskPreset(
    key: 'pajamas',
    titleVi: 'Mặc đồ ngủ',
    titleEn: 'Put on pajamas',
    iconKey: 'moon',
    defaultPoints: 5,
    dayPart: 'evening',
  ),
  TaskPreset(
    key: 'prepare_tomorrow',
    titleVi: 'Chuẩn bị quần áo ngày mai',
    titleEn: 'Prepare clothes for tomorrow',
    iconKey: 'hanger',
    defaultPoints: 10,
    dayPart: 'evening',
  ),

  // --- Việc nhà ---
  TaskPreset(
    key: 'wash_dishes',
    titleVi: 'Rửa bát',
    titleEn: 'Wash dishes',
    iconKey: 'dish',
    defaultPoints: 20,
  ),
  TaskPreset(
    key: 'set_table',
    titleVi: 'Dọn bàn ăn',
    titleEn: 'Set the table',
    iconKey: 'table',
    defaultPoints: 10,
  ),
  TaskPreset(
    key: 'take_out_trash',
    titleVi: 'Đổ rác',
    titleEn: 'Take out trash',
    iconKey: 'trash',
    defaultPoints: 10,
  ),
  TaskPreset(
    key: 'sweep_floor',
    titleVi: 'Quét nhà',
    titleEn: 'Sweep the floor',
    iconKey: 'broom',
    defaultPoints: 15,
  ),
  TaskPreset(
    key: 'fold_laundry',
    titleVi: 'Gấp quần áo',
    titleEn: 'Fold laundry',
    iconKey: 'laundry',
    defaultPoints: 15,
  ),
  TaskPreset(
    key: 'water_plants',
    titleVi: 'Tưới cây',
    titleEn: 'Water plants',
    iconKey: 'plant',
    defaultPoints: 10,
  ),
  TaskPreset(
    key: 'feed_pet',
    titleVi: 'Cho thú cưng ăn',
    titleEn: 'Feed pet',
    iconKey: 'paw',
    defaultPoints: 10,
  ),
  TaskPreset(
    key: 'clean_toys',
    titleVi: 'Cất đồ chơi',
    titleEn: 'Clean up toys',
    iconKey: 'toy',
    defaultPoints: 10,
  ),

  // --- Phát triển bản thân ---
  TaskPreset(
    key: 'exercise',
    titleVi: 'Tập thể dục',
    titleEn: 'Exercise',
    iconKey: 'run',
    defaultPoints: 20,
  ),
  TaskPreset(
    key: 'be_kind',
    titleVi: 'Làm một việc tử tế',
    titleEn: 'Do something kind',
    iconKey: 'heart',
    defaultPoints: 15,
  ),
  TaskPreset(
    key: 'no_screen',
    titleVi: 'Không màn hình 1 tiếng',
    titleEn: 'No screen for 1 hour',
    iconKey: 'eye_off',
    defaultPoints: 20,
  ),
];

/// Routine dựng sẵn khi onboarding — spec §4.2.
@immutable
class RoutinePreset {
  const RoutinePreset({
    required this.key,
    required this.titleVi,
    required this.titleEn,
    required this.iconKey,
    required this.dayPart,
    required this.taskKeys,
    this.completionBonus = 10,
  });

  final String key;
  final String titleVi;
  final String titleEn;
  final String iconKey;
  final String dayPart;
  final List<String> taskKeys;
  final int completionBonus;
}

const kRoutinePresets = <RoutinePreset>[
  RoutinePreset(
    key: 'morning',
    titleVi: 'Buổi sáng',
    titleEn: 'Morning routine',
    iconKey: 'sunrise',
    dayPart: 'morning',
    taskKeys: [
      'brush_teeth_morning',
      'make_bed',
      'get_dressed',
      'eat_breakfast',
      'pack_school_bag',
    ],
  ),
  RoutinePreset(
    key: 'after_school',
    titleVi: 'Sau giờ học',
    titleEn: 'After school',
    iconKey: 'backpack',
    dayPart: 'afternoon',
    taskKeys: ['homework', 'read_book', 'tidy_room'],
  ),
  RoutinePreset(
    key: 'bedtime',
    titleVi: 'Trước khi ngủ',
    titleEn: 'Bedtime routine',
    iconKey: 'moon',
    dayPart: 'evening',
    taskKeys: [
      'brush_teeth_evening',
      'shower',
      'pajamas',
      'prepare_tomorrow',
    ],
  ),
];

/// Tìm preset theo key.
TaskPreset? presetByKey(String key) {
  for (final p in kTaskPresets) {
    if (p.key == key) return p;
  }
  return null;
}

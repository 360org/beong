import 'package:beong/domain/services/penalty_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('penaltyFor', () {
    test('trừ đúng phần trăm điểm của việc', () {
      expect(penaltyFor(taskPoints: 10, pct: 50), 5);
      expect(penaltyFor(taskPoints: 10, pct: 20), 2);
      expect(penaltyFor(taskPoints: 20, pct: 25), 5);
    });

    test('làm tròn xuống, nghiêng về phía trẻ', () {
      // 50% của 15 là 7.5 — lấy 7, không lấy 8.
      expect(penaltyFor(taskPoints: 15, pct: 50), 7);
      expect(penaltyFor(taskPoints: 10, pct: 25), 2);
      expect(penaltyFor(taskPoints: 3, pct: 20), 0);
    });

    test('mức 0 thì không trừ gì', () {
      expect(penaltyFor(taskPoints: 100, pct: 0), 0);
    });

    test('mức âm hoặc điểm âm đều ra 0, không cộng ngược', () {
      expect(penaltyFor(taskPoints: 10, pct: -50), 0);
      expect(penaltyFor(taskPoints: -10, pct: 50), 0);
    });

    test('mức trên 100 bị kẹp về 100, không trừ quá điểm việc', () {
      expect(penaltyFor(taskPoints: 10, pct: 150), 10);
    });
  });

  group('PenaltyPolicy', () {
    test('mặc định là tắt', () {
      expect(PenaltyPolicy.off.isEnabled, isFalse);
      expect(PenaltyPolicy.off.missedPct, 0);
      expect(PenaltyPolicy.off.reopenPct, 0);
    });

    test('bật một trong hai mức là đã bật', () {
      expect(
        const PenaltyPolicy(missedPct: 50, reopenPct: 0).isEnabled,
        isTrue,
      );
      expect(
        const PenaltyPolicy(missedPct: 0, reopenPct: 20).isEnabled,
        isTrue,
      );
    });

    test('chỉ nhận mức trong khoảng 0–100', () {
      expect(const PenaltyPolicy(missedPct: 50, reopenPct: 20).isValid, isTrue);
      expect(
        const PenaltyPolicy(missedPct: 101, reopenPct: 0).isValid,
        isFalse,
      );
      expect(const PenaltyPolicy(missedPct: 0, reopenPct: -1).isValid, isFalse);
    });
  });

  group('summarizeDay', () {
    const policy = PenaltyPolicy(missedPct: 50, reopenPct: 20);

    test('đúng ví dụ bố mẹ đưa ra: 10 việc, làm 8, 3 việc làm lại', () {
      // 10 việc mỗi việc 10 xu. Làm xong 8, bỏ 2. Trong 8 việc đã xong có 3
      // việc bị mở lại một lần.
      final tasks = [
        for (var i = 0; i < 3; i++)
          const DayTaskOutcome(points: 10, completed: true, reopenCount: 1),
        for (var i = 0; i < 5; i++)
          const DayTaskOutcome(points: 10, completed: true),
        for (var i = 0; i < 2; i++)
          const DayTaskOutcome(points: 10, completed: false),
      ];

      final s = summarizeDay(tasks: tasks, policy: policy);

      expect(s.earned, 80, reason: '8 việc x 10 xu');
      expect(s.missedPenalty, 10, reason: '2 việc bỏ x 50% x 10 xu');
      expect(s.reopenPenalty, 6, reason: '3 lần làm lại x 20% x 10 xu');
      expect(s.net, 64);

      // Con số cuối trong ví dụ: đang có 100 xu thì hết ngày còn 164.
      expect(100 + s.net, 164);
    });

    test('việc bị mở lại vẫn được tính xu đầy đủ khi làm xong', () {
      // Trừ cả xu kiếm được lẫn tiền phạt là trừ hai lần cho một lỗi.
      final s = summarizeDay(
        tasks: const [
          DayTaskOutcome(points: 10, completed: true, reopenCount: 1),
        ],
        policy: policy,
      );

      expect(s.earned, 10);
      expect(s.reopenPenalty, 2);
      expect(s.net, 8);
    });

    test('mở lại nhiều lần thì trừ nhiều lần', () {
      final s = summarizeDay(
        tasks: const [
          DayTaskOutcome(points: 10, completed: true, reopenCount: 3),
        ],
        policy: policy,
      );

      expect(s.reopenPenalty, 6);
    });

    test('việc bỏ mà từng bị mở lại thì chịu cả hai khoản', () {
      // Ca thật: con bấm xong, bố mẹ mở lại, con không làm nữa, hết ngày.
      final s = summarizeDay(
        tasks: const [
          DayTaskOutcome(points: 10, completed: false, reopenCount: 1),
        ],
        policy: policy,
      );

      expect(s.missedPenalty, 5);
      expect(s.reopenPenalty, 2);
      expect(s.net, -7);
    });

    test('chính sách tắt thì không trừ dù bỏ hết việc', () {
      final s = summarizeDay(
        tasks: const [
          DayTaskOutcome(points: 10, completed: false),
          DayTaskOutcome(points: 10, completed: true, reopenCount: 2),
        ],
        policy: PenaltyPolicy.off,
      );

      expect(s.totalPenalty, 0);
      expect(s.net, 10);
    });

    test('ngày không có việc nào thì không kiếm cũng không mất', () {
      final s = summarizeDay(tasks: const [], policy: policy);
      expect(
        s,
        const DayPenaltySummary(earned: 0, missedPenalty: 0, reopenPenalty: 0),
      );
    });

    test('bỏ hết việc thì ngày ròng âm', () {
      final s = summarizeDay(
        tasks: const [
          DayTaskOutcome(points: 10, completed: false),
          DayTaskOutcome(points: 10, completed: false),
        ],
        policy: policy,
      );

      expect(s.net, -10);
    });
  });
}

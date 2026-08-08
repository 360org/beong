import 'package:beong/core/theme/kid_scale.dart';
import 'package:beong/domain/services/age_band.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ageBandForAge', () {
    test('5–8 tuổi vào nhóm little', () {
      for (var age = 5; age <= 8; age++) {
        expect(ageBandForAge(age), AgeBand.little, reason: 'tuổi $age');
      }
    });

    test('9–12 tuổi vào nhóm middle', () {
      for (var age = 9; age <= 12; age++) {
        expect(ageBandForAge(age), AgeBand.middle, reason: 'tuổi $age');
      }
    });

    test('13–15 tuổi vào nhóm teen', () {
      for (var age = 13; age <= 15; age++) {
        expect(ageBandForAge(age), AgeBand.teen, reason: 'tuổi $age');
      }
    });

    test('dưới 5 tuổi vẫn kẹp về little', () {
      expect(ageBandForAge(3), AgeBand.little);
      expect(ageBandForAge(0), AgeBand.little);
    });

    test('trên 15 tuổi vẫn kẹp về teen', () {
      expect(ageBandForAge(16), AgeBand.teen);
      expect(ageBandForAge(30), AgeBand.teen);
    });

    test('mọi tuổi trong dải hỗ trợ đều có nhóm', () {
      for (var age = kMinSupportedAge; age <= kMaxSupportedAge; age++) {
        expect(() => ageBandForAge(age), returnsNormally);
      }
    });
  });

  group('ageBandFor theo năm sinh', () {
    test('tính đúng nhóm từ năm sinh', () {
      expect(
        ageBandFor(birthYear: 2019, currentYear: 2026),
        AgeBand.little, // 7 tuổi
      );
      expect(
        ageBandFor(birthYear: 2015, currentYear: 2026),
        AgeBand.middle, // 11 tuổi
      );
      expect(
        ageBandFor(birthYear: 2012, currentYear: 2026),
        AgeBand.teen, // 14 tuổi
      );
    });

    test('chưa biết năm sinh thì dùng nhóm mặc định', () {
      expect(ageBandFor(birthYear: null, currentYear: 2026), kDefaultAgeBand);
    });

    test(
      'mặc định là middle — không hạ thấp trẻ lớn, không khô với trẻ nhỏ',
      () {
        expect(kDefaultAgeBand, AgeBand.middle);
      },
    );

    test('năm sinh ở tương lai bị coi là rác, rơi về mặc định', () {
      expect(ageBandFor(birthYear: 2030, currentYear: 2026), kDefaultAgeBand);
    });

    test('năm sinh cho ra tuổi phi thực tế thì rơi về mặc định', () {
      expect(ageBandFor(birthYear: 1800, currentYear: 2026), kDefaultAgeBand);
    });

    test('ranh giới nhóm chuyển đúng khi sang năm mới', () {
      // Bé sinh 2014: 12 tuổi năm 2026 (middle), 13 tuổi năm 2027 (teen).
      expect(ageBandFor(birthYear: 2014, currentYear: 2026), AgeBand.middle);
      expect(ageBandFor(birthYear: 2014, currentYear: 2027), AgeBand.teen);
    });
  });

  group('KidScale', () {
    test('mỗi nhóm tuổi có đúng một bộ tham số', () {
      for (final band in AgeBand.values) {
        expect(KidScale.of(band).band, band, reason: band.name);
      }
    });

    test('chữ và vùng chạm nhỏ dần khi tuổi tăng', () {
      expect(
        KidScale.little.textScale,
        greaterThan(KidScale.middle.textScale),
      );
      expect(
        KidScale.middle.textScale,
        greaterThan(KidScale.teen.textScale),
      );
      expect(
        KidScale.little.tapTarget,
        greaterThan(KidScale.middle.tapTarget),
      );
      expect(
        KidScale.middle.tapTarget,
        greaterThan(KidScale.teen.tapTarget),
      );
    });

    test('vùng chạm luôn đạt tối thiểu 48dp của Material', () {
      for (final band in AgeBand.values) {
        expect(
          KidScale.of(band).tapTarget,
          greaterThanOrEqualTo(48),
          reason: band.name,
        );
      }
    });

    test('trẻ lớn không thấy linh vật và hoa giấy', () {
      expect(KidScale.teen.showMascot, isFalse);
      expect(KidScale.teen.celebrateOnTap, isFalse);
    });

    test('trẻ nhỏ thấy linh vật nhưng chưa thấy streak', () {
      expect(KidScale.little.showMascot, isTrue);
      expect(KidScale.little.celebrateOnTap, isTrue);
      expect(KidScale.little.showStreakFlame, isFalse);
    });

    test('forBirthYear đi qua đúng nhóm tuổi', () {
      expect(
        KidScale.forBirthYear(2019, currentYear: 2026),
        KidScale.little,
      );
      expect(
        KidScale.forBirthYear(null, currentYear: 2026),
        KidScale.of(kDefaultAgeBand),
      );
    });

    test('so sánh theo giá trị để scope biết khi nào cần dựng lại', () {
      expect(KidScale.of(AgeBand.little), KidScale.little);
      expect(KidScale.little == KidScale.teen, isFalse);
      expect(KidScale.little.hashCode, KidScale.of(AgeBand.little).hashCode);
    });
  });
}

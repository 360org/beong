import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/mat_khau_ho_so.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mật khẩu **của từng hồ sơ** — ADR-027.
///
/// Ba hướng sai, test này canh cả ba:
/// - **Quá lỏng**: mật khẩu của bé này mở được hồ sơ bé kia → sổ xu lẫn lộn.
/// - **Quá chặt**: máy cài từ bản cũ còn hồ sơ chưa có mật khẩu mà bị khoá →
///   app tự khoá người dùng ra khỏi dữ liệu của chính họ.
/// - **Lệch với bản cũ**: đổi cách băm thì mọi PIN đã đặt trước ADR-027 thành
///   sai hết, và không ai vào được vai bố mẹ nữa.
void main() {
  late AppDatabase db;
  late MemberDao memberDao;
  late MatKhauHoSo service;

  const familyId = 'fam-1';
  const boMe = 'bo-me-1';
  const minh = 'con-1';
  const lan = 'con-2';

  setUp(() async {
    db = AppDatabase.memory();
    memberDao = MemberDao(db);
    service = MatKhauHoSo(memberDao: memberDao);

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'),
    );
    await memberDao.addMember(
      MembersCompanion.insert(
        id: boMe,
        familyId: familyId,
        kind: MemberKind.parent.name,
        displayName: 'Bố mẹ',
      ),
    );
    for (final (id, ten) in [(minh, 'Minh'), (lan, 'Lan')]) {
      await memberDao.addMember(
        MembersCompanion.insert(
          id: id,
          familyId: familyId,
          kind: MemberKind.child.name,
          displayName: ten,
        ),
      );
    }
  });

  tearDown(() async {
    await db.close();
  });

  group('dạng mật khẩu', () {
    test('đúng bốn chữ số mới hợp lệ', () {
      expect(MatKhauHoSo.dungDinhDang('1234'), isTrue);
      expect(MatKhauHoSo.dungDinhDang('123'), isFalse);
      expect(MatKhauHoSo.dungDinhDang('12345'), isFalse);
      expect(MatKhauHoSo.dungDinhDang('12a4'), isFalse);
      expect(MatKhauHoSo.dungDinhDang(''), isFalse);
    });

    test('đặt sai dạng thì ném lỗi, không lặng lẽ lưu', () async {
      await expectLater(
        service.dat(memberId: boMe, matKhau: '12'),
        throwsArgumentError,
      );
      expect(await service.daDat(boMe), isFalse);
    });
  });

  group('mỗi hồ sơ một mật khẩu', () {
    test('đặt cho hồ sơ này không đụng hồ sơ khác', () async {
      await service.dat(memberId: minh, matKhau: '1111');

      expect(await service.daDat(minh), isTrue);
      expect(await service.daDat(lan), isFalse);
      expect(await service.daDat(boMe), isFalse);
    });

    test('mật khẩu của bé này KHÔNG mở được hồ sơ bé kia', () async {
      // Đây là điều ADR-027 đổi so với bản cũ: trước là một PIN chung cả nhà,
      // nên bất kỳ mật khẩu đúng nào cũng mở được mọi thứ nó canh.
      await service.dat(memberId: minh, matKhau: '1111');
      await service.dat(memberId: lan, matKhau: '2222');

      expect(await service.dung(memberId: minh, matKhau: '1111'), isTrue);
      expect(await service.dung(memberId: minh, matKhau: '2222'), isFalse);
      expect(await service.dung(memberId: lan, matKhau: '2222'), isTrue);
      expect(await service.dung(memberId: lan, matKhau: '1111'), isFalse);
    });

    test('đổi mật khẩu thì mật khẩu cũ hết dùng được', () async {
      await service.dat(memberId: boMe, matKhau: '1357');
      await service.dat(memberId: boMe, matKhau: '2468');

      expect(await service.dung(memberId: boMe, matKhau: '1357'), isFalse);
      expect(await service.dung(memberId: boMe, matKhau: '2468'), isTrue);
    });
  });

  group('hồ sơ chưa đặt mật khẩu', () {
    test('cho vào, không khoá cứng', () async {
      // Máy cài từ bản trước ADR-027 còn nguyên loại hồ sơ này. Trả `false` ở
      // đây là khoá người dùng ra khỏi dữ liệu của chính họ vì một quy tắc vừa
      // ra đời — luồng vào app chịu trách nhiệm bắt đặt ngay sau khi cho vào.
      expect(await service.dung(memberId: minh, matKhau: '0000'), isTrue);
      expect(await service.dung(memberId: minh, matKhau: '9999'), isTrue);
    });

    test('`chuaDat` liệt kê đúng những hồ sơ còn nợ', () async {
      expect(
        (await service.chuaDat(familyId)).map((m) => m.id),
        unorderedEquals(<String>[boMe, minh, lan]),
      );

      await service.dat(memberId: boMe, matKhau: '1357');
      await service.dat(memberId: minh, matKhau: '1111');

      expect((await service.chuaDat(familyId)).map((m) => m.id), [lan]);
    });
  });

  test('cách băm không đổi so với bản trước ADR-027', () {
    // Đổi tiền tố hay thêm muối là làm mọi PIN đã đặt trên máy người dùng thành
    // sai hết — và họ không có cách nào biết vì sao, vì mật khẩu họ nhớ vẫn
    // đúng. Giá trị dưới đây là sha256('beong-pin:1357') — cùng tiền tố bản cũ
    // dùng — cố ý viết cứng để đổi cách băm là test đỏ ngay.
    expect(
      MatKhauHoSo.bam('1357'),
      '5ce5ef7cb433fff6a0c387620bc8657d97d8a3462ca40798a55adb70047376f3',
    );
  });
}

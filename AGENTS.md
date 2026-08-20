# Project Guidelines (FLUTTER)

> File do AIaC tạo. Quy tắc global được kế thừa từ Global AGENTS.md.

## Quy tắc cục bộ
- Kế thừa Global AGENTS.md; không lặp hoặc ghi đè các rule global.
- Chỉ sửa cấu hình `.Codex/` do AIaC tạo; giữ nguyên file cục bộ có sẵn.
- Tránh bang operator (`!`); kiểm tra `context.mounted` sau `await`.
- Chạy `flutter analyze` trước khi xác nhận.

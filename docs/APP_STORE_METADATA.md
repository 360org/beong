# Tài Liệu Toàn Diện: Khai Báo App Store Connect — Bé Ong (net.beong.app)

Tài liệu này tổng hợp toàn bộ các trường thông tin, câu trả lời bản câu hỏi phân loại và nội dung metadata đã được chuẩn bị đầy đủ cho việc nộp duyệt trên **App Store Connect** và tự động hóa qua **Fastlane**.

Đường dẫn tệp cấu hình Fastlane tự động:
- Metadata tiếng Việt: `/Volumes/DATA/DEV/MOBILES/beong/ios/fastlane/metadata/vi/`
- Metadata tiếng Anh (en-US): `/Volumes/DATA/DEV/MOBILES/beong/ios/fastlane/metadata/en-US/`
- Thông tin kiểm duyệt (App Review Information): `/Volumes/DATA/DEV/MOBILES/beong/ios/fastlane/metadata/review_information/`
- Ảnh chụp màn hình chuẩn 6.7" (1284×2778): `/Volumes/DATA/DEV/MOBILES/beong/ios/fastlane/screenshots/`

---

## 1. Thông Tin Chung (App Information)

| Trường thông tin | Giá trị khai báo |
|---|---|
| **App Name (Tên ứng dụng)** | `Bé Ong — Con Tự Lập, Tích Xu` (vi) / `Bé Ong — Kids Habits & Chores` (en) |
| **Subtitle (Phụ đề)** | `Bé Tự Lập & Nuôi Dưỡng Thói Quen` (vi) / `Independent Kids & Smart Habits` (en) |
| **Bundle ID** | `net.beong.app` |
| **SKU** | `BEONG_IOS_APP` |
| **Primary Category** | `Education` (Giáo dục) |
| **Secondary Category** | `Lifestyle` (Phong cách sống) |
| **Copyright** | `2026 360 CORP` |
| **Privacy Policy URL** | `https://beong.net/quyen-rieng-tu.html` |
| **Support URL** | `https://beong.net/gioi-thieu.html` |
| **Marketing URL** | `https://beong.net/` |

---

## 2. Phân Loại Độ Tuổi & Kids Category (Age Rating & Kids)

Bảng câu hỏi phân loại nội dung của Apple (**Content Rating**):

| Mục đánh giá | Câu trả lời |
|---|---|
| Violence (Bạo lực) | **None** (Không) |
| Cartoon/Fantasy Violence (Bạo lực hoạt hình) | **None** (Không) |
| Realistic Violence (Bạo lực chân thực) | **None** (Không) |
| Profanity or Crude Humor (Ngôn từ thô tục) | **None** (Không) |
| Mature/Suggestive Themes (Chủ đề người lớn) | **None** (Không) |
| Horror/Fear Themes (Kinh dị/Sợ hãi) | **None** (Không) |
| Medical/Treatment Information (Thông tin y tế) | **None** (Không) |
| Alcohol, Tobacco, or Drug Use (Rượu, bia, thuốc lá) | **None** (Không) |
| Simulated Gambling (Cờ bạc mô phỏng) | **None** (Không) |
| Sexual Content or Nudity (Nội dung khiêu dâm) | **None** (Không) |
| Unrestricted Web Access (Trình duyệt web không hạn chế) | **No** (Không) |
| Gambling and Contests (Cá cược thực tế) | **No** (Không) |
| **Kết quả Phân loại Tuổi (Age Rating)** | **4+** (Phù hợp mọi lứa tuổi) |
| **Made for Kids (Chuyên mục Trẻ em)** | **Yes (Bật)** → Chọn lứa tuổi: **Ages 6–8** & **Ages 9–11** |

---

## 3. Khai Báo Quyền Riêng Tư (App Privacy / Data Safety)

Apple yêu cầu khai báo chi tiết việc thu thập dữ liệu (App Privacy Details):

1. **Does the app collect data? (Ứng dụng có thu thập dữ liệu không?)**:
   - Khai báo: **Yes** (Chỉ thu thập dữ liệu chẩn đoán khi người dùng chủ động bấm gửi Báo lỗi).
2. **Loại dữ liệu (Data Types)**:
   - Chọn mục: **Diagnostics (Chẩn đoán)** ➔ Tích chọn: **Crash Data** và **Performance Data / Other Diagnostic Data**.
3. **Mục đích sử dụng (Usage Purpose)**:
   - **App Functionality (Chức năng ứng dụng)**.
4. **Liên kết danh tính (Linked to User Identity)**:
   - Chọn: **No** (Dữ liệu chẩn đoán không liên kết với danh tính người dùng).
5. **Theo dõi người dùng (Tracking)**:
   - Chọn: **No** (Ứng dụng không sử dụng dữ liệu để theo dõi người dùng trên các ứng dụng/trang web khác).

---

## 4. Giá & Khả Dụng (Pricing and Availability)

| Trường thông tin | Giá trị |
|---|---|
| **Price (Giá)** | **Free** ($0.00 / 0 VNĐ) — Hoàn toàn miễn phí |
| **In-App Purchases (Mua hàng trong app)** | **Không có** |
| **Advertisements (Quảng cáo)** | **Không có** |
| **Availability (Vùng khả dụng)** | **All countries and regions** (Mặc định toàn cầu, ưu tiên Việt Nam) |

---

## 5. Khai Báo Pháp Lý & Bản Quyền (Legal & Compliance)

- **Content Rights Declaration**:
  - *"Does your app contain, display, or access third-party content?"* ➔ Chọn **No** (Toàn bộ tài nguyên icon, hình ảnh, mã nguồn thuộc sở hữu của 360 CORP hoặc giấy phép MIT mã nguồn mở đi kèm).
- **Export Compliance (Mã hóa xuất khẩu)**:
  - *"Does your app use encryption?"* ➔ Chọn **Yes**, sau đó chọn **Exempt** (Sử dụng tiêu chuẩn HTTPS/TLS thông thường của hệ điều hành, được miễn trừ theo quy định EAR).

---

## 6. Thông Tin Liên Hệ Kiểm Duyệt (App Review Information)

| Trường thông tin | Giá trị |
|---|---|
| **Contact First Name** | `Chau` |
| **Contact Last Name** | `Le` |
| **Contact Email** | `support@360.org.vn` |
| **Contact Phone** | `+84988888888` |
| **Sign-in Required (Đăng nhập)** | **No (Không tích chọn)** — App chạy hoàn toàn Offline, không cần tài khoản hay server bên ngoài. |
| **Demo Notes (Ghi chú cho Reviewer)** | *(Đã tạo sẵn trong `ios/fastlane/metadata/review_information/notes.txt`)* |

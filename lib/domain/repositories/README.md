# Tầng repository

## Vì sao có tầng này

Hôm nay app chỉ đọc ghi một nơi: file SQLite trên máy. Câu hỏi "đọc ở đâu" chưa
tồn tại, nên tầng này trông như thừa.

Sprint 3 thêm đồng bộ nhiều máy, và lúc đó câu hỏi thành thật: một màn hình cần
số dư xu thì đọc bản local (nhanh, luôn có, có thể cũ) hay chờ máy chủ (đúng
nhất, có thể không tới)? Ghi một thao tác thì ghi thẳng hay bỏ vào outbox rồi
đẩy sau? Nếu tới lúc đó UI vẫn gọi thẳng DAO thì câu trả lời phải rải ra **53
chỗ gọi trong `lib/features`**, mỗi chỗ một kiểu.

Tầng này là chỗ duy nhất trả lời câu hỏi đó.

## Mặt cắt lấy từ đâu

**Không** bọc lại toàn bộ DAO. Tám DAO có tổng cộng 244 phương thức công khai;
chuyển tiếp hết là khoảng 2.500 dòng không thêm khả năng nào — đó là nghi thức,
không phải kiến trúc, và nó còn làm chính tầng này mất nghĩa vì không ai nhìn ra
đâu là chỗ cần quan tâm khi thêm sync.

Mặt cắt ở đây lấy đúng bằng **những gì `lib/features` thật sự gọi**: 65 phương
thức. Tiêu chí này khách quan và tự kiểm được:

```bash
# liệt kê phương thức mà tầng UI đang gọi qua provider
grep -rhoE "(read|watch)\(\w+DaoProvider\)\.[a-zA-Z_]+" lib/features/ \
  | sed 's/.*\.//' | sort -u
```

Danh sách đó phải khớp với các interface trong thư mục này. Lệch nghĩa là hoặc UI
vừa mọc thêm một đường đi tắt, hoặc repository còn phương thức không ai dùng.

## Quy tắc

1. **`lib/features` không import `lib/data`.** Có test tự động canh
   (`test/unit/kien_truc_test.dart`). Đây là ràng buộc thật của tầng này; bỏ nó
   thì mọi thứ còn lại chỉ là đặt tên.
2. **Service (`lib/domain/services`) vẫn được gọi thẳng DAO.** Chúng nằm cùng
   tầng nghiệp vụ và cần thao tác trong cùng transaction — ép qua repository ở
   đây sẽ phải mở lại chính những API mà repository đang giấu đi.
3. Interface đặt tên theo nghiệp vụ, không theo bảng.

## Còn thiếu, cố ý

Repository hiện trả về **kiểu hàng của Drift** (`Member`, `TaskInstance`, …) chứ
không phải entity riêng của domain. Tách entity là việc thật, nhưng làm bây giờ
thì phải viết mapper cho 12 bảng để đổi lấy đúng con số không lợi ích — hôm nay
chỉ có một nguồn dữ liệu nên kiểu của nó không thể "rò" sang chỗ khác được.

Làm việc đó cùng lúc với sync, khi đã có nguồn thứ hai và kiểu của nó **thật sự**
khác. Ghi ở đây để lần sau không ai tưởng là bỏ quên.

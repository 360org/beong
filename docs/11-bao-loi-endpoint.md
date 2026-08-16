# 11 — Endpoint nhận báo lỗi

App gửi báo cáo lỗi tới một endpoint HTTP, endpoint đó tạo issue GitHub hộ.

## Vì sao phải có endpoint, không gọi thẳng GitHub?

Gọi API GitHub cần token. Token nhúng trong app thì **ai cũng rút ra được**:

```
unzip -p app-release.apk assets/flutter_assets/... | strings | grep ghp_
```

Token đó có quyền ghi vào repo — người lấy được nó tạo issue rác, sửa nội dung,
hoặc tệ hơn tuỳ phạm vi quyền. Đây là lỗ hổng thật, không phải chuyện lý thuyết.

Endpoint giải quyết đúng vấn đề đó: **token nằm trên máy chủ**, app chỉ biết một
địa chỉ URL công khai. Mất địa chỉ đó thì cùng lắm có người gửi báo cáo rác — sửa
bằng rate limit, không mất repo.

## Dựng bằng Cloudflare Worker (miễn phí, ~5 phút)

Worker miễn phí 100.000 request/ngày, quá đủ.

### 1. Tạo Fine-grained token trên GitHub

`Settings → Developer settings → Personal access tokens → Fine-grained tokens`

- **Repository access**: chỉ chọn `360org/beong`, không chọn "All repositories".
- **Permissions**: `Issues: Read and write`. **Không** cấp gì khác — token này chỉ
  cần tạo issue.
- **Expiration**: đặt hạn (90 ngày), lịch nhắc gia hạn còn hơn một token vĩnh viễn.

### 2. Tạo Worker

`dash.cloudflare.com → Workers & Pages → Create → Worker`. Dán mã ở mục dưới,
bấm Deploy.

### 3. Nạp token vào Worker

`Worker → Settings → Variables and Secrets → Add → Type: Secret`

| Tên | Giá trị |
|---|---|
| `GITHUB_TOKEN` | token vừa tạo ở bước 1 |

**Dùng Secret, không dùng Variable**: Variable hiện dạng chữ thường trong dashboard.

### 4. Dựng app với địa chỉ Worker

```bash
flutter build apk --release \
  --dart-define=BEONG_REPORT_ENDPOINT=https://beong-baoloi.<tên>.workers.dev
```

Thiếu `--dart-define` thì app rơi về đường dự phòng (mở trang tạo issue trong
trình duyệt) — chạy được, nhưng không phải trải nghiệm muốn có.

> Nhớ thêm cờ này vào `.github/workflows/release.yml` để bản CI cũng có endpoint.
> Địa chỉ Worker không phải bí mật nên để thẳng trong workflow được.

## Mã Worker

```js
// Nhận báo cáo lỗi từ app Bé Ong, tạo issue GitHub.
//
// Token nằm ở đây, không nằm trong app — đó là toàn bộ lý do tồn tại của tệp này.

const OWNER = "360org";
const REPO = "beong";

// Trần độ dài, chặn ở đây chứ không tin app: bất kỳ ai cũng POST được vào
// endpoint này, và một request 50 MB đủ để đốt hết hạn mức của ngày.
const MAX_THAN = 60_000;      // ký tự
const MAX_ANH = 4_000_000;    // ký tự base64 ≈ 3 MB ảnh

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return new Response("Chỉ nhận POST", { status: 405 });
    }

    let goi;
    try {
      goi = await request.json();
    } catch {
      return new Response("JSON hỏng", { status: 400 });
    }

    const tieuDe = String(goi.tieu_de ?? "").slice(0, 200).trim();
    const than = String(goi.than ?? "").slice(0, MAX_THAN);
    if (!tieuDe || !than) {
      return new Response("Thiếu tiêu đề hoặc nội dung", { status: 400 });
    }

    // Ảnh: GitHub API không cho đính file vào issue, nên nhúng thẳng data URI
    // vào Markdown. Xấu nhưng chạy, và không cần thêm một dịch vụ lưu ảnh nữa.
    let phanAnh = "";
    const anh = goi.anh_png_base64;
    if (typeof anh === "string" && anh.length > 0 && anh.length <= MAX_ANH) {
      phanAnh = `\n\n### Ảnh màn hình\n\n<img src="data:image/png;base64,${anh}" width="320">`;
    }

    const res = await fetch(
      `https://api.github.com/repos/${OWNER}/${REPO}/issues`,
      {
        method: "POST",
        headers: {
          authorization: `Bearer ${env.GITHUB_TOKEN}`,
          accept: "application/vnd.github+json",
          // GitHub từ chối request không có User-Agent.
          "user-agent": "beong-bao-loi",
          "content-type": "application/json",
        },
        body: JSON.stringify({
          title: tieuDe,
          body: than + phanAnh,
          labels: ["bug", "from-app"],
        }),
      },
    );

    if (!res.ok) {
      // Không trả nguyên lỗi của GitHub về app: nó có thể lộ chi tiết cấu hình,
      // mà app cũng chỉ cần biết "hỏng" để hiện nút thử lại.
      console.log("GitHub lỗi", res.status, await res.text());
      return new Response("Máy chủ chưa nhận được", { status: 502 });
    }

    return new Response("ok", { status: 201 });
  },
};
```

## Trước khi dùng thật

- [ ] Tạo hai nhãn **`bug`** và **`from-app`** trong repo. GitHub không tự tạo
      nhãn; thiếu thì API trả 422 và mọi báo cáo đều hỏng.
- [ ] Bật **rate limit** cho Worker (`Security → WAF → Rate limiting`), ví dụ 5
      request/phút mỗi IP. Endpoint công khai không có giới hạn là lời mời spam.
- [ ] Thử một lần từ máy thật, xem issue có lên đúng repo không.
- [ ] Đặt lịch nhắc **gia hạn token** trước ngày hết hạn — token hết hạn thì báo
      lỗi lặng lẽ hỏng, và không ai biết cho tới khi có người phàn nàn.

## Riêng tư

Issue trên repo công khai thì **ai cũng đọc được**. Xem `10-privacy-policy.md`
mục 4b: màn báo lỗi có công tắc tắt ảnh và câu cảnh báo, vì ảnh chụp có thể chứa
tên con và số xu.

Nếu muốn kín, đổi repo nhận báo cáo sang một **repo private** riêng — chỉ cần đổi
`OWNER`/`REPO` trong Worker và cấp token cho repo đó. App không cần dựng lại.

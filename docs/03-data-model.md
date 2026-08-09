# 03 — Mô hình dữ liệu

Cùng một schema dùng cho Postgres (Supabase) và SQLite (Drift local), khác biệt chỉ ở kiểu
dữ liệu (`uuid` → `TEXT`, `timestamptz` → `INTEGER` epoch ms).

## 1. Sơ đồ quan hệ

```
families
   ├── memberships (user_id ↔ family_id, role)      → auth.users
   ├── members            (hồ sơ: parent / child)
   ├── routines           ── routine_assignees
   │      └── tasks (routine_id, order_index)
   ├── tasks              ── task_assignees ──┐
   │      └── task_instances ─────────────────┘  (một instance cho mỗi member × ngày)
   │              └── task_events (append-only)
   ├── rewards            (reward_type: screen_time|pocket_money|experience|item|custom)
   │      └── redemptions
   ├── savings_goals      (mục tiêu tiết kiệm của trẻ)
   ├── streaks            (theo member, tính lại được)
   ├── badges_earned
   └── point_transactions (append-only ledger)
```

## 2. Bảng

### families
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| name | text | "Nhà mình" |
| timezone | text | IANA, vd `Asia/Ho_Chi_Minh` — dùng để chốt "ngày" |
| day_rollover_hour | int | mặc định 4 (ngày mới bắt đầu 4h sáng) |
| exchange_rate_xu | int NULL | bao nhiêu xu = 1 đơn vị tiền; NULL = tắt quy đổi |
| currency | text | mặc định `VND` |
| jar_split | jsonb | tỷ lệ ba hũ, mặc định `{"spend":50,"save":40,"give":10}` |
| created_at / updated_at | timestamptz | |

### memberships
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| family_id | uuid FK | |
| user_id | uuid FK → auth.users | chỉ phụ huynh |
| role | text | `owner` \| `parent` |

### members (hồ sơ hiển thị, gồm cả trẻ)
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| family_id | uuid FK | |
| user_id | uuid NULL | NULL với trẻ |
| kind | text | `parent` \| `child` |
| display_name | text | |
| avatar_key | text | id avatar dựng sẵn hoặc đường dẫn ảnh |
| color | text | màu chủ đề hồ sơ |
| birth_year | int NULL | để gợi ý preset theo tuổi |
| pin_hash | text NULL | Argon2, chỉ lưu local |
| balance_cache | int | số dư cache, luôn tính lại được từ ledger |
| jar_split_override | jsonb NULL | trẻ lớn tự đặt tỷ lệ chia; NULL = theo gia đình |
| deleted_at | timestamptz NULL | soft delete |

### routines
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| family_id | uuid FK | |
| title | text | "Buổi sáng" |
| icon_key | text | |
| time_of_day | text NULL | `morning` \| `afternoon` \| `evening` |
| start_time | time NULL | mốc nhắc nhở cho cả routine |
| repeat_type | text | `daily` \| `custom` (routine không có `once`) |
| repeat_days | int[] | |
| completion_bonus | int | điểm thưởng khi làm trọn bộ, mặc định 10, 0 = tắt |
| active | bool | |
| deleted_at, version | | |

### routine_assignees
`(routine_id, member_id)` — PK ghép. Task trong routine kế thừa danh sách này; `task_assignees`
của các task đó không dùng đến.

### tasks (định nghĩa/khuôn mẫu)
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| family_id | uuid FK | |
| title | text | |
| icon_key | text | khóa icon preset, vd `brush_teeth` |
| preset_key | text NULL | không null nếu tạo từ preset |
| points | int | 5–500 |
| routine_id | uuid NULL FK | không null → task thuộc routine |
| order_index | int NULL | thứ tự trong routine |
| repeat_type | text | `once` \| `daily` \| `custom`; **bỏ qua nếu có `routine_id`** |
| repeat_days | int[] | 1=T2 … 7=CN, chỉ dùng khi `custom` |
| once_date | date NULL | chỉ dùng khi `once` |
| time_of_day | text NULL | `morning` \| `afternoon` \| `evening` |
| due_time | time NULL | mốc nhắc nhở |
| approval_mode | text | `auto` \| `manual` |
| proof_mode | text | `none` \| `photo` \| `note` (v1.1) |
| active | bool | tạm dừng mà không xóa |
| created_by | uuid FK members | |
| deleted_at | timestamptz NULL | |
| version | int | LWW |

### task_assignees
`(task_id, member_id)` — PK ghép.

### task_instances (một dòng cho mỗi task × trẻ × ngày)
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| family_id, task_id, member_id | uuid FK | |
| due_date | date | ngày theo timezone gia đình |
| status | text | `scheduled` \| `pending_review` \| `approved` \| `rejected` \| `missed` |
| points_snapshot | int | chốt điểm lúc sinh instance (đổi giá task sau không ảnh hưởng lịch sử) |
| completed_at / reviewed_at | timestamptz NULL | |
| reviewed_by | uuid NULL | |
| proof_url / proof_note | text NULL | |

**Unique:** `(task_id, member_id, due_date)` — chặn sinh trùng khi nhiều thiết bị cùng chạy scheduler.

### task_events (append-only)
`id, instance_id, actor_member_id, type (completed|approved|rejected|reopened|missed), created_at, client_op_id`

### rewards
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id, family_id | uuid | |
| title, icon_key | text | |
| reward_type | text | `screen_time` \| `pocket_money` \| `experience` \| `item` \| `custom` |
| cost_points | int | |
| meta_json | jsonb | trường riêng theo loại: `{minutes}` hoặc `{amount, currency}` |
| stock | int NULL | NULL = không giới hạn |
| requires_approval | bool | mặc định true |
| active, deleted_at, version | | |

### redemptions
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id, family_id, reward_id, member_id | uuid | |
| cost_snapshot | int | chốt giá lúc đổi |
| meta_snapshot | jsonb | chốt `{minutes}` / `{amount}` lúc đổi |
| status | text | `pending` \| `fulfilled` \| `rejected` \| `used` |
| created_at, resolved_at, resolved_by | | |
| used_at | timestamptz NULL | trẻ bấm "đã dùng" trên phiếu |

### savings_goals
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id, family_id, member_id | uuid | |
| title | text | "Bộ Lego cảnh sát" |
| image_path | text NULL | ảnh món đồ con muốn |
| target_xu | int | |
| status | text | `active` \| `reached` \| `abandoned` |
| created_at, reached_at | | |

Chỉ một mục tiêu `active` mỗi trẻ — nhiều mục tiêu cùng lúc làm loãng bài học trì hoãn thỏa mãn.

### streaks
`member_id PK, current_len, best_len, last_qualified_date, grace_used_month (YYYY-MM), grace_count`
Bảng dẫn xuất — luôn tính lại được từ `task_instances`; chỉ để tránh quét lại lịch sử mỗi lần mở app.

### badges_earned
`id, family_id, member_id, badge_key, earned_at, client_op_id UNIQUE`
Unique `(member_id, badge_key)` — huy hiệu chỉ nhận một lần.

### point_transactions (ledger, append-only)
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| family_id, member_id | uuid | |
| jar | text | `spend` \| `save` \| `give` — mỗi giao dịch thuộc đúng một hũ |
| delta | int | dương/âm, đơn vị **xu** |
| reason | text | `task_approved` \| `routine_bonus` \| `streak_bonus` \| `reward_redeemed` \| `reward_refund` \| `manual_adjust` \| `bonus` \| `penalty` |
| ref_type / ref_id | text/uuid | trỏ tới instance, routine hoặc redemption |
| note | text NULL | |
| created_by | uuid | |
| client_op_id | uuid UNIQUE | idempotency |
| created_at | timestamptz | |

> Số dư mỗi hũ = `SELECT SUM(delta) FROM point_transactions WHERE member_id = ? AND jar = ?`.
> Tổng số dư = tổng ba hũ. Không có cột số dư nào được ghi trực tiếp.
>
> Một lần duyệt task sinh **ba dòng ledger** (một cho mỗi hũ) theo `jar_split`, chia phần dư
> vào hũ Tiêu để tổng luôn khớp. Cả ba dòng dùng chung `client_op_id` gốc kèm hậu tố hũ để
> giữ tính idempotent.
> `members.balance_cache` chỉ để hiển thị nhanh; job đối soát chạy lại mỗi lần full sync.

### outbox (chỉ local)
`id, op, entity, entity_id, payload_json, client_op_id, created_at, retry_count, last_error`

### device_settings (chỉ local, không đồng bộ)
`setting_key (PK), setting_value`

Cấu hình thuộc về **cái máy này**, không thuộc về gia đình: đang mở hồ sơ nào, vai đã chọn. Cấu
hình gia đình nằm ở tài khoản bố mẹ (ADR-021). Khoá session dùng tiền tố `session.`.

**Không đặt bí mật vào bảng này.** Token ghép cặp phải nằm ở Keychain / Keystore
(`09-onboarding-pairing.md` §4) — file SQLite đọc được trên máy đã root hoặc qua bản sao lưu.

### Cấu hình trừ xu (trên `families`)
`missed_penalty_pct, reopen_penalty_pct` — phần trăm điểm của việc, 0 = tắt (ADR-022).

### Đếm trừ xu (trên `task_instances`)
`reopen_count` — số lần bố mẹ mở lại lượt này; mỗi lần là một khoản trừ.
`missed_penalty_at` — đã áp khoản trừ "bỏ việc" chưa. Có cột này thì bộ chạy cuối ngày chỉ quét
phần chưa xử lý, và **không trừ hồi tố** khi bố mẹ bật tính năng muộn.

## 3. Sinh task_instances

Chạy khi: mở app, đổi ngày, sửa task.

> **Lệch với code hiện tại:** `TaskDao.generateInstances` chỉ được gọi từ nút "Tạo việc hôm nay"
> trên màn hình con, không chạy lúc mở app. Hệ quả thấy được: bố mẹ mở app sau khi tạo routine thì
> thấy "0 / 0 việc hôm nay", tưởng routine chưa lưu. Việc còn lại nằm ở `05-roadmap.md` Sprint 3.

```
Với mỗi task active của family:
  lịch    := task.routine_id != null ? routine.lịch    : task.lịch
  người   := task.routine_id != null ? routine_assignees : task_assignees
  Với mỗi ngày D trong [hôm nay, hôm nay + 7]:
    nếu lịch khớp tại D (once/daily/custom):
      với mỗi member trong người:
        INSERT ... ON CONFLICT (task_id, member_id, due_date) DO NOTHING
Đánh dấu missed: instance status='scheduled' và due_date < hôm nay → 'missed'
```

### Thưởng trọn bộ routine
Sau mỗi lần một instance chuyển sang `approved`, nếu instance đó thuộc routine:
```
nếu COUNT(instance của routine R, member M, ngày D, status != 'approved') == 0:
  INSERT point_transactions(delta=R.completion_bonus, reason='routine_bonus',
                            ref_type='routine', ref_id=R.id,
                            client_op_id = uuid_v5(R.id + M.id + D))   -- idempotent
```
`client_op_id` sinh xác định (UUID v5) từ bộ ba → nhiều thiết bị cùng tính cũng chỉ ra một dòng,
unique index tự chặn phần còn lại.

### Tính streak
```
Với mỗi ngày D lùi dần từ hôm qua:
  due := số instance đến hạn ngày D
  nếu due == 0            → ngày trung tính, bỏ qua, streak không đứt
  nếu approved/due >= 0.8 → streak++
  ngược lại               → nếu chưa dùng ngày ân hạn tháng đó thì dùng, streak++
                            không thì dừng
```
"Hôm nay" tính theo `families.timezone` và `day_rollover_hour` (mặc định 4h sáng, để việc
làm lúc 11h đêm vẫn tính cho ngày hôm đó).

## 4. Chỉ mục

```sql
CREATE INDEX ON task_instances (family_id, due_date, status);
CREATE INDEX ON task_instances (member_id, due_date);
CREATE UNIQUE INDEX ON task_instances (task_id, member_id, due_date);
CREATE INDEX ON point_transactions (member_id, created_at DESC);
CREATE UNIQUE INDEX ON point_transactions (client_op_id);
CREATE INDEX ON redemptions (family_id, status);
CREATE INDEX ON tasks (routine_id, order_index);
CREATE UNIQUE INDEX ON badges_earned (member_id, badge_key);
```

## 5. Row Level Security (Postgres)

```sql
create or replace function auth_family_ids() returns setof uuid
language sql stable security definer as $$
  select family_id from memberships where user_id = auth.uid()
$$;

alter table tasks enable row level security;
create policy tasks_rw on tasks
  for all
  using  (family_id in (select auth_family_ids()))
  with check (family_id in (select auth_family_ids()));
-- lặp lại cho mọi bảng có family_id
```
`point_transactions`: cho `insert` + `select`, **cấm** `update`/`delete` để giữ tính append-only.

## 6. Migration

- Drift: `schemaVersion` tăng dần, mỗi bước có test dựng DB phiên bản cũ rồi migrate.
  Test: `test/unit/data/migration_test.dart`.
  - v1 → v2: thêm `device_settings`.
  - v2 → v3: thêm `families.missed_penalty_pct`, `families.reopen_penalty_pct`,
    `task_instances.reopen_count`, `task_instances.missed_penalty_at` (ADR-022). Mọi cột có
    default 0/NULL nên **nâng cấp không tự bật trừ xu** — có test khẳng định điều này.
- Supabase: file SQL đánh số trong `supabase/migrations/`, chạy qua CLI trong CI.
- Quy tắc: chỉ thêm cột nullable hoặc có default; đổi tên = thêm mới + backfill + xóa ở release sau.

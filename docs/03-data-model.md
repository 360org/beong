# 03 — Mô hình dữ liệu

Cùng một schema dùng cho Postgres (Supabase) và SQLite (Drift local), khác biệt chỉ ở kiểu
dữ liệu (`uuid` → `TEXT`, `timestamptz` → `INTEGER` epoch ms).

## 1. Sơ đồ quan hệ

```
families
   ├── memberships (user_id ↔ family_id, role)      → auth.users
   ├── members            (hồ sơ: parent / child)
   ├── tasks              ── task_assignees ──┐
   │      └── task_instances ─────────────────┘  (một instance cho mỗi member × ngày)
   │              └── task_events (append-only)
   ├── rewards
   │      └── redemptions
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
| deleted_at | timestamptz NULL | soft delete |

### tasks (định nghĩa/khuôn mẫu)
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| family_id | uuid FK | |
| title | text | |
| icon_key | text | khóa icon preset, vd `brush_teeth` |
| preset_key | text NULL | không null nếu tạo từ preset |
| points | int | 5–500 |
| repeat_type | text | `once` \| `daily` \| `custom` |
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
| Cột | Kiểu |
|---|---|
| id, family_id | uuid |
| title, icon_key | text |
| cost_points | int |
| stock | int NULL (NULL = không giới hạn) |
| requires_approval | bool (mặc định true) |
| active | bool, deleted_at |

### redemptions
`id, family_id, reward_id, member_id, cost_snapshot, status (pending|fulfilled|rejected), created_at, resolved_at, resolved_by`

### point_transactions (ledger, append-only)
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| family_id, member_id | uuid | |
| delta | int | dương/âm |
| reason | text | `task_approved` \| `reward_redeemed` \| `reward_refund` \| `manual_adjust` \| `bonus` \| `penalty` |
| ref_type / ref_id | text/uuid | trỏ tới instance hoặc redemption |
| note | text NULL | |
| created_by | uuid | |
| client_op_id | uuid UNIQUE | idempotency |
| created_at | timestamptz | |

> Số dư = `SELECT COALESCE(SUM(delta),0) FROM point_transactions WHERE member_id = ?`.
> `members.balance_cache` chỉ để hiển thị nhanh; job đối soát chạy lại mỗi lần full sync.

### outbox (chỉ local)
`id, op, entity, entity_id, payload_json, client_op_id, created_at, retry_count, last_error`

## 3. Sinh task_instances

Chạy khi: mở app, đổi ngày, sửa task.

```
Với mỗi task active của family:
  Với mỗi ngày D trong [hôm nay, hôm nay + 7]:
    nếu task khớp lịch tại D (once/daily/custom):
      với mỗi member được gán:
        INSERT ... ON CONFLICT (task_id, member_id, due_date) DO NOTHING
Đánh dấu missed: instance status='scheduled' và due_date < hôm nay → 'missed'
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
- Supabase: file SQL đánh số trong `supabase/migrations/`, chạy qua CLI trong CI.
- Quy tắc: chỉ thêm cột nullable hoặc có default; đổi tên = thêm mới + backfill + xóa ở release sau.

-- ============================================================================
-- Supabase PostgreSQL Schema Migration for Bé Ong
-- Version: 20260823000000_init_beong_schema.sql
-- Docs: docs/03-data-model.md & docs/09-onboarding-pairing.md
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. FAMILIES
CREATE TABLE IF NOT EXISTS public.families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(80) NOT NULL,
    timezone VARCHAR(50) NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
    day_rollover_hour INT NOT NULL DEFAULT 4,
    exchange_rate_xu INT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'VND',
    jar_split JSONB NOT NULL DEFAULT '{"spend":50,"save":40,"give":10}'::jsonb,
    allocation_mode VARCHAR(20) NOT NULL DEFAULT 'auto',
    require_approval BOOLEAN NOT NULL DEFAULT FALSE,
    missed_penalty_pct INT NOT NULL DEFAULT 0,
    reopen_penalty_pct INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. MEMBERSHIPS (Liên kết auth.users với gia đình)
CREATE TABLE IF NOT EXISTS public.memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'parent', -- 'owner' | 'parent'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (family_id, user_id)
);

-- 3. MEMBERS (Hồ sơ bố mẹ và con trong gia đình)
CREATE TABLE IF NOT EXISTS public.members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    user_id UUID NULL REFERENCES auth.users(id) ON DELETE SET NULL,
    kind VARCHAR(20) NOT NULL, -- 'parent' | 'child'
    display_name VARCHAR(40) NOT NULL,
    avatar_key TEXT NULL,
    color_index INT NOT NULL DEFAULT 0,
    birth_year INT NULL,
    pin_hash TEXT NULL,
    jar_split_override JSONB NULL,
    deleted_at TIMESTAMPTZ NULL,
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. DEVICES & PAIRING CODES (Hạ tầng ghép cặp máy con)
CREATE TABLE IF NOT EXISTS public.devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
    device_name TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL,
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.pairing_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
    code_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. JARS (Các hũ quản lý tài chính tuỳ biến của gia đình)
CREATE TABLE IF NOT EXISTS public.jars (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    jar_key VARCHAR(40) NOT NULL,
    title VARCHAR(40) NOT NULL,
    emoji VARCHAR(20) NOT NULL,
    percentage INT NOT NULL DEFAULT 0,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(family_id, jar_key)
);

-- 6. ROUTINES & ROUTINE ASSIGNEES
CREATE TABLE IF NOT EXISTS public.routines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    title VARCHAR(60) NOT NULL,
    icon_key TEXT NULL,
    day_part VARCHAR(20) NULL,
    start_time TIME NULL,
    repeat_type VARCHAR(20) NOT NULL DEFAULT 'daily',
    repeat_days TEXT NOT NULL DEFAULT '',
    completion_bonus INT NOT NULL DEFAULT 10,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    deleted_at TIMESTAMPTZ NULL,
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.routine_assignees (
    routine_id UUID NOT NULL REFERENCES public.routines(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
    PRIMARY KEY (routine_id, member_id)
);

-- 7. TASKS & TASK ASSIGNEES
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    title VARCHAR(60) NOT NULL,
    icon_key TEXT NULL,
    preset_key TEXT NULL,
    points INT NOT NULL DEFAULT 10,
    routine_id UUID NULL REFERENCES public.routines(id) ON DELETE SET NULL,
    order_index INT NULL,
    repeat_type VARCHAR(20) NOT NULL DEFAULT 'daily',
    repeat_days TEXT NOT NULL DEFAULT '',
    once_date DATE NULL,
    day_part VARCHAR(20) NULL,
    due_time TIME NULL,
    missed_penalty_pct INT NULL,
    approval_mode VARCHAR(20) NOT NULL DEFAULT 'manual',
    proof_mode VARCHAR(20) NOT NULL DEFAULT 'none',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID NULL,
    deleted_at TIMESTAMPTZ NULL,
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.task_assignees (
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
    PRIMARY KEY (task_id, member_id)
);

-- 8. TASK INSTANCES
CREATE TABLE IF NOT EXISTS public.task_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
    due_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled',
    points_snapshot INT NOT NULL,
    completed_at TIMESTAMPTZ NULL,
    reviewed_at TIMESTAMPTZ NULL,
    reviewed_by UUID NULL,
    proof_url TEXT NULL,
    proof_note TEXT NULL,
    reopen_count INT NOT NULL DEFAULT 0,
    missed_penalty_pct INT NULL,
    missed_penalty_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (task_id, member_id, due_date)
);

-- 9. POINT TRANSACTIONS (Append-only Ledger)
CREATE TABLE IF NOT EXISTS public.point_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
    jar VARCHAR(40) NOT NULL,
    delta INT NOT NULL,
    reason VARCHAR(40) NOT NULL,
    ref_type VARCHAR(40) NULL,
    ref_id TEXT NULL,
    note TEXT NULL,
    created_by UUID NULL,
    client_op_id TEXT NOT NULL UNIQUE,
    op_group_id TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. REWARDS & REDEMPTIONS
CREATE TABLE IF NOT EXISTS public.rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    title VARCHAR(60) NOT NULL,
    icon_key TEXT NULL,
    reward_type VARCHAR(20) NOT NULL DEFAULT 'custom',
    cost_points INT NOT NULL,
    meta_json JSONB NULL,
    stock INT NULL,
    requires_approval BOOLEAN NOT NULL DEFAULT TRUE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    deleted_at TIMESTAMPTZ NULL,
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.redemptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    reward_id UUID NOT NULL REFERENCES public.rewards(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
    cost_snapshot INT NOT NULL,
    meta_snapshot JSONB NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    resolved_at TIMESTAMPTZ NULL,
    resolved_by UUID NULL,
    used_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. SAVINGS GOALS, STREAKS & BADGES
CREATE TABLE IF NOT EXISTS public.savings_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
    title VARCHAR(60) NOT NULL,
    image_path TEXT NULL,
    icon_key TEXT NULL,
    target_xu INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    reached_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.streaks (
    member_id UUID PRIMARY KEY REFERENCES public.members(id) ON DELETE CASCADE,
    current_len INT NOT NULL DEFAULT 0,
    best_len INT NOT NULL DEFAULT 0,
    last_qualified_date DATE NULL,
    grace_used_month VARCHAR(7) NULL,
    grace_count INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.badges_earned (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
    badge_key VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (member_id, badge_key)
);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pairing_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routine_assignees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_assignees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.point_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges_earned ENABLE ROW LEVEL SECURITY;

-- Helper Functions để kiểm tra quyền
CREATE OR REPLACE FUNCTION public.is_family_parent(f_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.memberships
        WHERE family_id = f_id AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_current_device_member_id()
RETURNS UUID AS $$
BEGIN
    RETURN NULLIF(current_setting('request.jwt.claims', true)::jsonb ->> 'member_id', '')::uuid;
EXCEPTION
    WHEN OTHERS THEN RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

-- 1. FAMILIES POLICIES
CREATE POLICY "Parents have full access to family"
ON public.families FOR ALL
USING (public.is_family_parent(id));

CREATE POLICY "Child devices can read family settings"
ON public.families FOR SELECT
USING (
    id IN (
        SELECT family_id FROM public.members
        WHERE id = public.get_current_device_member_id()
    )
);

-- 2. MEMBERS POLICIES
CREATE POLICY "Parents have full access to members"
ON public.members FOR ALL
USING (public.is_family_parent(family_id));

CREATE POLICY "Child devices can read sibling basic profiles"
ON public.members FOR SELECT
USING (
    family_id IN (
        SELECT family_id FROM public.members
        WHERE id = public.get_current_device_member_id()
    )
);

-- 3. TASKS & ROUTINES POLICIES
CREATE POLICY "Parents have full access to tasks"
ON public.tasks FOR ALL
USING (public.is_family_parent(family_id));

CREATE POLICY "Child devices can read active tasks assigned to them"
ON public.tasks FOR SELECT
USING (
    active = TRUE AND (
        id IN (
            SELECT task_id FROM public.task_assignees
            WHERE member_id = public.get_current_device_member_id()
        )
        OR routine_id IN (
            SELECT routine_id FROM public.routine_assignees
            WHERE member_id = public.get_current_device_member_id()
        )
    )
);

CREATE POLICY "Parents have full access to routines"
ON public.routines FOR ALL
USING (public.is_family_parent(family_id));

CREATE POLICY "Child devices can read assigned routines"
ON public.routines FOR SELECT
USING (
    active = TRUE AND id IN (
        SELECT routine_id FROM public.routine_assignees
        WHERE member_id = public.get_current_device_member_id()
    )
);

-- 4. TASK INSTANCES POLICIES
CREATE POLICY "Parents have full access to task instances"
ON public.task_instances FOR ALL
USING (public.is_family_parent(family_id));

CREATE POLICY "Child can read and complete their own instances"
ON public.task_instances FOR SELECT
USING (member_id = public.get_current_device_member_id());

CREATE POLICY "Child can update their own instances to complete"
ON public.task_instances FOR UPDATE
USING (member_id = public.get_current_device_member_id())
WITH CHECK (member_id = public.get_current_device_member_id());

-- 5. POINT TRANSACTIONS POLICIES
CREATE POLICY "Parents have full access to point transactions"
ON public.point_transactions FOR ALL
USING (public.is_family_parent(family_id));

CREATE POLICY "Child can only read their own point transactions"
ON public.point_transactions FOR SELECT
USING (member_id = public.get_current_device_member_id());

-- 6. REWARDS & REDEMPTIONS POLICIES
CREATE POLICY "Parents have full access to rewards"
ON public.rewards FOR ALL
USING (public.is_family_parent(family_id));

CREATE POLICY "Child can view active rewards"
ON public.rewards FOR SELECT
USING (
    active = TRUE AND family_id IN (
        SELECT family_id FROM public.members
        WHERE id = public.get_current_device_member_id()
    )
);

CREATE POLICY "Parents have full access to redemptions"
ON public.redemptions FOR ALL
USING (public.is_family_parent(family_id));

CREATE POLICY "Child can create their own redemptions"
ON public.redemptions FOR INSERT
WITH CHECK (member_id = public.get_current_device_member_id());

CREATE POLICY "Child can read their own redemptions"
ON public.redemptions FOR SELECT
USING (member_id = public.get_current_device_member_id());

CREATE POLICY "Child can update their own redemptions (mark used)"
ON public.redemptions FOR UPDATE
USING (member_id = public.get_current_device_member_id())
WITH CHECK (member_id = public.get_current_device_member_id());

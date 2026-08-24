-- Migration: Tạo bảng lưu token thiết bị cho Push Notification (FCM / APNs)
-- và hàm trigger webhook gửi thông báo

-- 1. Bảng device_tokens
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'macos', 'web')),
    device_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_member_fcm_token UNIQUE (member_id, fcm_token)
);

-- Index tra cứu nhanh token theo gia đình và thành viên
CREATE INDEX IF NOT EXISTS idx_device_tokens_family_id ON public.device_tokens(family_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_member_id ON public.device_tokens(member_id);

-- 2. Bật Row Level Security (RLS)
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- Policy RLS: Thành viên chỉ xem và cập nhật token trong cùng gia đình
CREATE POLICY "device_tokens_select_family" ON public.device_tokens
    FOR SELECT USING (family_id IN (SELECT family_id FROM public.members WHERE id = auth.uid()));

CREATE POLICY "device_tokens_insert_family" ON public.device_tokens
    FOR INSERT WITH CHECK (family_id IN (SELECT family_id FROM public.members WHERE id = auth.uid()));

CREATE POLICY "device_tokens_update_family" ON public.device_tokens
    FOR UPDATE USING (family_id IN (SELECT family_id FROM public.members WHERE id = auth.uid()));

CREATE POLICY "device_tokens_delete_family" ON public.device_tokens
    FOR DELETE USING (family_id IN (SELECT family_id FROM public.members WHERE id = auth.uid()));

-- 3. Trigger tự động cập nhật `updated_at`
CREATE OR REPLACE FUNCTION public.handle_device_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_device_tokens_updated_at
    BEFORE UPDATE ON public.device_tokens
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_device_tokens_updated_at();

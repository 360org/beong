#!/usr/bin/env python3
"""
Store Asset Designer for Bé Ong
Generates 3 App Previews and 10 App Store Screenshots (1284 x 2778 px)
"""

import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# Paths
BASE_DIR = "/Volumes/DATA/DEV/MOBILES/beong"
SCREENSHOT_DIR = os.path.join(BASE_DIR, "docs/screenshot")
ASSET_ICONS_DIR = os.path.join(BASE_DIR, "assets/icons")
FONT_DIR = os.path.join(BASE_DIR, "assets/fonts")
OUTPUT_DIR = os.path.join(BASE_DIR, "docs/store_assets")
PREVIEW_DIR = os.path.join(OUTPUT_DIR, "previews")
SCREENSHOTS_OUT_DIR = os.path.join(OUTPUT_DIR, "screenshots")

os.makedirs(PREVIEW_DIR, exist_ok=True)
os.makedirs(SCREENSHOTS_OUT_DIR, exist_ok=True)

# Canvas Dimensions (Apple standard: 1284 x 2778 px)
WIDTH = 1284
HEIGHT = 2778

# Color Palette (Brand compliant: 04-design-system.md)
C_PRIMARY = "#0077CD"
C_PRIMARY_DARK = "#005BA1"
C_PRIMARY_LIGHT = "#E3F2FD"
C_BEE_YELLOW = "#FFC53D"
C_HONEY_GOLD = "#FFAE1A"
C_SUCCESS = "#00851C"
C_DARK_TEXT = "#1B1046"
C_MUTED_TEXT = "#605980"
C_WHITE = "#FFFFFF"

# Fonts
font_huge = ImageFont.truetype(os.path.join(FONT_DIR, "Nunito-ExtraBold.ttf"), 76)
font_title = ImageFont.truetype(os.path.join(FONT_DIR, "Nunito-ExtraBold.ttf"), 64)
font_subtitle = ImageFont.truetype(os.path.join(FONT_DIR, "Nunito-Bold.ttf"), 38)
font_body = ImageFont.truetype(os.path.join(FONT_DIR, "Nunito-Medium.ttf"), 34)
font_badge = ImageFont.truetype(os.path.join(FONT_DIR, "Nunito-ExtraBold.ttf"), 30)
font_tagline = ImageFont.truetype(os.path.join(FONT_DIR, "Nunito-Bold.ttf"), 32)
font_card_title = ImageFont.truetype(os.path.join(FONT_DIR, "Nunito-ExtraBold.ttf"), 34)
font_card_desc = ImageFont.truetype(os.path.join(FONT_DIR, "Nunito-Medium.ttf"), 26)

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))

def create_gradient_bg(w, h, color_top, color_bottom):
    """Creates a smooth vertical gradient background."""
    top_r, top_g, top_b = hex_to_rgb(color_top)
    bot_r, bot_g, bot_b = hex_to_rgb(color_bottom)

    gradient = Image.new("RGBA", (w, h))
    draw = ImageDraw.Draw(gradient)

    for y in range(h):
        ratio = y / float(h)
        r = int(top_r + (bot_r - top_r) * ratio)
        g = int(top_g + (bot_g - top_g) * ratio)
        b = int(top_b + (bot_b - top_b) * ratio)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))

    return gradient

def draw_hexagon(draw, center, radius, fill=None, outline=None, width=1):
    """Draw a regular hexagon."""
    cx, cy = center
    points = []
    for i in range(6):
        angle_deg = 60 * i - 30
        angle_rad = math.radians(angle_deg)
        x = cx + radius * math.cos(angle_rad)
        y = cy + radius * math.sin(angle_rad)
        points.append((x, y))
    draw.polygon(points, fill=fill, outline=outline, width=width)

def add_decorations(img, theme="blue"):
    """Adds subtle floating ambient background elements (hexagons, glowing circles)."""
    overlay = Image.new("RGBA", img.size, (255, 255, 255, 0))
    draw = ImageDraw.Draw(overlay)
    w, h = img.size

    if theme == "blue":
        hex_color = (0, 119, 205, 14)
        glow_color = (227, 242, 253, 60)
    elif theme == "warm":
        hex_color = (255, 197, 61, 20)
        glow_color = (255, 248, 230, 70)
    elif theme == "green":
        hex_color = (0, 133, 28, 14)
        glow_color = (230, 248, 235, 60)
    else:
        hex_color = (142, 138, 168, 14)
        glow_color = (246, 245, 252, 60)

    # Ambient soft glow orbs
    draw.ellipse([(-100, -100), (600, 600)], fill=glow_color)
    draw.ellipse([(w - 500, 400), (w + 200, 1100)], fill=glow_color)
    draw.ellipse([(100, h - 700), (700, h - 100)], fill=glow_color)

    # Hexagon motifs
    radius = 90
    dx = radius * math.sqrt(3)
    dy = radius * 1.5
    cols = int(w / dx) + 2
    rows = int(h / dy) + 2

    for row in range(rows):
        for col in range(cols):
            x_offset = (dx / 2) if (row % 2 == 1) else 0
            cx = col * dx + x_offset
            cy = row * dy
            draw_hexagon(draw, (cx, cy), radius * 0.88, outline=hex_color, width=2)

    return Image.alpha_composite(img, overlay)

def create_phone_mockup(screenshot_name, target_width=860, target_height=1880, corner_radius=64, border_width=16, shadow_offset=35, shadow_blur=50):
    """
    Wraps screenshot in modern bezel with dynamic island and high-res soft drop shadow.
    """
    sc_path = os.path.join(SCREENSHOT_DIR, screenshot_name)
    if not os.path.exists(sc_path):
        raise FileNotFoundError(f"Screenshot not found: {sc_path}")

    raw_img = Image.open(sc_path).convert("RGBA")

    screen_w = target_width - border_width * 2
    screen_h = target_height - border_width * 2

    scaled_screen = raw_img.resize((screen_w, screen_h), Image.Resampling.LANCZOS)

    screen_mask = Image.new("L", (screen_w, screen_h), 0)
    mask_draw = ImageDraw.Draw(screen_mask)
    inner_radius = max(8, corner_radius - border_width)
    mask_draw.rounded_rectangle([(0, 0), (screen_w, screen_h)], inner_radius, fill=255)

    phone_canvas = Image.new("RGBA", (target_width, target_height), (0, 0, 0, 0))
    phone_draw = ImageDraw.Draw(phone_canvas)

    # Outer bezel (Metallic dark frame)
    phone_draw.rounded_rectangle([(0, 0), (target_width, target_height)], corner_radius, fill=(24, 24, 30, 255), outline=(60, 60, 72, 255), width=3)

    # Paste screen content
    phone_canvas.paste(scaled_screen, (border_width, border_width), screen_mask)

    # Dynamic Island notch
    island_w = int(screen_w * 0.28)
    island_h = 36
    island_x = (target_width - island_w) // 2
    island_y = border_width + 12
    phone_draw.rounded_rectangle([(island_x, island_y), (island_x + island_w, island_y + island_h)], 18, fill=(0, 0, 0, 255))

    # Screen inner highlight stroke
    phone_draw.rounded_rectangle([(border_width, border_width), (target_width - border_width, target_height - border_width)], inner_radius, outline=(255, 255, 255, 35), width=2)

    # High-quality drop shadow
    pad = shadow_blur * 3
    shadow_w = target_width + pad * 2
    shadow_h = target_height + pad * 2
    shadow_canvas = Image.new("RGBA", (shadow_w, shadow_h), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_canvas)

    sx0 = pad
    sy0 = pad + shadow_offset
    sx1 = sx0 + target_width
    sy1 = sy0 + target_height

    shadow_draw.rounded_rectangle([(sx0, sy0), (sx1, sy1)], corner_radius, fill=(15, 10, 35, 110))
    shadow_canvas = shadow_canvas.filter(ImageFilter.GaussianBlur(shadow_blur))

    # Composite phone on shadow
    final_mockup = Image.new("RGBA", (shadow_w, shadow_h), (0, 0, 0, 0))
    final_mockup.paste(shadow_canvas, (0, 0), shadow_canvas)
    final_mockup.paste(phone_canvas, (pad, pad), phone_canvas)

    return final_mockup, pad

def draw_header_section(draw, badge_text, headline_lines, subtitle_lines, center_x=WIDTH//2, top_y=140, badge_theme="blue"):
    """Renders clean, highly legible header typography."""
    curr_y = top_y

    # 1. Badge Chip
    if badge_text:
        if badge_theme == "yellow":
            b_bg, b_fg = "#FFF4D4", "#906500"
        elif badge_theme == "green":
            b_bg, b_fg = "#E6F8EB", "#00851C"
        else:
            b_bg, b_fg = "#E3F2FD", "#0077CD"

        bbox = font_badge.getbbox(badge_text)
        bw = bbox[2] - bbox[0] + 52
        bh = bbox[3] - bbox[1] + 24
        bx = center_x - bw // 2
        draw.rounded_rectangle([(bx, curr_y), (bx + bw, curr_y + bh)], bh // 2, fill=b_bg)
        draw.text((center_x, curr_y + bh // 2 - 2), badge_text, fill=b_fg, font=font_badge, anchor="mm")
        curr_y += bh + 36

    # 2. Main Headline
    for line in headline_lines:
        draw.text((center_x, curr_y), line, fill=C_DARK_TEXT, font=font_huge, anchor="mt")
        bbox = font_huge.getbbox(line)
        curr_y += (bbox[3] - bbox[1]) + 20

    # 3. Subtitle / Explanatory text
    if subtitle_lines:
        curr_y += 10
        for sline in subtitle_lines:
            draw.text((center_x, curr_y), sline, fill=C_MUTED_TEXT, font=font_subtitle, anchor="mt")
            bbox = font_subtitle.getbbox(sline)
            curr_y += (bbox[3] - bbox[1]) + 14

    return curr_y

def paste_icon_with_shadow(canvas, icon_name, pos, size=130, rotation=0):
    """Pasting 3D emoji icon with floating drop shadow."""
    ipath = os.path.join(ASSET_ICONS_DIR, icon_name)
    if not os.path.exists(ipath):
        return
    icon = Image.open(ipath).convert("RGBA")
    icon = icon.resize((size, size), Image.Resampling.LANCZOS)
    if rotation != 0:
        icon = icon.rotate(rotation, resample=Image.Resampling.BICUBIC, expand=True)

    iw, ih = icon.size
    shadow_blur = 18
    shadow = Image.new("RGBA", (iw + shadow_blur * 2, ih + shadow_blur * 2), (0, 0, 0, 0))
    s_mask = icon.split()[3]
    shadow_color = Image.new("RGBA", (iw, ih), (25, 18, 45, 95))
    shadow.paste(shadow_color, (shadow_blur, shadow_blur + 10), s_mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(shadow_blur))

    canvas.paste(shadow, (pos[0] - shadow_blur, pos[1] - shadow_blur), shadow)
    canvas.paste(icon, pos, icon)

def draw_feature_card(draw, pos, size, icon_name, title, desc, bg_color="#FFFFFF", border_color="#E0DFEC"):
    """Draws a floating feature callout card beside or below mockups."""
    x, y = pos
    w, h = size

    # Background card
    draw.rounded_rectangle([(x, y), (x + w, y + h)], 24, fill=bg_color, outline=border_color, width=2)

    # Icon
    icon_size = 64
    paste_icon_with_shadow(draw._image, icon_name, (x + 24, y + (h - icon_size) // 2), size=icon_size)

    # Texts
    tx = x + 24 + icon_size + 20
    ty = y + 26
    draw.text((tx, ty), title, fill=C_DARK_TEXT, font=font_card_title)
    draw.text((tx, ty + 42), desc, fill=C_MUTED_TEXT, font=font_card_desc)

# ==============================================================================
# SCREENSHOT GENERATION (10 Single-Focus Artworks)
# ==============================================================================

def generate_screenshot(filename, badge, headline, subtitle, screenshot_name, theme="blue", icons=None, card_info=None):
    """Generates standard full-sized screenshot artwork with mockups & visual accents."""
    bg = create_gradient_bg(WIDTH, HEIGHT, "#FFFFFF", "#F4F7FC" if theme=="blue" else ("#FDFBF5" if theme=="warm" else "#F4FAF6"))
    bg = add_decorations(bg, theme=theme)
    draw = ImageDraw.Draw(bg)

    # Header
    last_y = draw_header_section(draw, badge, headline, subtitle, badge_theme=theme, top_y=130)

    # Phone Mockup
    mockup_img, pad = create_phone_mockup(screenshot_name, target_width=860, target_height=1880)

    mockup_x = (WIDTH - 860) // 2 - pad
    mockup_y = 670 - pad

    bg.paste(mockup_img, (mockup_x, mockup_y), mockup_img)

    # Decorative floating icons
    if icons:
        for ic_name, ic_pos, ic_size, ic_rot in icons:
            paste_icon_with_shadow(bg, ic_name, ic_pos, size=ic_size, rotation=ic_rot)

    # Output save
    out_path = os.path.join(SCREENSHOTS_OUT_DIR, filename)
    bg.convert("RGB").save(out_path, "PNG", quality=95)
    print(f"✓ Created Screenshot: {filename}")

# ==============================================================================
# APP PREVIEWS GENERATION (3 Multi-Screen Panorama Artworks)
# ==============================================================================

def generate_preview_1():
    """Preview 1: Bé Tự Lập Làm Việc Nhà & Tích Xu."""
    bg = create_gradient_bg(WIDTH, HEIGHT, "#FFFFFF", "#F3F8FE")
    bg = add_decorations(bg, theme="blue")
    draw = ImageDraw.Draw(bg)

    # Header
    draw_header_section(draw,
        "VAI TRÒ TRẺ EM · TỰ LẬP MỖI NGÀY",
        ["Bé Tự Lập Làm Việc Nhà", "Nhận Thưởng Xứng Đáng"],
        ["Con chủ động thực hiện thói quen, tích lũy xu ong", "và học cách tự chịu trách nhiệm."],
        badge_theme="yellow",
        top_y=120
    )

    # Main Center Mockup (Child Home - Hoàn thành)
    center_mockup, pad = create_phone_mockup("28-child-home-hoan-thanh.png", target_width=780, target_height=1700)
    bg.paste(center_mockup, ((WIDTH - 780)//2 - pad, 680 - pad), center_mockup)

    # Left Secondary Mockup (Child Home - Đang làm)
    left_mockup, l_pad = create_phone_mockup("27-child-home-dang-lam.png", target_width=660, target_height=1440, shadow_blur=35)
    # Right Secondary Mockup (Child Huy hiệu)
    right_mockup, r_pad = create_phone_mockup("29-child-huy-hieu.png", target_width=660, target_height=1440, shadow_blur=35)

    # Compose layered mockups
    comp = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    comp.paste(left_mockup, (-220 - l_pad, 820 - l_pad), left_mockup)
    comp.paste(right_mockup, (WIDTH - 440 - r_pad, 820 - r_pad), right_mockup)
    comp.paste(center_mockup, ((WIDTH - 780)//2 - pad, 680 - pad), center_mockup)

    bg = Image.alpha_composite(bg, comp)

    # Floating 3D Icons
    paste_icon_with_shadow(bg, "bee.png", (980, 560), size=170, rotation=12)
    paste_icon_with_shadow(bg, "star.png", (130, 600), size=140, rotation=-15)
    paste_icon_with_shadow(bg, "fire.png", (1020, 1950), size=150, rotation=10)

    # Bottom Tagline
    b_draw = ImageDraw.Draw(bg)
    b_draw.rounded_rectangle([(WIDTH//2 - 280, HEIGHT - 140), (WIDTH//2 + 280, HEIGHT - 64)], 38, fill="#E3F2FD")
    b_draw.text((WIDTH//2, HEIGHT - 104), "✨ Con tự bay, bố mẹ bay cùng ✨", fill="#0077CD", font=font_tagline, anchor="mm")

    out_path = os.path.join(PREVIEW_DIR, "preview_01_con_tu_lap.png")
    bg.convert("RGB").save(out_path, "PNG", quality=95)
    print("✓ Created Preview 1: Con Tự Lập")

def generate_preview_2():
    """Preview 2: Bố Mẹ Đồng Hành & Xét Duyệt Việc."""
    bg = create_gradient_bg(WIDTH, HEIGHT, "#FFFFFF", "#F5FAF6")
    bg = add_decorations(bg, theme="green")
    draw = ImageDraw.Draw(bg)

    # Header
    draw_header_section(draw,
        "VAI TRÒ PHỤ HUYNH · ĐỒNG HÀNH & KẾT NỐI",
        ["Bố Mẹ Đồng Hành & Xét Duyệt", "Nhẹ Nhàng Không Cằn Nhằn"],
        ["Giao việc theo lịch trình, xem bằng chứng và duyệt thưởng", "chỉ với một chạm tiện lợi."],
        badge_theme="green",
        top_y=120
    )

    # Main Center Mockup (Parent Home / Hang doi duyet)
    center_mockup, pad = create_phone_mockup("55-parent-hang-doi-duyet.png", target_width=780, target_height=1700)

    # Left Secondary Mockup (Parent Home)
    left_mockup, l_pad = create_phone_mockup("04-parent-home.png", target_width=660, target_height=1440, shadow_blur=35)
    # Right Secondary Mockup (Duyệt đổi thưởng)
    right_mockup, r_pad = create_phone_mockup("38-parent-duyet-doi-thuong.png", target_width=660, target_height=1440, shadow_blur=35)

    comp = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    comp.paste(left_mockup, (-220 - l_pad, 820 - l_pad), left_mockup)
    comp.paste(right_mockup, (WIDTH - 440 - r_pad, 820 - r_pad), right_mockup)
    comp.paste(center_mockup, ((WIDTH - 780)//2 - pad, 680 - pad), center_mockup)

    bg = Image.alpha_composite(bg, comp)

    paste_icon_with_shadow(bg, "heart.png", (990, 580), size=160, rotation=12)
    paste_icon_with_shadow(bg, "clipboard.png", (120, 600), size=145, rotation=-12)
    paste_icon_with_shadow(bg, "av_parent.png", (100, 1960), size=150, rotation=-8)

    b_draw = ImageDraw.Draw(bg)
    b_draw.rounded_rectangle([(WIDTH//2 - 300, HEIGHT - 140), (WIDTH//2 + 300, HEIGHT - 64)], 38, fill="#E6F8EB")
    b_draw.text((WIDTH//2, HEIGHT - 104), "🌿 Nuôi dưỡng trách nhiệm & thấu hiểu 🌿", fill="#00851C", font=font_tagline, anchor="mm")

    out_path = os.path.join(PREVIEW_DIR, "preview_02_bo_me_dong_hanh.png")
    bg.convert("RGB").save(out_path, "PNG", quality=95)
    print("✓ Created Preview 2: Bố Mẹ Đồng Hành")

def generate_preview_3():
    """Preview 3: Học Quản Lý Tài Chính & 3 Hũ Xu."""
    bg = create_gradient_bg(WIDTH, HEIGHT, "#FFFFFF", "#FEF9F0")
    bg = add_decorations(bg, theme="warm")
    draw = ImageDraw.Draw(bg)

    # Header
    draw_header_section(draw,
        "GIÁO DỤC TÀI CHÍNH · 3 HŨ THÔNG MINH",
        ["Học Quản Lý Tài Chính Từ Bé", "Tiết Kiệm & Đổi Thưởng"],
        ["Trẻ tự chia xu vào 3 hũ: Tiết kiệm, Tiêu dùng, Chia sẻ", "và nuôi dưỡng ước mơ."],
        badge_theme="yellow",
        top_y=120
    )

    # Main Center Mockup (Chia xu)
    center_mockup, pad = create_phone_mockup("59-child-man-chia-xu.png", target_width=780, target_height=1700)

    # Left Secondary Mockup (Phần thưởng)
    left_mockup, l_pad = create_phone_mockup("32-child-phan-thuong.png", target_width=660, target_height=1440, shadow_blur=35)
    # Right Secondary Mockup (Thống kê mục tiêu)
    right_mockup, r_pad = create_phone_mockup("41-parent-thong-ke-co-muc-tieu.png", target_width=660, target_height=1440, shadow_blur=35)

    comp = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    comp.paste(left_mockup, (-220 - l_pad, 820 - l_pad), left_mockup)
    comp.paste(right_mockup, (WIDTH - 440 - r_pad, 820 - r_pad), right_mockup)
    comp.paste(center_mockup, ((WIDTH - 780)//2 - pad, 680 - pad), center_mockup)

    bg = Image.alpha_composite(bg, comp)

    paste_icon_with_shadow(bg, "jar_bank.png", (980, 560), size=160, rotation=14)
    paste_icon_with_shadow(bg, "jar_save.png", (120, 590), size=150, rotation=-14)
    paste_icon_with_shadow(bg, "gem.png", (1030, 1960), size=150, rotation=10)

    b_draw = ImageDraw.Draw(bg)
    b_draw.rounded_rectangle([(WIDTH//2 - 280, HEIGHT - 140), (WIDTH//2 + 280, HEIGHT - 64)], 38, fill="#FFF4D4")
    b_draw.text((WIDTH//2, HEIGHT - 104), "🍯 Tích lũy từng xu, vươn tới mục tiêu 🍯", fill="#906500", font=font_tagline, anchor="mm")

    out_path = os.path.join(PREVIEW_DIR, "preview_03_quan_ly_tai_chinh.png")
    bg.convert("RGB").save(out_path, "PNG", quality=95)
    print("✓ Created Preview 3: Quản Lý Tài Chính")

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

def main():
    print("=== STARTING STORE ASSET DESIGN GENERATION ===")

    # 1. Generate 3 App Previews
    generate_preview_1()
    generate_preview_2()
    generate_preview_3()

    # 2. Generate 10 App Store Screenshots
    print("\n--- Generating 10 Curated Screenshots ---")

    # Screenshot 01: Nuôi dưỡng tự lập
    generate_screenshot(
        "01_tu_lap_lam_viec_nha.png",
        "TỰ LẬP MỖI NGÀY",
        ["Nuôi Dưỡng Tính Tự Lập", "Cho Trẻ Ngay Từ Bé"],
        ["Giao diện trực quan, vui tươi giúp bé tự giác làm việc", "mà không cần bố mẹ nhắc nhở nhiều."],
        "26-child-home.png",
        theme="blue",
        icons=[("bee.png", (1040, 540), 160, 12), ("star.png", (80, 720), 140, -15)]
    )

    # Screenshot 02: Thư viện việc mẫu phong phú
    generate_screenshot(
        "02_thu_vien_viec_mau.png",
        "KHO VIỆC DỰNG SẴN",
        ["Thư Viện Nhiệm Vụ Mẫu", "Phù Hợp Mọi Độ Tuổi"],
        ["Hơn 20+ mẫu việc nhà sinh động theo từng lứa tuổi từ 3+", "giúp bố mẹ thiết lập chỉ trong 1 phút."],
        "18-them-nhiem-vu.png",
        theme="blue",
        icons=[("books.png", (1030, 560), 150, 10), ("broom.png", (80, 740), 140, -12)]
    )

    # Screenshot 03: Routine Buổi sáng / Tối
    generate_screenshot(
        "03_thoi_quen_routine.png",
        "RÈN LUYỆN NỀ NẾP",
        ["Gom Việc Theo Lịch Trình", "Thói Quen Sáng & Tối"],
        ["Thiết lập Routine rèn nề nếp buổi sáng, sau giờ học, trước khi ngủ.", "Hoàn thành trọn bộ nhận thêm xu thưởng."],
        "05-parent-nhiemvu.png",
        theme="warm",
        icons=[("sunrise.png", (1020, 560), 160, 14), ("moon.png", (80, 720), 140, -12)]
    )

    # Screenshot 04: Kho phần thưởng hấp dẫn
    generate_screenshot(
        "04_kho_phan_thuong.png",
        "ĐỘNG LỰC TÍCH CỰC",
        ["Kho Phần Thưởng Hấp Dẫn", "Khích Lệ Sự Nỗ Lực"],
        ["Đổi thời gian giải trí, sách truyện, dã ngoại cuối tuần.", "Biến sự chăm chỉ thành niềm vui trọn vẹn."],
        "32-child-phan-thuong.png",
        theme="warm",
        icons=[("popcorn.png", (1030, 560), 155, 12), ("bike.png", (70, 730), 150, -14)]
    )

    # Screenshot 05: Giáo dục tài chính 3 hũ
    generate_screenshot(
        "05_hoc_quan_ly_tai_chinh.png",
        "GIÁO DỤC TÀI CHÍNH",
        ["Học Quản Lý Tài Chính", "Qua Mô Hình 3 Hũ Xu"],
        ["Con tự phân bổ xu vào hũ Tiết kiệm, Tiêu dùng & Chia sẻ.", "Hình thành tư duy tài chính thông minh sớm."],
        "59-child-man-chia-xu.png",
        theme="warm",
        icons=[("jar_bank.png", (1040, 550), 160, 15), ("gem.png", (80, 720), 145, -12)]
    )

    # Screenshot 06: Sổ cái minh bạch
    generate_screenshot(
        "06_minh_bach_so_cai.png",
        "MINH BẠCH TUYỆT ĐỐI",
        ["Sổ Lịch Sử Chi Tiết", "Minh Bạch Từng Giao Dịch"],
        ["Mọi khoản xu cộng/trừ đều ghi rõ nguồn gốc và lý do.", "Cam kết minh bạch và tôn trọng trẻ nhỏ."],
        "63-so-lich-su-day-du.png",
        theme="blue",
        icons=[("clipboard.png", (1030, 560), 150, 10), ("money.png", (80, 740), 140, -15)]
    )

    # Screenshot 07: Hệ thống huy hiệu & vinh danh
    generate_screenshot(
        "07_huy_hieu_vinh_danh.png",
        "VINH DANH THÀNH TÍCH",
        ["Hệ Thống Huy Hiệu", "Ghi Nhận Mọi Nỗ Lực"],
        ["Mở khóa các huy hiệu Ong Chăm Chỉ, Siêu Sao Tiết Kiệm...", "Cổ vũ trẻ kiên trì từng ngày."],
        "29-child-huy-hieu.png",
        theme="blue",
        icons=[("fire.png", (1040, 550), 160, 12), ("star.png", (70, 730), 145, -15)]
    )

    # Screenshot 08: Xét duyệt thông minh
    generate_screenshot(
        "08_xet_duyet_thong_minh.png",
        "GẮN KẾT GIA ĐÌNH",
        ["Bố Mẹ Duyệt Việc Nhanh", "Kèm Bằng Chứng Ảnh Chụp"],
        ["Xem ảnh hoàn thành của con, duyệt nhanh trong 1 chạm", "và dành tặng những lời khen ấm áp."],
        "55-parent-hang-doi-duyet.png",
        theme="green",
        icons=[("heart.png", (1030, 550), 160, 14), ("clipboard.png", (80, 730), 140, -10)]
    )

    # Screenshot 09: Mục tiêu tiết kiệm & Thống kê
    generate_screenshot(
        "09_muc_tieu_tiet_kiem.png",
        "NUÔI DƯỠNG ƯỚC MƠ",
        ["Đặt Mục Tiêu Tiết Kiệm", "Theo Dõi Hành Trình"],
        ["Con đặt mục tiêu món đồ yêu thích và theo dõi tiến độ.", "Biểu đồ trực quan giúp bố mẹ thấu hiểu sự tiến bộ."],
        "41-parent-thong-ke-co-muc-tieu.png",
        theme="warm",
        icons=[("toy.png", (1040, 560), 155, 12), ("jar_save.png", (70, 730), 150, -12)]
    )

    # Screenshot 10: Ghép cặp không dây & Bảo mật
    generate_screenshot(
        "10_ghep_cap_bao_mat.png",
        "BẢO MẬT & ĐỒNG BỘ",
        ["Ghép Cặp Bằng Mã QR", "Bảo Vệ Riêng Tư Tuyệt Đối"],
        ["Kết nối máy bố mẹ và con trong vài giây qua QR.", "Mật khẩu hồ sơ riêng biệt, không thu thập dữ liệu trái phép."],
        "86-ma-qr-ghep-cap.png",
        theme="blue",
        icons=[("av_parent.png", (1030, 550), 160, 10), ("bee.png", (70, 730), 150, -12)]
    )

    print("\n=== COMPLETED ALL 3 PREVIEWS AND 10 SCREENSHOTS SUCCESSFULLY ===")

if __name__ == "__main__":
    main()

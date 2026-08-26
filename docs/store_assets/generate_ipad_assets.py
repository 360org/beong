#!/usr/bin/env python3
"""
Generate iPad 13-inch (2048 x 2732 px) screenshots for Apple App Store Connect
"""

import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

BASE_DIR = "/Volumes/DATA/DEV/MOBILES/beong"
SCREENSHOT_DIR = os.path.join(BASE_DIR, "docs/screenshot")
ASSET_ICONS_DIR = os.path.join(BASE_DIR, "assets/icons")
FONT_DIR = os.path.join(BASE_DIR, "assets/fonts")
OUTPUT_DIR = os.path.join(BASE_DIR, "docs/store_assets/ipad_screenshots")
FASTLANE_IPAD_DIR = os.path.join(BASE_DIR, "ios/fastlane/screenshots/ipad")

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(FASTLANE_IPAD_DIR, exist_ok=True)

WIDTH = 2048
HEIGHT = 2732

C_PRIMARY = "#0077CD"
C_DARK_TEXT = "#1B1046"
C_MUTED_TEXT = "#605980"

font_huge = ImageFont.truetype(os.path.join(FONT_DIR, "Nunito-ExtraBold.ttf"), 96)
font_subtitle = ImageFont.truetype(os.path.join(FONT_DIR, "Nunito-Bold.ttf"), 52)
font_badge = ImageFont.truetype(os.path.join(FONT_DIR, "Nunito-ExtraBold.ttf"), 40)

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))

def create_gradient_bg(w, h, color_top, color_bottom):
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
    overlay = Image.new("RGBA", img.size, (255, 255, 255, 0))
    draw = ImageDraw.Draw(overlay)
    w, h = img.size

    hex_color = (0, 119, 205, 14) if theme=="blue" else ((255, 197, 61, 20) if theme=="warm" else (0, 133, 28, 14))
    glow_color = (227, 242, 253, 70) if theme=="blue" else ((255, 248, 230, 80) if theme=="warm" else (230, 248, 235, 70))

    draw.ellipse([(-200, -200), (900, 900)], fill=glow_color)
    draw.ellipse([(w - 700, 500), (w + 300, 1500)], fill=glow_color)

    radius = 120
    dx = radius * math.sqrt(3)
    dy = radius * 1.5
    cols = int(w / dx) + 2
    rows = int(h / dy) + 2
    for row in range(rows):
        for col in range(cols):
            x_offset = (dx / 2) if (row % 2 == 1) else 0
            cx = col * dx + x_offset
            cy = row * dy
            draw_hexagon(draw, (cx, cy), radius * 0.88, outline=hex_color, width=3)
    return Image.alpha_composite(img, overlay)

def create_phone_mockup(screenshot_name, target_width=1100, target_height=2000, corner_radius=64, border_width=18, shadow_blur=60):
    sc_path = os.path.join(SCREENSHOT_DIR, screenshot_name)
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
    phone_draw.rounded_rectangle([(0, 0), (target_width, target_height)], corner_radius, fill=(24, 24, 30, 255), outline=(60, 60, 72, 255), width=4)
    phone_canvas.paste(scaled_screen, (border_width, border_width), screen_mask)

    pad = shadow_blur * 3
    shadow_w = target_width + pad * 2
    shadow_h = target_height + pad * 2
    shadow_canvas = Image.new("RGBA", (shadow_w, shadow_h), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_canvas)
    shadow_draw.rounded_rectangle([(pad, pad + 40), (pad + target_width, pad + target_height + 40)], corner_radius, fill=(15, 10, 35, 120))
    shadow_canvas = shadow_canvas.filter(ImageFilter.GaussianBlur(shadow_blur))

    final_mockup = Image.new("RGBA", (shadow_w, shadow_h), (0, 0, 0, 0))
    final_mockup.paste(shadow_canvas, (0, 0), shadow_canvas)
    final_mockup.paste(phone_canvas, (pad, pad), phone_canvas)
    return final_mockup, pad

def paste_icon_with_shadow(canvas, icon_name, pos, size=180, rotation=0):
    ipath = os.path.join(ASSET_ICONS_DIR, icon_name)
    if not os.path.exists(ipath):
        return
    icon = Image.open(ipath).convert("RGBA")
    icon = icon.resize((size, size), Image.Resampling.LANCZOS)
    if rotation != 0:
        icon = icon.rotate(rotation, resample=Image.Resampling.BICUBIC, expand=True)
    iw, ih = icon.size
    shadow_blur = 24
    shadow = Image.new("RGBA", (iw + shadow_blur * 2, ih + shadow_blur * 2), (0, 0, 0, 0))
    s_mask = icon.split()[3]
    shadow_color = Image.new("RGBA", (iw, ih), (25, 18, 45, 95))
    shadow.paste(shadow_color, (shadow_blur, shadow_blur + 12), s_mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(shadow_blur))
    canvas.paste(shadow, (pos[0] - shadow_blur, pos[1] - shadow_blur), shadow)
    canvas.paste(icon, pos, icon)

def generate_ipad_screenshot(filename, badge, headline_lines, subtitle_lines, screenshot_name, theme="blue", icons=None):
    bg = create_gradient_bg(WIDTH, HEIGHT, "#FFFFFF", "#F3F8FE" if theme=="blue" else ("#FEF9F0" if theme=="warm" else "#F4FAF6"))
    bg = add_decorations(bg, theme=theme)
    draw = ImageDraw.Draw(bg)

    curr_y = 150
    # Badge
    b_bg, b_fg = ("#FFF4D4", "#906500") if theme=="warm" else (("#E6F8EB", "#00851C") if theme=="green" else ("#E3F2FD", "#0077CD"))
    bbox = font_badge.getbbox(badge)
    bw = bbox[2] - bbox[0] + 64
    bh = bbox[3] - bbox[1] + 28
    bx = (WIDTH - bw) // 2
    draw.rounded_rectangle([(bx, curr_y), (bx + bw, curr_y + bh)], bh // 2, fill=b_bg)
    draw.text((WIDTH // 2, curr_y + bh // 2 - 2), badge, fill=b_fg, font=font_badge, anchor="mm")
    curr_y += bh + 42

    # Headline
    for line in headline_lines:
        draw.text((WIDTH // 2, curr_y), line, fill=C_DARK_TEXT, font=font_huge, anchor="mt")
        bbox = font_huge.getbbox(line)
        curr_y += (bbox[3] - bbox[1]) + 24

    # Subtitle
    curr_y += 10
    for sline in subtitle_lines:
        draw.text((WIDTH // 2, curr_y), sline, fill=C_MUTED_TEXT, font=font_subtitle, anchor="mt")
        bbox = font_subtitle.getbbox(sline)
        curr_y += (bbox[3] - bbox[1]) + 16

    # Mockup
    mockup_img, pad = create_phone_mockup(screenshot_name, target_width=1000, target_height=1880)
    mockup_x = (WIDTH - 1000) // 2 - pad
    mockup_y = 740 - pad
    bg.paste(mockup_img, (mockup_x, mockup_y), mockup_img)

    if icons:
        for ic_name, ic_pos, ic_size, ic_rot in icons:
            paste_icon_with_shadow(bg, ic_name, ic_pos, size=ic_size, rotation=ic_rot)

    out_path = os.path.join(OUTPUT_DIR, filename)
    bg.convert("RGB").save(out_path, "PNG", quality=95)
    fastlane_path = os.path.join(FASTLANE_IPAD_DIR, filename)
    bg.convert("RGB").save(fastlane_path, "PNG", quality=95)
    print(f"✓ Created iPad Screenshot: {filename}")

def main():
    print("=== GENERATING IPAD 13-INCH SCREENSHOTS (2048 x 2732) ===")

    generate_ipad_screenshot(
        "ipad_01_tu_lap.png",
        "TỰ LẬP MỖI NGÀY",
        ["Nuôi Dưỡng Tính Tự Lập", "Cho Trẻ Ngay Từ Bé"],
        ["Giao diện trực quan giúp bé tự giác làm việc nhà tích xu."],
        "26-child-home.png",
        theme="blue",
        icons=[("bee.png", (1580, 600), 220, 12), ("star.png", (180, 780), 200, -15)]
    )

    generate_ipad_screenshot(
        "ipad_02_viec_mau.png",
        "KHO VIỆC DỰNG SẴN",
        ["Thư Viện Nhiệm Vụ Mẫu", "Phù Hợp Mọi Độ Tuổi"],
        ["Hơn 20+ mẫu nhiệm vụ sinh động theo từng lứa tuổi từ 3+."],
        "18-them-nhiem-vu.png",
        theme="blue",
        icons=[("books.png", (1580, 620), 210, 10), ("broom.png", (180, 800), 190, -12)]
    )

    generate_ipad_screenshot(
        "ipad_03_tai_chinh.png",
        "GIÁO DỤC TÀI CHÍNH",
        ["Học Quản Lý Tài Chính", "Qua Mô Hình 3 Hũ Xu"],
        ["Con tự phân bổ xu vào hũ Tiết kiệm, Tiêu dùng & Chia sẻ."],
        "59-child-man-chia-xu.png",
        theme="warm",
        icons=[("jar_bank.png", (1580, 600), 220, 15), ("gem.png", (180, 780), 200, -12)]
    )

    generate_ipad_screenshot(
        "ipad_04_xet_duyet.png",
        "GẮN KẾT GIA ĐÌNH",
        ["Bố Mẹ Duyệt Việc Nhanh", "Kèm Bằng Chứng Ảnh Chụp"],
        ["Xem ảnh hoàn thành của con và duyệt nhanh chỉ với 1 chạm."],
        "55-parent-hang-doi-duyet.png",
        theme="green",
        icons=[("heart.png", (1580, 600), 220, 14), ("clipboard.png", (180, 800), 190, -10)]
    )

    generate_ipad_screenshot(
        "ipad_05_ghep_cap.png",
        "BẢO MẬT & ĐỒNG BỘ",
        ["Ghép Cặp Bằng Mã QR", "Bảo Vệ Riêng Tư Tuyệt Đối"],
        ["Kết nối máy bố mẹ và con trong vài giây qua mã QR an toàn."],
        "86-ma-qr-ghep-cap.png",
        theme="blue",
        icons=[("av_parent.png", (1580, 600), 220, 10), ("bee.png", (180, 800), 210, -12)]
    )

    print("=== DONE ALL IPAD SCREENSHOTS ===")

if __name__ == "__main__":
    main()

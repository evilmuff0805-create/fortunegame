#!/usr/bin/env python3
"""카피바라 파일럿 에셋 처리 (골격가이드 §1/§8/§9/§10).

① 누끼: 외곽 플러드필 — 테두리에 연결된 흰 배경만 투명화. 내부 흰색(눈 하이라이트 등)은
   외곽과 단절돼 보존된다(단순 색키잉 금지 요건 충족).
② 규격: 동물 = 2048² 마스터에 정수리 y=0.12 / 바닥 y=0.88, 좌우 중앙(§1).
        모자 = 1024×768, 하단 중앙(§8).
③ 앱 에셋: 512² 다운스케일(§1).
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

RAW = "art/raw/capybara"
MASTER = "art/master/capybara"
ITEM_MASTER = "art/master/items"
APP_ANIMAL = "assets/animals"
APP_ITEM = "assets/items"
for d in (MASTER, ITEM_MASTER, APP_ANIMAL, APP_ITEM):
    os.makedirs(d, exist_ok=True)

CANVAS = 2048
TOP, BOTTOM = 0.12, 0.88
APP = 512


def remove_white_bg(im: Image.Image, tol=44, dilate=1) -> Image.Image:
    """테두리에 연결된 배경색(흰색) 영역만 투명화. 내부 흰색 보존."""
    a = np.array(im.convert("RGBA"))
    rgb = a[:, :, :3].astype(int)
    border = np.concatenate([rgb[0, :], rgb[-1, :], rgb[:, 0], rgb[:, -1]])
    bg = np.median(border, axis=0)
    diff = np.abs(rgb - bg).max(axis=2)
    bgish = diff < tol
    lbl, _ = ndimage.label(bgish)
    border_labels = set(lbl[0, :]) | set(lbl[-1, :]) | set(lbl[:, 0]) | set(lbl[:, -1])
    border_labels.discard(0)
    mask = np.isin(lbl, list(border_labels))
    if dilate:  # 안티에일리어싱 흰 후광 제거 (어두운 아웃라인은 색차 커서 무사)
        mask = ndimage.binary_dilation(mask, iterations=dilate)
    a[mask, 3] = 0
    return Image.fromarray(a, "RGBA")


def bbox(im: Image.Image):
    ys, xs = np.where(np.array(im)[:, :, 3] > 10)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def place_animal(im: Image.Image) -> Image.Image:
    x0, y0, x1, y1 = bbox(im)
    crop = im.crop((x0, y0, x1, y1))
    target_h = round((BOTTOM - TOP) * CANVAS)
    scale = target_h / crop.height
    new_w = round(crop.width * scale)
    crop = crop.resize((new_w, target_h), Image.LANCZOS)
    out = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    out.paste(crop, (round(CANVAS / 2 - new_w / 2), round(TOP * CANVAS)), crop)
    return out


def place_hat(im: Image.Image, W=1024, H=768) -> Image.Image:
    x0, y0, x1, y1 = bbox(im)
    crop = im.crop((x0, y0, x1, y1))
    scale = min(0.92 * W / crop.width, 0.92 * H / crop.height)
    nw, nh = round(crop.width * scale), round(crop.height * scale)
    crop = crop.resize((nw, nh), Image.LANCZOS)
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    out.paste(crop, (round(W / 2 - nw / 2), H - nh - 8), crop)  # 하단 중앙
    return out


def verify(im: Image.Image, name: str):
    """§10 체크리스트 자동 항목: 정수리 0.12 / 바닥 0.88 / 중앙."""
    x0, y0, x1, y1 = bbox(im)
    h = im.height
    crown, bottom = y0 / h, y1 / h
    cx = ((x0 + x1) / 2) / im.width
    ok = abs(crown - TOP) < 0.005 and abs(bottom - BOTTOM) < 0.005 and abs(cx - 0.5) < 0.02
    print(f"  {name}: 정수리 {crown:.3f}(0.120) 바닥 {bottom:.3f}(0.880) "
          f"중심x {cx:.3f}(0.500) → {'OK' if ok else 'CHECK'}")
    return ok


ANIMALS = {
    "src_base.png": "animal_gito_base.png",     # 뉴트럴 (= face_gito_neutral)
    "src_deliver.png": "animal_gito_deliver.png",  # 봉투 전달 (§7-C)
    "src_happy.png": "face_gito_happy.png",     # 맑음·쾌청
    "src_worry.png": "face_gito_worry.png",     # 비·흐림
    "src_luck.png": "face_gito_wow.png",        # 무지개
}

print("== 동물 5종 (누끼 + 2048 재배치 + 체크리스트) ==")
allok = True
for src, out in ANIMALS.items():
    im = Image.open(os.path.join(RAW, src))
    cut = remove_white_bg(im)
    master = place_animal(cut)
    master.save(os.path.join(MASTER, out))
    master.resize((APP, APP), Image.LANCZOS).save(os.path.join(APP_ANIMAL, out))
    allok &= verify(master, out)

print("== 모자 (이미 투명 → 1024×768 하단중앙) ==")
hat = Image.open(os.path.join(RAW, "src_hat.png"))
hat_master = place_hat(hat)
hat_master.save(os.path.join(ITEM_MASTER, "item_hat_beret01.png"))
hat_master.resize((512, 384), Image.LANCZOS).save(os.path.join(APP_ITEM, "item_hat_beret01.png"))
print(f"  item_hat_beret01.png: {hat_master.size} 저장")

print("\n자동 체크리스트(정수리/바닥/중앙):", "전부 OK" if allok else "CHECK 필요")
print("(머리중심·지름·512 가독성·IP 비유사성은 시각 확인 항목)")

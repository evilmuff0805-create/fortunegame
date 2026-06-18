#!/usr/bin/env python3
"""동물 아트 처리 파이프라인 (골격가이드 §1/§9/§10) — 전 동물 공용·재현 가능.

process_capybara.py를 일반화: animal id와 raw 디렉터리만 주면 동일 파이프라인 적용.
① 외곽 플러드필 누끼(내부 흰색 보존) ② 2048 마스터(정수리0.12/바닥0.88/중심0.50) ③ 512 앱에셋
§9 네이밍: animal_{id}_base, animal_{id}_deliver, face_{id}_{happy|worry|wow}

usage: python3 art/process_animal_art.py <animal_id> <raw_dir>
  raw_dir 안에 src_base/src_happy/src_worry/src_luck/src_deliver.png
"""
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

CANVAS = 2048
TOP, BOTTOM = 0.12, 0.88
APP = 512

NAMING = {
    "src_base.png": "animal_{id}_base.png",
    "src_deliver.png": "animal_{id}_deliver.png",
    "src_happy.png": "face_{id}_happy.png",
    "src_worry.png": "face_{id}_worry.png",
    "src_luck.png": "face_{id}_wow.png",
}


def remove_white_bg(im, tol=44, dilate=1):
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
    if dilate:
        mask = ndimage.binary_dilation(mask, iterations=dilate)
    a[mask, 3] = 0
    return Image.fromarray(a, "RGBA")


def bbox(im):
    ys, xs = np.where(np.array(im)[:, :, 3] > 10)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def place_animal(im):
    x0, y0, x1, y1 = bbox(im)
    crop = im.crop((x0, y0, x1, y1))
    target_h = round((BOTTOM - TOP) * CANVAS)
    scale = target_h / crop.height
    new_w = round(crop.width * scale)
    crop = crop.resize((new_w, target_h), Image.LANCZOS)
    out = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    out.paste(crop, (round(CANVAS / 2 - new_w / 2), round(TOP * CANVAS)), crop)
    return out


def verify(im, name):
    x0, y0, x1, y1 = bbox(im)
    crown, bottom = y0 / im.height, y1 / im.height
    cx = ((x0 + x1) / 2) / im.width
    ok = abs(crown - TOP) < 0.005 and abs(bottom - BOTTOM) < 0.005 and abs(cx - 0.5) < 0.02
    white = ((np.array(im)[:, :, 3] > 200) &
             (np.array(im)[:, :, 0] >= 245) &
             (np.array(im)[:, :, 1] >= 245) &
             (np.array(im)[:, :, 2] >= 245)).sum()
    print(f"  {name}: 정수리 {crown:.3f} 바닥 {bottom:.3f} 중심 {cx:.3f} "
          f"내부흰색 {int(white)}px → {'OK' if ok else 'CHECK'}")
    return ok


def main():
    animal_id, raw = sys.argv[1], sys.argv[2]
    master = f"art/master/{animal_id}"
    app = "assets/animals"
    os.makedirs(master, exist_ok=True)
    os.makedirs(app, exist_ok=True)
    print(f"== {animal_id} 처리 ({raw}) ==")
    allok = True
    for src, tmpl in NAMING.items():
        out = tmpl.format(id=animal_id)
        im = Image.open(os.path.join(raw, src))
        m = place_animal(remove_white_bg(im))
        m.save(os.path.join(master, out))
        m.resize((APP, APP), Image.LANCZOS).save(os.path.join(app, out))
        allok &= verify(m, out)
    print("자동 체크리스트:", "전부 OK" if allok else "CHECK 필요")


if __name__ == "__main__":
    main()

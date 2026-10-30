"""Converts a screen recording into a looping animated WebP for the README.

Usage:
    python3 tool/mp4_to_webp.py IN.mp4 OUT.webp [WIDTH] [FPS] [QUALITY]

    WIDTH    output width in pixels, the height keeps the aspect ratio (540)
    FPS      frames per second sampled from the recording (15)
    QUALITY  WebP quality from 0 to 100 (90)

Needs OpenCV and Pillow: pip3 install opencv-python pillow
"""

import sys

import cv2
from PIL import Image


def main() -> None:
    if len(sys.argv) < 3:
        sys.exit(__doc__)

    src, dst = sys.argv[1], sys.argv[2]
    width = int(sys.argv[3]) if len(sys.argv) > 3 else 540
    fps = float(sys.argv[4]) if len(sys.argv) > 4 else 15
    quality = int(sys.argv[5]) if len(sys.argv) > 5 else 90

    cap = cv2.VideoCapture(src)
    src_fps = cap.get(cv2.CAP_PROP_FPS)
    if not src_fps:
        sys.exit(f"Can't read {src}")

    # Keeping a frame every 1 / fps seconds of the recording
    frames, index, next_time = [], 0, 0.0
    while True:
        ok, frame = cap.read()
        if not ok:
            break
        if index / src_fps >= next_time:
            height = round(frame.shape[0] * width / frame.shape[1])
            frame = cv2.resize(frame, (width, height), interpolation=cv2.INTER_AREA)
            frames.append(Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)))
            next_time += 1 / fps
        index += 1

    if not frames:
        sys.exit(f'No frames in {src}')

    frames[0].save(
        dst,
        'WEBP',
        save_all=True,
        append_images=frames[1:],
        duration=round(1000 / fps),
        loop=0,
        quality=quality,
        method=6,
    )
    print(f'{dst}: {len(frames)} frames, {frames[0].width}x{frames[0].height}')


if __name__ == '__main__':
    main()

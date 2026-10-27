# Demo clips

The README shows these clips from GitHub (`raw.githubusercontent.com/.../master/doc/demo/`),
so they're kept out of the published package by `.pubignore`.

Record each clip from the example app on the same device at the same size,
then replace the placeholder with the same file name.

| File | Example app | What to show |
|---|---|---|
| `sliding.webp` | **Sliding toasts** | Simple, glassy, and image-decorated toasts |
| `status.webp` | **Status toasts** | Success and error toasts, then tap the long message to open its dialog |
| `popup.webp` | **Popup toasts** | Popup toasts, tap the bottom one to change the theme color |
| `all_at_once.webp` | **All at once** + **Show five toasts** | Every toast shows right away |
| `one_by_one.webp` | **One by one** + **Show five toasts** | Toasts take turns, the badge counting down |
| `stacked.webp` | **Stacked** + **Show five toasts** | The stack building up, then tap it to spread it out |

## Converting a screen recording

`tool/mp4_to_webp.py` turns a recording into a looping animated WebP, usually several times
smaller than a GIF of the same quality. It needs OpenCV and Pillow (`pip3 install opencv-python pillow`).
Run it from the repository root:

```sh
# README clips: 360 px wide, 15 fps
python3 tool/mp4_to_webp.py ~/Desktop/sliding.mp4 doc/demo/sliding.webp

# pub.dev screenshots ship with the package, so they're smaller: 280 px, 10 fps, quality 60
python3 tool/mp4_to_webp.py ~/Desktop/stacked.mp4 doc/screenshots/stacked.webp 280 10 60
```

With [ffmpeg](https://ffmpeg.org) installed, this does the same:

```sh
ffmpeg -i sliding.mp4 -vf "fps=15,scale=360:-1" -loop 0 -quality 70 doc/demo/sliding.webp
```

## pub.dev screenshots

`doc/screenshots/` holds the screenshots listed under `screenshots:` in `pubspec.yaml`,
shown in the gallery on pub.dev. Unlike the clips here, they ship with the package,
so keep them few and small. Copy the matching clips there once they're recorded.

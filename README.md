# Video Encoding Comparison Tool

This project provides a Bash + HTML-based visual framework to **compare the quality of multiple video encodings**. It lets you extract reference frames from `.mp4` files, display them in carousels, and rate them manually by sharpness, pixelation, and color fidelity. Summary scores are then computed automatically.

---

## 📦 Features

- Extract 10 consistent random or fixed frames from each video
- Generate a standalone HTML comparison interface
- Rate each frame interactively (ratings are saved to localStorage)
- View average scores per video and per criterion
- See codec, resolution, frame rate, pixel format, bitrate and file size for each encoding

---

## 🛠️ Requirements

- Linux or WSL2
- Bash
- [ffmpeg](https://ffmpeg.org/download.html)
- [ffprobe](https://ffmpeg.org/download.html)

Ensure `ffmpeg` and `ffprobe` are accessible from your shell. Otherwise, install via your package manager:

```bash
sudo apt install ffmpeg
```

---

## 🚀 Usage

1. Place all `.mp4` files you want to compare into a folder (e.g. `bigbuckbunny/`)
2. Run the script:

```bash
chmod +x extract_reference_frames.sh
./extract_reference_frames.sh
```

3. Follow the prompts:
   - Choose your source folder and output directory
   - Choose whether to extract frames and/or generate HTML
   - Choose extraction mode (fixed or consistent random timestamps)
   - Optionally overwrite existing frames without confirmation

4. Open the generated HTML file (e.g. `bigbuckbunny/frames/compare.html`) in your browser.

---

## 📊 How to Interpret Results

- Click stars to rate each frame's **Sharpness**, **Pixelation**, and **Color**
- Ratings are saved per image locally in your browser (`localStorage`)
- Average scores are automatically calculated per video
- Each video displays:
  - File size (e.g. `1.5G`)
  - Codec details (e.g. `H264 Main @ 1920x1080 / 30 fps / yuv420p / 19306 kbps`)

---

## 📁 Output Structure

```text
bigbuckbunny/
├── video1.mp4
├── video2.mp4
└── frames/
    ├── video1/
    │   ├── frame_01.png
    │   └── ...
    ├── video2/
    │   └── ...
    └── compare.html
```

---

## 📖 Notes

- **Ratings are preserved** as long as `localStorage` is not cleared in the browser.
- You can regenerate the HTML file safely without losing your ratings.
- All file paths are relative and work offline.

---

## 🪪 License

MIT License

> © 2025 Germain Metti. Free for personal and commercial use with attribution.

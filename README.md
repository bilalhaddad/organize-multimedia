# Organize Multimedia

A Bash script to organize and deduplicate photos and videos into a clean `YYYY/MM/DD` folder structure.

## ✨ Features

- Organizes photos/videos by **EXIF date** or **creation date**
- Deduplicates files using **MD5 checksum**
- Renames conflicting files automatically
- Cleans up empty folders and temporary files

## 📦 Dependencies

- `bash`
- `find`
- `md5sum`
- `identify` (ImageMagick)
- `ffprobe` (FFmpeg)

## 🚀 Usage

```bash
chmod +x organize.sh
./organize.sh /path/to/source /path/to/destination

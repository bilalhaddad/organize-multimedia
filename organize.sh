#!/bin/bash

# ========== CONFIG ==========
cfgSource="${1:-$PWD}"
cfgDestRoot="${2:-$PWD/../organized}"
TMPFILE=$(mktemp)

# ========== DEPENDENCY CHECK ==========
for cmd in identify ffprobe stat md5sum; do
    if ! command -v "$cmd" > /dev/null; then
        echo "❌ Error: '$cmd' is not installed. Please install it and retry."
        exit 1
    fi
done

# ========== FUNCTIONS ==========
get_file_date() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"  # lowercase

    if [[ "$ext" =~ ^(jpg|jpeg|png|nef|bmp)$ ]]; then
        # Try EXIF date for images
        local exif_date
        exif_date=$(identify -format '%[EXIF:DateTimeOriginal]' "$file" 2>/dev/null | sed 's/:/-/g; s/ /_/g')
        [[ -n "$exif_date" ]] && echo "$exif_date" | cut -d_ -f1 && return
    elif [[ "$ext" =~ ^(mp4|mov|avi|webm|m4v|flv|vob|mpg)$ ]]; then
        # Try creation_time for videos
        local video_date
        video_date=$(ffprobe -v quiet -show_entries format_tags=creation_time \
            -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null | cut -d'T' -f1)
        [[ -n "$video_date" ]] && echo "$video_date" && return
    fi

    # Fallback to modification time
    date -r "$file" "+%Y-%m-%d"
}

# ========== MAIN ==========
echo "📁 Organizing files from: $cfgSource"
echo "📂 Destination root: $cfgDestRoot"
echo "🧪 Scanning for media files..."

# Find supported media files
find "$cfgSource" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.nef" -o -iname "*.bmp" -o \
  -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.webm" -o -iname "*.m4v" -o \
  -iname "*.flv" -o -iname "*.vob" -o -iname "*.mpg" \) > "$TMPFILE"

while IFS= read -r f; do
    [[ ! -f "$f" ]] && { echo "⚠️ Skipping missing file: $f"; continue; }

    date_str=$(get_file_date "$f")
    if [[ ! "$date_str" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "❌ Could not extract valid date from: $f"
        continue
    fi

    y=$(echo "$date_str" | cut -d- -f1)
    m=$(echo "$date_str" | cut -d- -f2)
    d=$(echo "$date_str" | cut -d- -f3)

    destDir="$cfgDestRoot/$y/$m/$d"
    mkdir -p "$destDir"

    base=$(basename "$f")
    destFile="$destDir/$base"

    if [[ -f "$destFile" ]]; then
        md5_src=$(md5sum "$f" | awk '{print $1}')
        md5_dst=$(md5sum "$destFile" | awk '{print $1}')

        if [[ "$md5_src" == "$md5_dst" ]]; then
            echo "🔁 Duplicate found: $f == $destFile — deleting source"
            rm -f "$f"
        else
            ts=$(date +%s)
            new_name="${ts}_$base"
            echo "⚠️ Conflict: Renaming $base to $new_name"
            mv -f "$f" "$destDir/$new_name"
        fi
    else
        mv -f "$f" "$destFile"
        echo "✅ Moved: $f → $destFile"
    fi
done < "$TMPFILE"

# Cleanup
echo "🧹 Cleaning temporary files and empty folders..."
find "$cfgSource" -type f \( -iname "*.ds_store" -o -iname "*.thm" -o -iname "*.ind" -o -iname "thumbs.db" \) -delete
find "$cfgSource" -type d -empty -delete
rm -f "$TMPFILE"

echo "🎉 Done organizing media!"

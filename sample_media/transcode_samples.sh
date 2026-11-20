#!/usr/bin/env bash
# MediaVerse: Batch transcode test videos to standardized 720p H.264 / AAC
set -euo pipefail

INPUT_DIR="./raw_media"
OUTPUT_DIR="./standardized_media"

mkdir -p "$OUTPUT_DIR"

for file in "$INPUT_DIR"/*.mp4; do
  [ -e "$file" ] || continue
  filename=$(basename "$file")
  echo "Transcoding: $filename..."
  ffmpeg -y -i "$file" \
    -vf "scale=-2:720" \
    -c:v libx264 -preset fast -crf 23 \
    -c:a aac -b:a 128k -ac 2 \
    -movflags +faststart \
    "$OUTPUT_DIR/${filename%.*}_720p.mp4"
done

echo "Transcoding completed. Assets ready for S3 upload."
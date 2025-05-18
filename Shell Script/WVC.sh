#!/bin/bash

echo "[WVC - INFO] Starting Task..."

# 1. Get the file name from the first argument and store in variable "infile"
infile="$1"

if [[ ! -f "$infile" ]]; then
  echo "[WVC - ERR] File '$infile' not found!"
  exit 1
fi
echo "[WVC - INFO] Processed Input File."

# 2. Remove lines starting with '#' and save to link.txt
grep -v "^#" "$infile" > link.txt
echo "[WVC - INFO] Processed Links to Download."

# 3. Copy infile to work.m3u8
cp "$infile" work.m3u8
echo "[WVC - INFO] Processed Work Files."

# 4. Keep only the actual .ts filename in work.m3u8 (remove everything else)
sed -i -E 's#.*/([^/?&]+\.ts).*#\1#' work.m3u8
echo "[WVC - INFO] Processed Playlist File."

# 5. Download files listed in link.txt using wget
echo "[WVC - INFO] Downloading Media Files. (This might take a while!)"
wget -q -i link.txt
echo "[WVC - INFO] Successfully Downloaded All Media Files."

# 6. Rename all files
for file in *.ts*; do
  mv "$file" "${file%%.ts*}.ts"
done
echo "[WVC - INFO] Processed File Names."

# 7. Get total file numbers
echo "[WVC - INFO] Verifying total file number..."

totfile=$(grep -oE 'media_[0-9]+' link.txt | sed 's/media_//' | sort -n | tail -1)

echo "[WVC - INFO] Total Media Files: $((max_number + 1))"

# 8. Check if some of the files are missing, report and stop the script if found any
echo "[WVC - INFO] Verifying Media Files..."

for i in $(seq 0 "$totfile"); do
    file="media_$i.ts"

    if [ ! -f "$file" ]; then
        echo "[WVC - ERR] $file is missing"
        missingfile=$((missingfile + 1))
    elif [ ! -s "$file" ]; then
        echo "[WVC - WARN] $file is partially downloaded (zero bytes)"
        partdownfile=$((partdownfile + 1))
    fi
done

echo "[WVC - INFO] Total Missing File: $((missingfile))"
echo "[WVC - INFO] Total Partialy Downloaded File: $((partdownfile))"

# Stop if any files are missing or broken
if [[ "$missingfile" -gt 0 || "$partdownfile" -gt 0 ]]; then
    echo "[WVC - ERR] Aborting Task Due To Missing Or Incomplete Files."
    exit 1
fi

# 9. Run ffmpeg to combine and decode to movie.mp4
ffmpeg -loglevel error -protocol_whitelist file,crypto -allowed_extensions ALL -i work.m3u8 -c copy movie.mp4

echo "[WVC - INFO] Task Completed."

#!/bin/bash

# Usage: ./update_images.sh /path/to/images /path/to/wedding-website.html

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <images_directory> <html_file>"
    exit 1
fi

IMAGES_DIR="$1"
HTML_FILE="$2"

# Check if the images directory exists
if [ ! -d "$IMAGES_DIR" ]; then
    echo "Error: Images directory does not exist"
    exit 1
fi

# Check if the HTML file exists
if [ ! -f "$HTML_FILE" ]; then
    echo "Error: HTML file does not exist"
    exit 1
fi

# Count the number of images first
IMAGE_FILES=()

# Use numerical sorting for images that start with numbers
while IFS= read -r -d '' file; do
    IMAGE_FILES+=("$file")
done < <(find "$IMAGES_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) -print0 | sort -z -V)

IMAGE_COUNT=${#IMAGE_FILES[@]}
echo "Found $IMAGE_COUNT images"

# Create temporary files
TEMP_HTML=$(mktemp)
SLIDESHOW_TEMP=$(mktemp)
DOTS_TEMP=$(mktemp)

# Generate slideshow HTML
echo '    <div class="slideshow-container">' > "$SLIDESHOW_TEMP"
echo '        <div class="navigation-overlay prev-overlay" onclick="prevSlide()"></div>' >> "$SLIDESHOW_TEMP"
echo '        <div class="navigation-overlay next-overlay" onclick="nextSlide()"></div>' >> "$SLIDESHOW_TEMP"

for i in "${!IMAGE_FILES[@]}"; do
    img="${IMAGE_FILES[$i]}"
    
    # Get image dimensions using identify from ImageMagick
    if command -v identify &> /dev/null; then
        DIMENSIONS=$(identify -format "%w/%h" "$img" 2>/dev/null)
        WIDTH=$(echo "$DIMENSIONS" | cut -d'/' -f1)
        HEIGHT=$(echo "$DIMENSIONS" | cut -d'/' -f2)
    else
        # Default dimensions if identify is not available
        WIDTH=800
        HEIGHT=400
    fi
    
    # Set the first image as active
    if [ $i -eq 0 ]; then
        CLASS="slide active"
    else
        CLASS="slide"
    fi
    
    # Extract caption from filename (after the underscore)
    FILENAME=$(basename "$img")
    CAPTION=""
    if [[ $FILENAME =~ [0-9]+_(.+)\..+ ]]; then
        CAPTION="${BASH_REMATCH[1]}"
        # Replace underscores with spaces
        CAPTION="${CAPTION//_/ }"
    fi
    
    # Add the image and caption to the slideshow
    echo "        <div class=\"slide-container\">" >> "$SLIDESHOW_TEMP"
    echo "            <img class=\"$CLASS\" src=\"$img\" alt=\"Couple photo\" width=\"$WIDTH\" height=\"$HEIGHT\">" >> "$SLIDESHOW_TEMP"
    if [ -n "$CAPTION" ]; then
        echo "            <div class=\"caption\">$CAPTION</div>" >> "$SLIDESHOW_TEMP"
    fi
    echo "        </div>" >> "$SLIDESHOW_TEMP"
done

echo '    </div>' >> "$SLIDESHOW_TEMP"

# Generate dots HTML
echo '    <div class="dot-container">' > "$DOTS_TEMP"

for ((i=0; i<IMAGE_COUNT; i++)); do
    if [ $i -eq 0 ]; then
        echo "        <span class=\"dot active-dot\" onclick=\"currentSlide($i)\"></span>" >> "$DOTS_TEMP"
    else
        echo "        <span class=\"dot\" onclick=\"currentSlide($i)\"></span>" >> "$DOTS_TEMP"
    fi
done

echo '    </div>' >> "$DOTS_TEMP"

# Create a marker for our processing
SLIDESHOW_START_MARKER="<!--SLIDESHOW_START-->"
SLIDESHOW_END_MARKER="<!--SLIDESHOW_END-->"
DOTS_START_MARKER="<!--DOTS_START-->"
DOTS_END_MARKER="<!--DOTS_END-->"

# First add markers to the original file if they don't exist
if ! grep -q "$SLIDESHOW_START_MARKER" "$HTML_FILE"; then
    sed -i "s/<div class=\"slideshow-container\">/$SLIDESHOW_START_MARKER\n<div class=\"slideshow-container\">/" "$HTML_FILE"
    # Find the closing div for slideshow
    LINE_NUM=$(grep -n "<div class=\"slideshow-container\">" "$HTML_FILE" | cut -d: -f1)
    # Count opening and closing divs to find the matching closing div
    sed -i "$((LINE_NUM+1)),/<\/div>/ {
        /<\/div>/ {
            s/<\/div>/<\/div>\n$SLIDESHOW_END_MARKER/
            t done
        }
        b
        :done
        q
    }" "$HTML_FILE"
fi

if ! grep -q "$DOTS_START_MARKER" "$HTML_FILE"; then
    sed -i "s/<div class=\"dot-container\">/$DOTS_START_MARKER\n<div class=\"dot-container\">/" "$HTML_FILE"
    # Find the closing div for dots
    LINE_NUM=$(grep -n "<div class=\"dot-container\">" "$HTML_FILE" | cut -d: -f1)
    # Insert end marker after the closing div
    sed -i "$((LINE_NUM+1)),/<\/div>/ {
        /<\/div>/ {
            s/<\/div>/<\/div>\n$DOTS_END_MARKER/
            t done
        }
        b
        :done
        q
    }" "$HTML_FILE"
fi

# Now replace everything between markers
sed -e "/$SLIDESHOW_START_MARKER/,/$SLIDESHOW_END_MARKER/{ /$SLIDESHOW_START_MARKER/{p; r $SLIDESHOW_TEMP
        }; /$SLIDESHOW_END_MARKER/p; d; }" "$HTML_FILE" > "$TEMP_HTML"

# Replace dots section
sed -e "/$DOTS_START_MARKER/,/$DOTS_END_MARKER/{ /$DOTS_START_MARKER/{p; r $DOTS_TEMP
        }; /$DOTS_END_MARKER/p; d; }" "$TEMP_HTML" > "${TEMP_HTML}.2"

# Backup the original file
cp "$HTML_FILE" "${HTML_FILE}.bak"

# Replace the original file with the modified version
mv "${TEMP_HTML}.2" "$HTML_FILE"

# Clean up
rm -f "$SLIDESHOW_TEMP" "$DOTS_TEMP" "$TEMP_HTML"

echo "Slideshow and dots updated with $IMAGE_COUNT images from $IMAGES_DIR"

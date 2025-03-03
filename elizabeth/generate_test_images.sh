#!/bin/bash

# Usage: ./generate_test_images.sh <output_directory> <html_file> [number_of_images]

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <output_directory> <html_file> [number_of_images]"
    exit 1
fi

OUTPUT_DIR="$1"
HTML_FILE="$2"
NUM_IMAGES=${3:-10}  # Default to 10 images if not specified

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed. Please install it first."
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Array of possible background colors
COLORS=("DodgerBlue" "Coral" "SpringGreen" "Violet" "Gold" "DeepPink" "MediumTurquoise" "OrangeRed" "YellowGreen" "SlateBlue")

# Array of possible dimensions (width x height)
DIMENSIONS=(
    "800x400"  # Landscape
    "800x600"  # Landscape
    "400x600"  # Portrait
    "350x650"  # Portrait
    "600x600"  # Square
)

echo "Generating $NUM_IMAGES test images..."

# Generate random test images
for ((i=1; i<=NUM_IMAGES; i++)); do
    # Pick a random color and dimension
    COLOR=${COLORS[$(($RANDOM % ${#COLORS[@]}))]}
    DIMENSION=${DIMENSIONS[$(($RANDOM % ${#DIMENSIONS[@]}))]}
    
    # Extract width and height from dimension
    WIDTH=$(echo $DIMENSION | cut -d'x' -f1)
    HEIGHT=$(echo $DIMENSION | cut -d'x' -f2)
    
    # Determine orientation for text
    if [ $WIDTH -ge $HEIGHT ]; then
        ORIENTATION="Landscape"
    else
        ORIENTATION="Portrait"
    fi
    
    # Generate a unique filename
    FILENAME="$OUTPUT_DIR/wedding_test_image_${i}_${DIMENSION}.jpg"
    
    # Create the image with text
    convert -size $DIMENSION xc:$COLOR \
        -fill white -pointsize 40 -gravity center \
        -draw "text 0,0 'Anish & Elizabeth'" \
        -pointsize 30 \
        -draw "text 0,70 'Test Image #${i}'" \
        -draw "text 0,120 '${DIMENSION} (${ORIENTATION})'" \
        -draw "text 0,170 '${COLOR}'" \
        "$FILENAME"
        
    echo "Created: $FILENAME"
done

echo "All test images generated successfully in $OUTPUT_DIR"

# Now run the script to update the HTML with these images
if [ -f "./update_images.sh" ]; then
    echo "Updating HTML with the generated images..."
    ./update_images.sh "$OUTPUT_DIR" "$HTML_FILE"
else
    echo "Warning: update_images.sh not found in current directory."
    echo "You'll need to run it manually to update your HTML:"
    echo "./update_images.sh $OUTPUT_DIR $HTML_FILE"
fi

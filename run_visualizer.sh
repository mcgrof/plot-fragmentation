#!/bin/bash
# Wrapper to run visualizer with timeout for large files

TIMEOUT=${TIMEOUT:-300}  # 5 minutes default
INPUT="$1"
OUTPUT="$2"

if [ -z "$INPUT" ] || [ -z "$OUTPUT" ]; then
    echo "Usage: $0 <input.json> <output.png>"
    exit 1
fi

echo "Processing $INPUT -> $OUTPUT (timeout: ${TIMEOUT}s)..."

# Check if output already exists
if [ -f "$OUTPUT" ]; then
    echo "Output already exists: $OUTPUT"
    exit 0
fi

# Try to run with timeout
timeout $TIMEOUT python3 ./fragmentation_visualizer.py "$INPUT" -o "$OUTPUT" 2>&1

if [ $? -eq 124 ]; then
    echo "Warning: Processing timed out after ${TIMEOUT}s"
    echo "The file contains too many events for quick processing."
    echo "Using pre-generated image from images/ directory instead."

    # Try to use pre-generated image
    basename=$(basename "$OUTPUT")
    if [ -f "images/$basename" ]; then
        cp "images/$basename" "$OUTPUT"
        echo "Copied pre-generated image to $OUTPUT"
    else
        echo "No pre-generated image found for $basename"
        exit 1
    fi
else
    echo "Successfully generated $OUTPUT"
fi
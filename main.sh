#!/bin/bash
set -e  # Exit on error

# Usage function
function usage {
    echo "Usage: $0 [OPTIONS] INPUT_DIR OUTPUT_FILE"
    echo "Concatenate all text files from INPUT_DIR recursively into a single OUTPUT_FILE"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -p, --pattern   File pattern to include (default: '*.md,*.txt,*.mdx')"
    echo "                  Comma-separated list of patterns"
    echo "  -t, --title     Add a title to the output file (default: 'DOCS')"
    echo "  -s, --separator String to use as separator between files (default: '---')"
    echo "  -n, --no-path   Don't include file paths in the output"
    echo "  -v, --verbose   Show verbose output"
    echo "  -f, --no-frontmatter  Strip frontmatter from markdown files"
    echo "  -c, --clean     Remove HTML tags and special formatting"
    exit 1
}

# Error handling
function error_exit {
    echo "ERROR: $1" >&2
    exit 1
}

# Default values
PATTERN="*.md,*.txt,*.mdx"
TITLE="DOCS"
SEPARATOR="---"
SHOW_PATH=true
VERBOSE=false
STRIP_FRONTMATTER=false
CLEAN_HTML=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -p|--pattern)
            [[ -z "$2" ]] && error_exit "Pattern option requires an argument"
            PATTERN="$2"
            shift 2
            ;;
        -t|--title)
            [[ -z "$2" ]] && error_exit "Title option requires an argument"
            TITLE="$2"
            shift 2
            ;;
        -s|--separator)
            [[ -z "$2" ]] && error_exit "Separator option requires an argument"
            SEPARATOR="$2"
            shift 2
            ;;
        -n|--no-path)
            SHOW_PATH=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--no-frontmatter)
            STRIP_FRONTMATTER=true
            shift
            ;;
        -c|--clean)
            CLEAN_HTML=true
            shift
            ;;
        *)
            if [[ -z "$INPUT_DIR" ]]; then
                INPUT_DIR="$1"
            elif [[ -z "$OUTPUT_FILE" ]]; then
                OUTPUT_FILE="$1"
            else
                error_exit "Unexpected argument: $1"
            fi
            shift
            ;;
    esac
done

# Check if required arguments are provided
if [[ -z "$INPUT_DIR" || -z "$OUTPUT_FILE" ]]; then
    error_exit "Input directory and output file are required"
fi

# Check if input directory exists
if [[ ! -d "$INPUT_DIR" ]]; then
    error_exit "Input directory does not exist: $INPUT_DIR"
fi

# Check if output directory exists
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [[ ! -d "$OUTPUT_DIR" && "$OUTPUT_DIR" != "." ]]; then
    if $VERBOSE; then
        echo "Creating output directory: $OUTPUT_DIR"
    fi
    mkdir -p "$OUTPUT_DIR" || error_exit "Failed to create output directory: $OUTPUT_DIR"
fi

if $VERBOSE; then
    echo "Starting concatenation process..."
    echo "Input directory: $INPUT_DIR"
    echo "Output file: $OUTPUT_FILE"
    echo "File patterns: $PATTERN"
    if $STRIP_FRONTMATTER; then
        echo "Stripping frontmatter: Yes"
    fi
    if $CLEAN_HTML; then
        echo "Cleaning HTML: Yes"
    fi
fi

# Clear the output file and add header
echo "# $TITLE" > "$OUTPUT_FILE" || error_exit "Failed to write to output file"
echo "" >> "$OUTPUT_FILE"
echo "Generated on $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "$SEPARATOR" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Build find command with multiple patterns
IFS=',' read -ra PATTERN_ARRAY <<< "$PATTERN"
FIND_EXPR=()
for p in "${PATTERN_ARRAY[@]}"; do
    FIND_EXPR+=(-o -name "$p")
done

# Remove the first -o from the array
FIND_EXPR=("${FIND_EXPR[@]:1}")

# Get the matching files into an array to avoid subshell issues (POSIX-compatible)
FILES=()
while IFS= read -r line; do
    FILES+=("$line")
done < <(find "$INPUT_DIR" -type f \( "${FIND_EXPR[@]}" \) | sort)

# Count files
FILE_COUNT=${#FILES[@]}
if $VERBOSE; then
    echo "Found $FILE_COUNT files to process"
fi

# Process all matching files
for ((i=0; i<FILE_COUNT; i++)); do
    FILE="${FILES[$i]}"
    
    # Get relative path
    REL_PATH=${FILE#$INPUT_DIR/}
    
    if $VERBOSE; then
        echo "[$(($i+1))/$FILE_COUNT] Processing: $REL_PATH"
    fi
    
    # Add file info header
    if [[ "$SHOW_PATH" = true ]]; then
        echo "## File: $REL_PATH" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
    
    # Process file content based on options
    if [[ "$STRIP_FRONTMATTER" = true && ("$FILE" == *.md || "$FILE" == *.mdx) ]]; then
        # Strip frontmatter (content between --- lines at the beginning of the file)
        awk 'BEGIN{f=0} /^---$/{f=!f;next} f{next} {print}' "$FILE" > /tmp/file_content
    else
        # Just copy the file as is
        cat "$FILE" > /tmp/file_content
    fi
    
    # Clean HTML if requested
    if [[ "$CLEAN_HTML" = true ]]; then
        # Remove HTML tags, JSX components and special formatting
        sed -i'' -e 's/<[^>]*>//g' /tmp/file_content
        sed -i'' -e 's/\${[^}]*}//g' /tmp/file_content
        sed -i'' -e '/^<.*>$/d' /tmp/file_content
    fi
    
    # Append processed content to output file
    cat /tmp/file_content >> "$OUTPUT_FILE" || error_exit "Failed to read file: $FILE"
    rm /tmp/file_content
    
    # Add separator
    echo "" >> "$OUTPUT_FILE"
    echo "$SEPARATOR" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

# Print summary
echo "Concatenation complete: $OUTPUT_FILE"
echo "Total lines: $(wc -l < "$OUTPUT_FILE")"
echo "Size: $(du -h "$OUTPUT_FILE" | cut -f1) ($(wc -c < "$OUTPUT_FILE") bytes)"

# Make the script executable
chmod +x "$0" 
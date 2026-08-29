#!/bin/bash

set -euo pipefail

# ------------------------------------------------------------
# (photos) make & post script
#
# Prepare and publish photographs to a (photos) instance
#
# Default:
#   photos .
#   photos IMG_6311.jpg
#
# Performs both MAKE and POST.
#
# Modes:
#   --make     Create and optimize photos only
#   --post     Upload prepared photos only
#
# The positional argument can be either:
#   directory
#   single .jpg/.jpeg file
#
# ------------------------------------------------------------


# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------

THUMB_SIZE=400
QUALITY=85

FORCE=false
DRY_RUN=false
VERBOSE=false

MAKE=false
POST=false

TARGET="."


# ------------------------------------------------------------
# Functions
# ------------------------------------------------------------

usage() {
    cat <<EOF
Usage:
  photos [options] [file|directory]

Modes:
  --make              Create and optimize photos
  --post              Upload prepared photos
  (no mode specified) Make and post

Options:
  --size SIZE         Thumbnail long edge (default: 400)
  --quality QUALITY   JPEG quality, 0-100 (default: 85)
  --force             Overwrite existing thumbnails
  --dryrun           Show what would happen without changing/uploading
  --verbose           Show detailed output
  -h, --help          Show this help

Examples:
  photos .
  photos IMG_6311.jpg
  photos IMG_6311.jpeg
  photos --make .
  photos --post .
  photos --make IMG_6311.jpg
  photos --post IMG_6311.jpg
  photos --make --post IMG_6311.jpg
  photos --dryrun --verbose .
EOF
}


log() {
    echo "$*"
}


verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo "  $*"
    fi
}


error() {
    echo "Error: $*" >&2
    exit 1
}


is_valid_quality() {
    [[ "$1" =~ ^[0-9]+$ ]] && \
        (( "$1" >= 0 && "$1" <= 100 ))
}


is_valid_size() {
    [[ "$1" =~ ^[0-9]+$ ]] && \
        (( "$1" > 0 ))
}


check_dependencies() {

    if [[ "$MAKE" == true ]]; then

        command -v magick >/dev/null 2>&1 || \
            error "ImageMagick is not installed. Install it with: brew install imagemagick"

        command -v jpegoptim >/dev/null 2>&1 || \
            error "jpegoptim is not installed. Install it with: brew install jpegoptim"

        command -v exiftool >/dev/null 2>&1 || \
            error "ExifTool is not installed. Install it with: brew install exiftool"

    fi


    if [[ "$POST" == true ]]; then

        command -v sftp >/dev/null 2>&1 || \
            error "sftp is not available."

    fi
}


# ------------------------------------------------------------
# Get DateTimeOriginal
# ------------------------------------------------------------

get_date_time_original() {

    local file="$1"

    exiftool \
        -s3 \
        -DateTimeOriginal \
        "$file"
}


# ------------------------------------------------------------
# Remove all metadata except DateTimeOriginal
# ------------------------------------------------------------

clean_metadata() {

    local file="$1"
    local date_time_original

    date_time_original="$(
        get_date_time_original "$file" 2>/dev/null || true
    )"


    if [[ -n "$date_time_original" ]]; then

        verbose "Preserving DateTimeOriginal → $date_time_original"

        exiftool \
            -all= \
            "-EXIF:DateTimeOriginal=$date_time_original" \
            -overwrite_original \
            "$file"

    else

        verbose "No DateTimeOriginal found"

        exiftool \
            -all= \
            -overwrite_original \
            "$file"

    fi
}


# ------------------------------------------------------------
# Optimize JPEG
# ------------------------------------------------------------

optimize_image() {

    local file="$1"

    clean_metadata "$file"

    jpegoptim \
        --max="$QUALITY" \
        --overwrite \
        "$file"
}


# ------------------------------------------------------------
# Process a single image
# ------------------------------------------------------------

process_image() {

    local source="$1"

    local basename
    basename="$(basename "$source")"

    local filename
    filename="${basename%.*}"

    local output
    output="$DIRECTORY/$filename.jpg"

    local thumbnail
    thumbnail="$DIRECTORY/thumb/$filename.jpg"


    echo ""
    log "Processing: $basename"


    # --------------------------------------------------------
    # Normalize .jpeg → .jpg
    # --------------------------------------------------------

    if [[ "$source" != "$output" ]]; then

        if [[ -e "$output" && "$FORCE" != true ]]; then

            error "Output already exists: $filename.jpg (use --force to overwrite)"

        fi

        verbose "Rename → $filename.jpg"

        if [[ "$DRY_RUN" != true ]]; then

            mv "$source" "$output"

        fi

    fi


    # --------------------------------------------------------
    # Create thumb directory
    # --------------------------------------------------------

    if [[ "$DRY_RUN" != true ]]; then

        mkdir -p "$DIRECTORY/thumb"

    else

        verbose "Create → thumb/"

    fi


    # --------------------------------------------------------
    # Check thumbnail
    # --------------------------------------------------------

    if [[ -e "$thumbnail" && "$FORCE" != true ]]; then

        error "Thumbnail already exists: thumb/$filename.jpg (use --force to overwrite)"

    fi


    # --------------------------------------------------------
    # Optimize original
    # --------------------------------------------------------

    verbose "Optimizing original → JPEG quality $QUALITY"

    if [[ "$DRY_RUN" != true ]]; then

        optimize_image "$output"

    fi


    # --------------------------------------------------------
    # Create thumbnail
    # --------------------------------------------------------

    verbose "Thumbnail → thumb/$filename.jpg"
    verbose "Maximum dimension → ${THUMB_SIZE}px"

    if [[ "$DRY_RUN" != true ]]; then

        magick "$output" \
            -resize "${THUMB_SIZE}x${THUMB_SIZE}>" \
            "$thumbnail"

    fi


    # --------------------------------------------------------
    # Optimize thumbnail
    # --------------------------------------------------------

    verbose "Optimizing thumbnail → JPEG quality $QUALITY"

    if [[ "$DRY_RUN" != true ]]; then

        optimize_image "$thumbnail"

    fi


    log "✓ $filename.jpg"
}


# ------------------------------------------------------------
# Upload files via SFTP
# ------------------------------------------------------------

upload_files() {

    echo ""
    log "Uploading files …"
    echo ""


    [[ -n "${POSTPHOTO_SFTP_HOST:-}" ]] || \
        error "POSTPHOTO_SFTP_HOST is not configured. Please set it as an environment variable in your bash configuration."


    [[ -n "${POSTPHOTO_REMOTE_DIRECTORY:-}" ]] || \
        error "POSTPHOTO_REMOTE_DIRECTORY is not configured. Please set it as an environment variable in your bash configuration."


    local sftp_host
    sftp_host="$POSTPHOTO_SFTP_HOST"

    local remote_directory
    remote_directory="$POSTPHOTO_REMOTE_DIRECTORY"


    local sftp_batch
    sftp_batch="$(mktemp)"


    trap 'rm -f "$sftp_batch"' EXIT


    # --------------------------------------------------------
    # Upload originals
    # --------------------------------------------------------

    for image in "${images[@]}"; do

        local basename
        basename="$(basename "$image")"

        local filename
        filename="${basename%.*}"

        local local_file
        local_file="$DIRECTORY/$filename.jpg"

        local remote_file
        remote_file="$remote_directory/$filename.jpg"


        if [[ ! -f "$local_file" ]]; then

            error "Prepared file does not exist: $local_file"

        fi


        verbose "Upload → $remote_file"

        printf 'put "%s" "%s"\n' \
            "$local_file" \
            "$remote_file" \
            >> "$sftp_batch"

    done


    # --------------------------------------------------------
    # Upload thumbnails
    # --------------------------------------------------------

    for image in "${images[@]}"; do

        local basename
        basename="$(basename "$image")"

        local filename
        filename="${basename%.*}"

        local local_file
        local_file="$DIRECTORY/thumb/$filename.jpg"

        local remote_file
        remote_file="$remote_directory/thumb/$filename.jpg"


        if [[ ! -f "$local_file" ]]; then

            error "Thumbnail does not exist: $local_file"

        fi


        verbose "Upload → $remote_file"

        printf 'put "%s" "%s"\n' \
            "$local_file" \
            "$remote_file" \
            >> "$sftp_batch"

    done


    # --------------------------------------------------------
    # Execute SFTP
    # --------------------------------------------------------

    if [[ "$VERBOSE" == true ]]; then

        sftp \
            -b "$sftp_batch" \
            "$sftp_host"

    else

        sftp \
            -q \
            -b "$sftp_batch" \
            "$sftp_host"

    fi


    rm -f "$sftp_batch"
    trap - EXIT


    echo ""
    log "Upload complete."
}


# ------------------------------------------------------------
# Parse arguments
# ------------------------------------------------------------

while [[ $# -gt 0 ]]; do

    case "$1" in

        --make)

            MAKE=true
            shift
            ;;


        --post)

            POST=true
            shift
            ;;


        --size)

            [[ $# -ge 2 ]] || \
                error "--size requires a value"

            THUMB_SIZE="$2"
            shift 2
            ;;


        --quality)

            [[ $# -ge 2 ]] || \
                error "--quality requires a value"

            QUALITY="$2"
            shift 2
            ;;


        --force)

            FORCE=true
            shift
            ;;


        --dryrun)

            DRY_RUN=true
            shift
            ;;


        --verbose)

            VERBOSE=true
            shift
            ;;


        -h|--help)

            usage
            exit 0
            ;;


        -*)

            error "Unknown option: $1"
            ;;


        *)

            if [[ "$TARGET" != "." ]]; then
                error "Only one file or directory can be specified."
            fi

            TARGET="$1"
            shift
            ;;

    esac

done


# ------------------------------------------------------------
# Default behavior:
# no explicit mode = MAKE + POST
# ------------------------------------------------------------

if [[ "$MAKE" == false && "$POST" == false ]]; then

    MAKE=true
    POST=true

fi


# ------------------------------------------------------------
# Validate options
# ------------------------------------------------------------

is_valid_size "$THUMB_SIZE" || \
    error "Invalid thumbnail size: $THUMB_SIZE"


is_valid_quality "$QUALITY" || \
    error "Invalid JPEG quality: $QUALITY"


# ------------------------------------------------------------
# Resolve target
# ------------------------------------------------------------

if [[ -d "$TARGET" ]]; then

    DIRECTORY="$(cd "$TARGET" && pwd)"
    TARGET_TYPE="directory"

elif [[ -f "$TARGET" ]]; then

    case "$TARGET" in

        *.jpg|*.JPG|*.jpeg|*.JPEG)
            ;;

        *)
            error "File is not a JPEG: $TARGET"
            ;;

    esac

    DIRECTORY="$(cd "$(dirname "$TARGET")" && pwd)"
    TARGET_TYPE="file"
    TARGET_FILE="$(basename "$TARGET")"

else

    error "File or directory does not exist: $TARGET"

fi


# ------------------------------------------------------------
# SFTP configuration
# ------------------------------------------------------------

if [[ "$POST" == true ]]; then

    SFTP_HOST="${POSTPHOTO_SFTP_HOST:-}"
    REMOTE_DIRECTORY="${POSTPHOTO_REMOTE_DIRECTORY:-}"

    [[ -n "$SFTP_HOST" ]] || \
        error "POSTPHOTO_SFTP_HOST is not configured."

    [[ -n "$REMOTE_DIRECTORY" ]] || \
        error "POSTPHOTO_REMOTE_DIRECTORY is not configured."

fi


# ------------------------------------------------------------
# Check dependencies
# ------------------------------------------------------------

check_dependencies


# ------------------------------------------------------------
# Build image list
# ------------------------------------------------------------

shopt -s nullglob
shopt -s nocaseglob


if [[ "$TARGET_TYPE" == "directory" ]]; then

    images=(
        "$DIRECTORY"/*.jpg
        "$DIRECTORY"/*.jpeg
    )

else

    images=(
        "$DIRECTORY/$TARGET_FILE"
    )

fi


# ------------------------------------------------------------
# Make sure we found something
# ------------------------------------------------------------

if (( ${#images[@]} == 0 )); then

    log "No JPEG images found."

    exit 0

fi


# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

echo ""
echo "(photos)"
echo "––––––––"
echo "Directory:    $DIRECTORY"
echo "Images:       ${#images[@]}"
echo "Thumb size:   ${THUMB_SIZE}px"
echo "JPEG quality: $QUALITY"

if [[ "$MAKE" == true ]]; then
    echo "Action:       MAKE"
fi

if [[ "$POST" == true ]]; then
    echo "Action:       POST"
    echo "Destination:  $SFTP_HOST:$REMOTE_DIRECTORY"
fi

echo "Metadata:     EXIF:DateTimeOriginal only"

if [[ "$DRY_RUN" == true ]]; then
    echo "Mode:         DRY RUN"
fi

if [[ "$FORCE" == true ]]; then
    echo "Mode:         FORCE"
fi


# ------------------------------------------------------------
# MAKE
# ------------------------------------------------------------

if [[ "$MAKE" == true ]]; then

    for image in "${images[@]}"; do

        process_image "$image"

    done

fi


# ------------------------------------------------------------
# POST
# ------------------------------------------------------------

if [[ "$POST" == true ]]; then

    if [[ "$DRY_RUN" == true ]]; then

        echo ""
        echo "Dry run: upload skipped."

    else

        upload_files

    fi

fi


# ------------------------------------------------------------
# Done
# ------------------------------------------------------------

echo ""

if [[ "$DRY_RUN" == true ]]; then

    echo "Dry run complete."

else

    echo "Done."

fi
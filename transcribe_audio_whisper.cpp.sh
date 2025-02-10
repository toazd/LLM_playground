#!/usr/bin/env bash
#
# Transcribe wav audio files using whisper.cpp compiled with vulkan support from
# https://github.com/ggerganov/whisper.cpp
# Vulkan support means that iGPUs are supported which is significantly faster than
# running the full precision models on CPU only
#
# To build whisper.cpp with vulkan support:
#   git clone https://github.com/ggerganov/whisper.cpp.git
#   cd whisper.cpp
#   sh ./models/download-ggml-model.sh ggml-large-v3-turbo
#   cmake -B build -DGGML_VULKAN=1
#   cmake --build build -j --config Release
#     whisper-cli will be in the build/bin directory
#
# IMPORTANT: the cli options for whisper.cpp differ from the stock openai-whisper
#
#
# Basic outline of operations:
#   The folder structure of the input path is recreated in the output path and the
#   input audio file is put into it's own folder (named after itself) and then converted
#   using ffmpeg to a format that whisper.cpp accepts. A copy of the original audio file is
#   also copied to the new folder. Then, whisper-cli is used to transcribe
#   the file into all the supported output formats that whisper.cpp supports
#   (txt, vtt, srt, lrc, csv, json-full)
#
# Fun fact:
#   The skeleton for this script was initially created by Deepseek-r1-14b running locally using
#   lm-studio (vulkan) on an AMD Ryzen 7 7730U iGPU with 2GB VRAM allocated and 16GB system RAM
#   on Arch linux with the following prompt:
#
#     Write a bash script that processes audio files using the whisper command line utility.
#     Add variables at the top of the script to configure the input path, the whisper model
#     to use, and the output path. The input path must be processed recursively. Before calling
#     whisper recreate the folder structure of the input path in the output path. Before an audio
#     file is processed with whisper, create a new folder in the corresponding output path with
#     the same name as the audio file and copy the audio file to the new folder.
#
#   Deepseek did pretty good the first time around but there were bugs that needed to be worked out,
#   namely, it chose to use find to recurse the input path but it didn't use the correct flags with
#   find in order for it to work properly when spaces occur in the file name. One shouldn't use find
#   for recursing files in any path to begin with and that was replaced with the much more reliable
#   bash globstar. After I discovered that whisper.cpp was a thing (supports vulkan) I then updated
#   the script to use that instead of whisper.

shopt -s globstar # needed for bash's built in directory recursion
shopt -s dotglob  # probably not needed but it doesn't hurt

# Configure paths and settings
INPUT_PATH="/home/wmcdannell/Documents/Bible Study/Sermons"
WHISPER_MODEL="ggml-large-v3-turbo.bin"
OUTPUT_PATH="/home/wmcdannell/Audio transcribing/output/ggml-large-v3-turbo"

# Ensure output directory exists
mkdir -p "$OUTPUT_PATH"

# Find all audio files in input path (recursively)
for file in "$INPUT_PATH"/**/*.*; do

    # if $file is a directory, skip it
    [[ -d "$file" ]] && continue

    # Extract relative path from input to file
    # deepseek wanted to use the commented out command
    # which is overkill computationally for a task that
    # bash has built in support for
    #RELATIVE_PATH="$(echo "$file" | sed "s|$INPUT_PATH||")"
    RELATIVE_PATH="${file/$INPUT_PATH//}"

    # Create output directory structure
    OUTPUT_DIR="$OUTPUT_PATH$(dirname "$RELATIVE_PATH")"
    mkdir -p "$OUTPUT_DIR"

    # Extract filename without extension
    FILENAME=$(basename "$file")
    EXTENSION="${FILENAME##*.}"
    BASENAME="${FILENAME%.*}"

    # Create new folder in output path with the same name as the audio file
    NEW_FOLDER="$OUTPUT_DIR/$BASENAME"
    mkdir -p "$NEW_FOLDER"

    # Get the filename without the path
    new_file=$(basename "$file")

    # put a copy of the original in the new folder if it doesn't exist
    # if you don't want this simply comment out the next line
    [[ ! -e "$NEW_FOLDER/$new_file" ]] && cp -v "$file" "$NEW_FOLDER"

    # construct the new file name without the extension using bash parameter expansion
    new_file_wo_ext="$NEW_FOLDER/${new_file%.*}"

    # if the new file was already transcribed skip this one
    [[ -e "${new_file_wo_ext}.wav" && -e "${new_file_wo_ext}.wav.txt" ]] && {
        echo "Skipping $NEW_FOLDER/${new_file%.*}.wav"
        continue
    }

    # convert the input audio file to the wav format that whisper.cpp expects
    ffmpeg -hide_banner -loglevel error -y -i "$file" -ar 16000 -ac 1 -c:a pcm_s16le "${new_file_wo_ext}.wav"

    # update new_file to point to the new wav file
    new_file="${new_file_wo_ext}.wav"

    # Process the audio file with whisper.cpp
    echo "Processing: $new_file"
    ./whisper-cli \
        --model "$WHISPER_MODEL" \
        --language en \
        --temperature 0 \
        --print-progress \
        --output-txt \
        --output-vtt \
        --output-srt \
        --output-lrc \
        --output-csv \
        --output-json-full \
        --file "$new_file"

    # The exit status of whisper-cli is checked
    exit_status=$?

    # 0 is typically success
    [[ $exit_status -gt 0 ]] && {
        echo "Abnormal whisper-cli exit status: $exit_status"
        exit $exit_status
    }
done

echo "Processing complete."

# quick install and compile instructions:
#
# mkdir token_count && cd token_count && wget https://raw.githubusercontent.com/toazd/LLM_playground/refs/heads/main/token_count.py && python -m venv venv && source venv/bin/activate
# pip install tiktoken PyPDF2 chardet pyinstaller
# pyinstaller --hidden-import=tiktoken_ext.openai_public --hidden-import=tiktoken_ext --onefile token_count.py
# compiled token_count will be in dist/
#

import tiktoken
from PyPDF2 import PdfReader
import chardet


def count_tokens(text, encoding_name="cl100k_base"):
    encoding = tiktoken.get_encoding(encoding_name)
    return len(encoding.encode(text))


def extract_text_from_pdf(file_path):
    try:
        reader = PdfReader(file_path)
        text = ""
        for page in reader.pages:
            text += page.extract_text()
        return text
    except Exception as e:
        print(f"Error reading PDF file: {e}")
        sys.exit(1)


def extract_text_from_txt(file_path):
    try:
        # Read the file in binary mode to detect encoding
        with open(file_path, 'rb') as file:
            raw_data = file.read()

        # Detect the encoding
        result = chardet.detect(raw_data)
        encoding = result['encoding']

        # Decode the file content using the detected encoding
        text = raw_data.decode(encoding)
        return text
    except Exception as e:
        print(f"Error reading text file: {e}")
        sys.exit(1)


def summarize_document(file_path):
    if file_path.endswith('.pdf'):
        text = extract_text_from_pdf(file_path)
    elif file_path.endswith('.txt'):
        text = extract_text_from_txt(file_path)
    else:
        print("Error: Unsupported file format. Only .txt and .pdf files are supported.")
        sys.exit(1)

    lines = text.splitlines()
    words = text.split()
    characters = len(text)
    tokens = count_tokens(text)

    summary = {
        "file_path": file_path,
        "lines": len(lines),
        "words": len(words),
        "characters": characters,
        "tokens": tokens
    }

    return summary


def format_number_with_separator(number):
    return f"{number:,}"


def main():
    if len(sys.argv) != 2:
        print("Usage: python summarize_document.py <file_path>")
        sys.exit(1)

    file_path = sys.argv[1]
    summary = summarize_document(file_path)

    #print(f"Summary for '{summary['file_path']}':")
    #print(f"  Number of lines: {format_number_with_separator(summary['lines'])}")
    #print(f"  Number of words: {format_number_with_separator(summary['words'])}")
    #print(f"  Number of characters: {format_number_with_separator(summary['characters'])}")
    #print(f"  Number of tokens: {format_number_with_separator(summary['tokens'])}")

    # only output the number of tokens, useful for usage in other scripts
    print(f"{summary['tokens']}")


if __name__ == "__main__":
    main()

# Configure the addresses for each client you want to use
# NOTE: jq is required but is not typically installed by default
LMSTUDIO_ADDRESS="http://localhost:1234/v1/chat/completions"
OLLAMA_CHAT_ADDRESS="http://localhost:11434/api/chat"
OLLAMA_GENERATE_ADDRESS="http://localhost:11434/api/generate"
# https://github.com/ollama/ollama/blob/main/docs/api.md

# Use lm-studio to print the poem
print_lmstudio_poem() {
  curl -s "$LMSTUDIO_ADDRESS" -H "Content-Type: application/json" -d '{
    "model": "llama3.2-3b",
      "messages": [
        {
          "role": "system",
          "content": "You are a master poet and every line must rhyme"
        },
        {
          "role": "user",
          "content": "Create a random 4 line poem. Include different emojis related to the line at the beginning and the end of each line. Do not output anything else."
        }
      ],
      "temperature": 1.0,
      "stream": false
  }' | jq -r '.choices[].message.content'
}

# Use ollama chat API to print a poem
print_ollama_chat_poem() {
  curl -s "$OLLAMA_CHAT_ADDRESS" -H "Content-Type: application/json" -d '{
    "model": "llama3.2:3b",
      "messages": [
        {
          "role": "system",
          "content": "You are a master poet and every line must rhyme"
        },
        {
          "role": "user",
          "content": "Create a random 4 line poem. Include different emojis related to the line at the beginning and the end of each line. Do not output anything else."
        }
      ],
      "temperature": 1.0,
      "stream": false,
      "use_mmap": true,
      "use_mlock": false,
      "keep_alive": 0.01
  }' | jq -r '.message.content'
}

# Use ollama generate API to print a poem
print_ollama_generate_poem() {
  curl -s "$OLLAMA_GENERATE_ADDRESS" -H "Content-Type: application/json" -d '{
        "model": "llama3.2:3b",
        "prompt": "Create a random 4 line poem. Include different emojis related to the line at the beginning and the end of each line. Do not output anything else.",
        "stream": false,
        "keep_alive": 0.01,
        "options":
        {
          "temperature": 1.0,
          "use_mmap": true,
          "use_mlock": false
        }
  }' | jq -r '.response'
}

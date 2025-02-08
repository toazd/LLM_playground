#!/bin/env bash

# Backend/LLM provider Configuration
OLLAMA_URL="http://localhost:11434/api/generate"
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"
KOBOLDCPP_URL="http://localhost:5001/api/v1/generate"
JAN_URL="http://localhost:1337/v1/chat/completions"
ANYTHINGLLM_URL="http://localhost:3001/api/v1/chat"

# Choose which model to load
# NOTE: does not apply to KoboldCPP or AnythingLLM
MODEL="llama3.2:3b"

# Function to chat with Ollama
chat_ollama() {
    local PROMPT="$1"
    curl -s -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d "{
        \"model\": \"$MODEL\",
        \"prompt\": \"$PROMPT\",
        \"stream\": false
    }" | jq -r '.response'
}

# Function to chat with LM Studio
chat_lm_studio() {
    local PROMPT="$1"
    curl -s -X POST "$LM_STUDIO_URL" -H "Content-Type: application/json" -d "{
        \"model\": \"$MODEL\",
        \"messages\": [{
            \"role\": \"user\",
            \"content\": \"$PROMPT\"
        }],
        \"temperature\": 0.7
    }" | jq -r '.choices[0].message.content'
}

# Function to chat with KoboldCPP
chat_koboldcpp() {
    local PROMPT="$1"
    curl -s -X POST "$KOBOLDCPP_URL" -H "Content-Type: application/json" -d "{
            \"prompt\": \"$PROMPT\",
            \"temperature\": 0.7
    }" | jq -r '.results[0].text'
}

# Function to chat with Jan
chat_jan() {
    local PROMPT="$1"
    curl -s -X POST "$JAN_URL" -H "Content-Type: application/json" -d "{
        \"model\": \"$MODEL\",
        \"messages\": [{
            \"role\": \"user\",
            \"content\": \"$PROMPT\"
        }],
        \"temperature\": 0.7
    }" | jq -r '.choices[0].message.content'
}

# Function to chat with AnythingLLM
chat_anythingllm() {
    local PROMPT="$1"
    curl -s -X POST "$ANYTHINGLLM_URL" -H "Content-Type: application/json" -d "{
        \"prompt\": \"$PROMPT\",
        \"temperature\": 0.7
    }" | jq -r '.response'
}

# Main function
main() {
    echo "Choose an option:"
    echo "1. Chat with Ollama"
    echo "2. Chat with LM Studio"
    echo "3. Chat with KoboldCPP"
    echo "4. Chat with Jan"
    echo "5. Chat with AnythingLLM"
    read -rp "Enter your choice (1-5): " CHOICE

    if [[ "$CHOICE" == "exit" ]]; then
        echo "Exiting menu"
        exit 0
    fi

    if [[ "$CHOICE" -lt 1 || "$CHOICE" -gt 5 ]]; then
        echo "Invalid choice. Exiting."
        exit 1
    fi

    while true; do
        read -rp "You: " PROMPT
        if [[ "$PROMPT" == "exit" ]]; then
            echo "Exiting chat."
            break
        fi

        case "$CHOICE" in
            1) RESPONSE=$(chat_ollama "$PROMPT") ;;
            2) RESPONSE=$(chat_lm_studio "$PROMPT") ;;
            3) RESPONSE=$(chat_koboldcpp "$PROMPT") ;;
            4) RESPONSE=$(chat_jan "$PROMPT") ;;
            5) RESPONSE=$(chat_anythingllm "$PROMPT") ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac

        echo "LLM: $RESPONSE"
    done
}

# Run the main function
main

#!/bin/bash

# Helper script to send commands to the Hytale server console
# Usage: send-command.sh <command>
# Example: send-command.sh "/auth status"

if [ $# -eq 0 ]; then
    echo "Usage: $(basename "$0") <command>"
    echo "Example: $(basename "$0") \"/auth status\""
    exit 1
fi

# Find the hytale input pipe
INPUT_PIPE=$(find /tmp -name "hytale_input_*" -type p 2>/dev/null | head -1)

if [ -z "$INPUT_PIPE" ]; then
    echo "Error: Hytale server input pipe not found. Is the server running?"
    exit 1
fi

# Send the command
echo "$*" > "$INPUT_PIPE"

echo "Command sent: $*"

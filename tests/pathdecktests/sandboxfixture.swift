import Foundation

/// Mock configuration fixture representing a messy, real-world ~/.zshrc profile for testing.
public struct SandboxFixture {
    public static let messyZshrc = """
# PathDeck Mock Messy Zshrc Configuration File

# Prepend homebrew path
export PATH="/opt/homebrew/bin:$PATH" # Load brew dependencies first

# Append user cargo binaries
export PATH="$PATH:/Users/even/.cargo/bin"

# Active developer studio aliases
alias gs="git status" # Quick status check shortcut
alias ll="ls -la" # Detailed directory listing

# Inactive / commented out aliases
# alias gp="git push"

# System and service environment variables
export DOCKER_HOST="tcp://localhost:2375" # Local Docker daemon connection
export OPENAI_API_KEY="sk-proj-test12345secretkey" # Secret AI api keys
export GITHUB_TOKEN="ghp_dummytokenfortests"

# Multiline Homebrew shellenv conditional initialization block
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Custom helper shell functions
pathdeck_clean() {
    echo "Purging shell cache..."
    hash -r
}
"""

    public static let consolidatedZshrc = """
# PathDeck Mock Messy Zshrc Configuration File

# Prepend homebrew path
# >>> PathDeck PATH Section >>>
export PATH="/opt/homebrew/bin:$PATH" # Load brew dependencies first
export PATH="$PATH:/Users/even/.cargo/bin"
# <<< PathDeck PATH Section <<<

# Append user cargo binaries

# Active developer studio aliases
alias gs="git status" # Quick status check shortcut
alias ll="ls -la" # Detailed directory listing

# Inactive / commented out aliases
# alias gp="git push"

# System and service environment variables
export DOCKER_HOST="tcp://localhost:2375" # Local Docker daemon connection
export OPENAI_API_KEY="sk-proj-test12345secretkey" # Secret AI api keys
export GITHUB_TOKEN="ghp_dummytokenfortests"

# Multiline Homebrew shellenv conditional initialization block
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Custom helper shell functions
pathdeck_clean() {
    echo "Purging shell cache..."
    hash -r
}
"""
}

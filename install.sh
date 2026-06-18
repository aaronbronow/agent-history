#!/usr/bin/env bash
# Installer script for agent-history plugin
# Usage: curl -sSL https://raw.githubusercontent.com/aaronbronow/agent-history/main/install.sh | bash

set -euo pipefail

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BLUE}⚡ Installing agent-history plugin...${NC}"

# Define custom plugin directory
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
PLUGIN_DIR="$ZSH_CUSTOM/plugins/agent-history"
REPO_URL="https://github.com/aaronbronow/agent-history.git"

if [ -d "$PLUGIN_DIR" ]; then
    echo -e "${YELLOW}Plugin directory already exists. Updating plugin via git pull...${NC}"
    git -C "$PLUGIN_DIR" pull
else
    echo -e "${CYAN}Cloning agent-history repository...${NC}"
    git clone "$REPO_URL" "$PLUGIN_DIR"
fi

# Check ~/.zshrc for plugin activation
ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ]; then
    if grep -q "agent-history" "$ZSHRC"; then
        echo -e "${GREEN}✓ agent-history is already enabled in your .zshrc!${NC}"
    else
        echo -e "${YELLOW}! agent-history is not enabled in your .zshrc plugins list.${NC}"
        echo -e "To enable it, open ${BLUE}~/.zshrc${NC} and add ${CYAN}agent-history${NC} to your plugins list, e.g.:"
        echo -e "  plugins=(\n    ...\n    ${CYAN}agent-history${NC}\n  )"
    fi
else
    echo -e "${RED}Warning: ~/.zshrc file not found. Make sure to load the plugin in your shell configuration.${NC}"
fi

echo -e "\n${GREEN}✓ Installation complete! Run ${BOLD}${PURPLE}source ~/.zshrc${NC}${GREEN} to reload your shell.${NC}\n"

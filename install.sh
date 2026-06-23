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

REPO_URL="https://github.com/aaronbronow/agent-history.git"

# Detect shell and framework
SHELL_NAME=$(basename "${SHELL:-bash}")
OMZ_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ "$SHELL_NAME" == "zsh" ]] || [ -f "$HOME/.zshrc" ]; then
    RC_FILE="$HOME/.zshrc"
else
    RC_FILE="$HOME/.bashrc"
fi

if [[ "$SHELL_NAME" == "zsh" ]] && [ -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${CYAN}Oh My Zsh environment detected.${NC}"
    PLUGIN_DIR="$OMZ_DIR/plugins/agent-history"
    IS_OMZ=true
else
    echo -e "${CYAN}Generic shell environment detected (Shell: $SHELL_NAME).${NC}"
    PLUGIN_DIR="$HOME/.agent-history"
    IS_OMZ=false
fi

# Clone or update the repository
if [ -d "$PLUGIN_DIR" ]; then
    echo -e "${YELLOW}Plugin directory already exists. Updating plugin via git pull...${NC}"
    git -C "$PLUGIN_DIR" pull
else
    echo -e "${CYAN}Cloning agent-history repository to $PLUGIN_DIR...${NC}"
    git clone "$REPO_URL" "$PLUGIN_DIR"
fi

if [ "$IS_OMZ" = true ]; then
    # Check plugin activation in RC file
    if [ -f "$RC_FILE" ]; then
        if grep -q "agent-history" "$RC_FILE"; then
            echo -e "${GREEN}✓ agent-history is already enabled in your $RC_FILE!${NC}"
        else
            echo -e "${YELLOW}! agent-history is not enabled in your $RC_FILE plugins list.${NC}"
            echo -e "To enable it, open ${BLUE}$RC_FILE${NC} and add ${CYAN}agent-history${NC} to your plugins list, e.g.:"
            echo -e "  plugins=(\n    ...\n    ${CYAN}agent-history${NC}\n  )"
        fi
    else
        echo -e "${RED}Warning: $RC_FILE file not found. Make sure to load the plugin in your shell configuration.${NC}"
    fi
else
    # Determine configuration loader file to update for non-OMZ installations
    if [[ "$RC_FILE" == *".zshrc" ]]; then
        LOADER_FILE="agent-history.plugin.zsh"
    else
        LOADER_FILE="agent-history.plugin.sh"
    fi

    if [ -f "$RC_FILE" ]; then
        if grep -q "$LOADER_FILE" "$RC_FILE"; then
            echo -e "${GREEN}✓ agent-history loader is already configured in $RC_FILE!${NC}"
        else
            echo -e "${YELLOW}Adding loader to $RC_FILE...${NC}"
            echo -e "\n# agent-history plugin loader" >> "$RC_FILE"
            echo "source \"$PLUGIN_DIR/$LOADER_FILE\"" >> "$RC_FILE"
            echo -e "${GREEN}✓ Added loader to $RC_FILE!${NC}"
        fi
    else
        echo -e "${RED}Warning: Shell configuration file $RC_FILE not found.${NC}"
        echo -e "To complete installation, add the following to your shell startup file:"
        echo -e "  ${CYAN}source \"$PLUGIN_DIR/$LOADER_FILE\"${NC}"
    fi
fi

echo -e "\n${GREEN}✓ Installation complete! Run ${BOLD}${PURPLE}source $RC_FILE${NC}${GREEN} to reload your shell.${NC}\n"

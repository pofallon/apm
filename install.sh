#!/bin/bash
set -e

# APM CLI Installer Script
# Usage: curl -sSL https://raw.githubusercontent.com/danielmeppiel/apm-cli/mai# Extract API asset URL for private repository downloads
ASSET_URL=$(echo "$LATEST_RELEASE" | grep -B 2 '"name": "'$DOWNLOAD_BINARY'"' | grep '"url":' | sed -E 's/.*"url": "([^"]+)".*/\1/')install.sh | sh
# For private repositories, use with authentication:
#   curl -sSL -H "Authorization: token $GITHUB_APM_PAT" \
#     https://raw.githubusercontent.com/danielmeppiel/apm-cli/main/install.sh | \
#     GITHUB_APM_PAT=$GITHUB_APM_PAT sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO="danielmeppiel/apm-cli"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="apm"

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    APM CLI Installer                        ║"
echo "║              The NPM for AI-Native Development              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Platform detection
OS=$(uname -s)
ARCH=$(uname -m)

# Normalize architecture names
case $ARCH in
    x86_64)
        ARCH="x86_64"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ;;
    *)
        echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
        echo "Supported architectures: x86_64, arm64"
        exit 1
        ;;
esac

# Normalize OS names and set binary name
case $OS in
    Darwin)
        PLATFORM="darwin"
        DOWNLOAD_BINARY="apm-darwin-$ARCH.tar.gz"
        EXTRACTED_DIR="apm-darwin-$ARCH"
        ;;
    Linux)
        PLATFORM="linux"
        DOWNLOAD_BINARY="apm-linux-$ARCH.tar.gz"
        EXTRACTED_DIR="apm-linux-$ARCH"
        ;;
    *)
        echo -e "${RED}Error: Unsupported operating system: $OS${NC}"
        echo "Supported platforms: macOS (Darwin), Linux"
        exit 1
        ;;
esac

echo -e "${BLUE}Detected platform: $PLATFORM-$ARCH${NC}"
echo -e "${BLUE}Target binary: $DOWNLOAD_BINARY${NC}"

# Check if we have permission to install to /usr/local/bin
if [ ! -w "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Note: Will need sudo permissions to install to $INSTALL_DIR${NC}"
fi

# Get latest release info
echo -e "${YELLOW}Fetching latest release information...${NC}"

# Try to fetch release info without authentication first (for public repos)
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")

# Check if the response indicates authentication is required (private repo)
if [ $? -ne 0 ] || [ -z "$LATEST_RELEASE" ] || echo "$LATEST_RELEASE" | grep -q '"message".*"Not Found"'; then
    echo -e "${BLUE}Repository appears to be private, trying with authentication...${NC}"
    
    # Check if we have GitHub token for private repo access
    AUTH_HEADER_VALUE=""
    if [ -n "$GITHUB_APM_PAT" ]; then
        echo -e "${BLUE}Using GITHUB_APM_PAT for private repository access${NC}"
        AUTH_HEADER_VALUE="$GITHUB_APM_PAT"
    elif [ -n "$GITHUB_TOKEN" ]; then
        echo -e "${BLUE}Using GITHUB_TOKEN for private repository access${NC}"
        AUTH_HEADER_VALUE="$GITHUB_TOKEN"
    else
        echo -e "${RED}Error: Repository is private but no authentication token found${NC}"
        echo "Please set GITHUB_APM_PAT or GITHUB_TOKEN environment variable:"
        echo "  export GITHUB_APM_PAT=your_token_here"
        echo "  curl -sSL -H \"Authorization: token \$GITHUB_APM_PAT\" \\"
        echo "    https://raw.githubusercontent.com/danielmeppiel/apm-cli/main/install.sh | \\"
        echo "    GITHUB_APM_PAT=\$GITHUB_APM_PAT sh"
        exit 1
    fi
    
    # Retry with authentication
    LATEST_RELEASE=$(curl -s -H "Authorization: token $AUTH_HEADER_VALUE" "https://api.github.com/repos/$REPO/releases/latest")
fi

if [ $? -ne 0 ] || [ -z "$LATEST_RELEASE" ]; then
    echo -e "${RED}Error: Failed to fetch release information${NC}"
    echo "Please check your internet connection and try again."
    exit 1
fi

# Extract tag name and download URLs
TAG_NAME=$(echo "$LATEST_RELEASE" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG_NAME/$DOWNLOAD_BINARY"

# Extract API asset URL for private repository downloads
ASSET_URL=$(echo "$LATEST_RELEASE" | grep -B 3 "\"name\": \"$DOWNLOAD_BINARY\"" | grep '"url":' | sed -E 's/.*"url": "([^"]+)".*/\1/')

if [ -z "$TAG_NAME" ]; then
    echo -e "${RED}Error: Could not determine latest release version${NC}"
    exit 1
fi

echo -e "${GREEN}Latest version: $TAG_NAME${NC}"
echo -e "${BLUE}Download URL: $DOWNLOAD_URL${NC}"

# Create temporary directory
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# Download binary
echo -e "${YELLOW}Downloading APM CLI...${NC}"

# Try downloading without authentication first (for public repos)
if curl -L --fail --silent --show-error "$DOWNLOAD_URL" -o "$TMP_DIR/$DOWNLOAD_BINARY"; then
    echo -e "${GREEN}✓ Download successful${NC}"
else
    # If unauthenticated download fails, try with authentication if available
    if [ -n "$AUTH_HEADER_VALUE" ]; then
        echo -e "${BLUE}Download failed, retrying with authentication...${NC}"
        
        # For private repositories, use GitHub API with proper headers
        if [ -n "$ASSET_URL" ]; then
            echo -e "${BLUE}Using GitHub API for private repository access...${NC}"
            if curl -L --fail --silent --show-error \
                -H "Authorization: token $AUTH_HEADER_VALUE" \
                -H "Accept: application/octet-stream" \
                "$ASSET_URL" -o "$TMP_DIR/$DOWNLOAD_BINARY"; then
                echo -e "${GREEN}✓ Download successful via GitHub API${NC}"
            else
                echo -e "${BLUE}GitHub API download failed, trying direct URL with auth...${NC}"
                if curl -L --fail --silent --show-error -H "Authorization: token $AUTH_HEADER_VALUE" "$DOWNLOAD_URL" -o "$TMP_DIR/$DOWNLOAD_BINARY"; then
                    echo -e "${GREEN}✓ Download successful with authentication${NC}"
                else
                    echo -e "${RED}Error: Failed to download APM CLI even with authentication${NC}"
                    echo "Direct URL: $DOWNLOAD_URL"
                    echo "API URL: $ASSET_URL"
                    echo "This might mean:"
                    echo "  1. No binary available for your platform ($PLATFORM-$ARCH)"
                    echo "  2. Network connectivity issues"
                    echo "  3. The release doesn't include binaries yet"
                    echo "  4. Invalid GitHub token or insufficient permissions"
                    echo ""
                    echo "For private repositories, ensure your token has the required permissions."
                    echo "You can try installing from source instead:"
                    echo "  git clone https://github.com/$REPO.git"
                    echo "  cd apm-cli && uv sync && uv run pip install -e ."
                    exit 1
                fi
            fi
        else
            echo -e "${BLUE}No API URL available, trying direct URL with auth...${NC}"
            if curl -L --fail --silent --show-error -H "Authorization: token $AUTH_HEADER_VALUE" "$DOWNLOAD_URL" -o "$TMP_DIR/$DOWNLOAD_BINARY"; then
                echo -e "${GREEN}✓ Download successful with authentication${NC}"
            else
                echo -e "${RED}Error: Failed to download APM CLI even with authentication${NC}"
                echo "URL: $DOWNLOAD_URL"
                echo "This might mean:"
                echo "  1. No binary available for your platform ($PLATFORM-$ARCH)"
                echo "  2. Network connectivity issues"
                echo "  3. The release doesn't include binaries yet"
                echo "  4. Invalid GitHub token or insufficient permissions"
                echo ""
                echo "For private repositories, ensure your token has the required permissions."
                echo "You can try installing from source instead:"
                echo "  git clone https://github.com/$REPO.git"
                echo "  cd apm-cli && uv sync && uv run pip install -e ."
                exit 1
            fi
        fi
    else
        echo -e "${RED}Error: Failed to download APM CLI${NC}"
        echo "URL: $DOWNLOAD_URL"
        echo "This might mean:"
        echo "  1. No binary available for your platform ($PLATFORM-$ARCH)"
        echo "  2. Network connectivity issues"
        echo "  3. The release doesn't include binaries yet"
        echo "  4. Private repository requires authentication"
        echo ""
        echo "For private repositories, set GITHUB_APM_PAT environment variable:"
        echo "  export GITHUB_APM_PAT=your_token_here"
        echo "  curl -sSL -H \"Authorization: token \$GITHUB_APM_PAT\" \\"
        echo "    https://raw.githubusercontent.com/danielmeppiel/apm-cli/main/install.sh | \\"
        echo "    GITHUB_APM_PAT=\$GITHUB_APM_PAT sh"
        echo ""
        echo "You can also try installing from source:"
        echo "  git clone https://github.com/$REPO.git"
        echo "  cd apm-cli && uv sync && uv run pip install -e ."
        exit 1
    fi
fi

# Extract binary from tar.gz
echo -e "${YELLOW}Extracting binary...${NC}"
if tar -xzf "$TMP_DIR/$DOWNLOAD_BINARY" -C "$TMP_DIR"; then
    echo -e "${GREEN}✓ Extraction successful${NC}"
else
    echo -e "${RED}Error: Failed to extract binary from archive${NC}"
    exit 1
fi

# Make binary executable
chmod +x "$TMP_DIR/$EXTRACTED_DIR/$BINARY_NAME"

# Test the binary
echo -e "${YELLOW}Testing binary...${NC}"
if "$TMP_DIR/$EXTRACTED_DIR/$BINARY_NAME" --version >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Binary test successful${NC}"
else
    echo -e "${RED}Error: Downloaded binary failed to run${NC}"
    exit 1
fi

# Install binary directory structure
echo -e "${YELLOW}Installing APM CLI to $INSTALL_DIR...${NC}"

# APM installation directory (for the complete bundle)
APM_INSTALL_DIR="/usr/local/lib/apm"

# Remove any existing installation
if [ -d "$APM_INSTALL_DIR" ]; then
    if [ -w "/usr/local/lib" ]; then
        rm -rf "$APM_INSTALL_DIR"
    else
        sudo rm -rf "$APM_INSTALL_DIR"
    fi
fi

# Create installation directory
if [ -w "/usr/local/lib" ]; then
    mkdir -p "$APM_INSTALL_DIR"
    cp -r "$TMP_DIR/$EXTRACTED_DIR"/* "$APM_INSTALL_DIR/"
else
    sudo mkdir -p "$APM_INSTALL_DIR"
    sudo cp -r "$TMP_DIR/$EXTRACTED_DIR"/* "$APM_INSTALL_DIR/"
fi

# Create symlink in /usr/local/bin pointing to the actual binary
if [ -w "$INSTALL_DIR" ]; then
    ln -sf "$APM_INSTALL_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
else
    sudo ln -sf "$APM_INSTALL_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
fi

# Verify installation
if command -v apm >/dev/null 2>&1; then
    INSTALLED_VERSION=$(apm --version 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓ APM CLI installed successfully!${NC}"
    echo -e "${BLUE}Version: $INSTALLED_VERSION${NC}"
    echo -e "${BLUE}Location: $INSTALL_DIR/$BINARY_NAME -> $APM_INSTALL_DIR/$BINARY_NAME${NC}"
else
    echo -e "${YELLOW}⚠ APM CLI installed but not found in PATH${NC}"
    echo "You may need to add $INSTALL_DIR to your PATH environment variable."
    echo "Add this line to your shell profile (.bashrc, .zshrc, etc.):"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
fi

echo ""
echo -e "${GREEN}🎉 Installation complete!${NC}"
echo ""
echo -e "${BLUE}Quick start:${NC}"
echo "  apm init my-app          # Create a new APM project"
echo "  cd my-app && apm install # Install dependencies"
echo "  apm run                  # Run your first prompt"
echo ""
echo -e "${BLUE}Documentation:${NC} https://github.com/$REPO"
echo -e "${BLUE}Need help?${NC} Create an issue at https://github.com/$REPO/issues"

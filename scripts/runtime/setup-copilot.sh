#!/bin/bash
# Setup script for GitHub Copilot CLI runtime
# Handles npm authentication and @github/copilot installation with MCP configuration
# Private preview version (Staffship)

set -euo pipefail

# Get the directory of this script for sourcing common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/setup-common.sh"

# Configuration
COPILOT_PACKAGE="@github/copilot"
VANILLA_MODE=false
NODE_MIN_VERSION="22"
NPM_MIN_VERSION="10"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --vanilla)
            VANILLA_MODE=true
            shift
            ;;
        *)
            # Version specification not supported for Copilot CLI (uses latest from npm)
            shift
            ;;
    esac
done

# Check Node.js version
check_node_version() {
    log_info "Checking Node.js version..."
    
    if ! command -v node >/dev/null 2>&1; then
        log_error "Node.js is not installed"
        log_info "Please install Node.js version $NODE_MIN_VERSION or higher from https://nodejs.org/"
        exit 1
    fi
    
    local node_version=$(node --version | sed 's/v//')
    local node_major=$(echo "$node_version" | cut -d. -f1)
    
    if [[ "$node_major" -lt "$NODE_MIN_VERSION" ]]; then
        log_error "Node.js version $node_version is too old. Required: v$NODE_MIN_VERSION or higher"
        log_info "Please update Node.js from https://nodejs.org/"
        exit 1
    fi
    
    log_success "Node.js version $node_version ✓"
}

# Check npm version
check_npm_version() {
    log_info "Checking npm version..."
    
    if ! command -v npm >/dev/null 2>&1; then
        log_error "npm is not installed"
        log_info "Please install npm version $NPM_MIN_VERSION or higher"
        exit 1
    fi
    
    local npm_version=$(npm --version)
    local npm_major=$(echo "$npm_version" | cut -d. -f1)
    
    if [[ "$npm_major" -lt "$NPM_MIN_VERSION" ]]; then
        log_error "npm version $npm_version is too old. Required: v$NPM_MIN_VERSION or higher"
        log_info "Please update npm with: npm install -g npm@latest"
        exit 1
    fi
    
    log_success "npm version $npm_version ✓"
}

# Check GitHub npm authentication
check_github_npm_auth() {
    log_info "Checking GitHub npm registry authentication..."
    
    # Check if already logged in to @github scope
    if npm whoami --scope=@github --registry=https://npm.pkg.github.com >/dev/null 2>&1; then
        local username=$(npm whoami --scope=@github --registry=https://npm.pkg.github.com)
        log_success "Already authenticated to GitHub npm registry as: $username"
        return 0
    else
        log_info "Attempting authentication to GitHub npm registry"
        
        # Check if we have GITHUB_NPM_PAT for automatic authentication
        if [[ -n "$GITHUB_NPM_PAT" ]]; then
            log_info "Found GITHUB_NPM_PAT, attempting automatic npm authentication..."
            if setup_npm_auth_with_token; then
                return 0
            fi
        fi
        
        return 1
    fi
}

# Set up npm authentication using GITHUB_NPM_PAT token
setup_npm_auth_with_token() {
    if [[ -z "$GITHUB_NPM_PAT" ]]; then
        log_error "GITHUB_NPM_PAT environment variable not set"
        return 1
    fi
    
    log_info "Setting up npm authentication with GITHUB_NPM_PAT..."
    
    # Use npm login in non-interactive mode with the token
    # This mimics: npm login --scope=@github --auth-type=legacy --registry=https://npm.pkg.github.com
    
    # Configure npm registry for @github scope
    npm config set @github:registry https://npm.pkg.github.com/
    
    # Set the auth token directly in the npm configuration
    npm config set //npm.pkg.github.com/:_authToken "${GITHUB_NPM_PAT}"
    
    # Test the authentication
    if npm whoami --scope=@github --registry=https://npm.pkg.github.com >/dev/null 2>&1; then
        local username=$(npm whoami --scope=@github --registry=https://npm.pkg.github.com)
        log_success "Successfully authenticated to GitHub npm registry as: $username using GITHUB_NPM_PAT"
        return 0
    else
        log_error "Failed to authenticate with GITHUB_NPM_PAT"
        return 1
    fi
}

# Guide user through GitHub npm authentication
setup_github_npm_auth() {
    log_info "Setting up GitHub npm registry authentication..."
    echo ""
    log_info "GitHub Copilot CLI is currently in private preview and requires authentication"
    log_info "to the GitHub npm registry. Please follow these steps:"
    echo ""
    
    echo "${HIGHLIGHT}Step 1: Create a GitHub Personal Access Token${RESET}"
    echo "1. Go to: https://github.com/settings/tokens/new"
    echo "2. Select 'Classic token'"
    echo "3. Add 'read:packages' scope"
    echo "4. Enable SSO for the 'github' organization"
    echo "5. Set expiration < 90 days"
    echo "6. Generate token and copy it"
    echo ""
    
    echo "${HIGHLIGHT}Step 2: Authenticate with npm${RESET}"
    echo "Run this command and enter your GitHub username and PAT:"
    echo ""
    echo "  npm login --scope=@github --auth-type=legacy --registry=https://npm.pkg.github.com"
    echo ""
    
    # Ask if they want to try authentication now
    if command -v read >/dev/null 2>&1; then
        read -p "Would you like to authenticate now? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Starting npm authentication..."
            if npm login --scope=@github --auth-type=legacy --registry=https://npm.pkg.github.com; then
                log_success "Successfully authenticated to GitHub npm registry!"
            else
                log_error "Authentication failed. Please try again manually."
                exit 1
            fi
        else
            log_warning "Please authenticate manually and then re-run this script"
            exit 1
        fi
    else
        log_warning "Please authenticate manually and then re-run this script"
        exit 1
    fi
}

# Install Copilot CLI via npm
install_copilot_cli() {
    log_info "Installing GitHub Copilot CLI..."
    
    # Install globally - npm will use the configured registries (GitHub for @github scope, default for others)
    if npm install -g "$COPILOT_PACKAGE"; then
        log_success "Successfully installed $COPILOT_PACKAGE"
    else
        log_error "Failed to install $COPILOT_PACKAGE"
        log_info "This might be due to:"
        log_info "  - Authentication issues with GitHub npm registry"
        log_info "  - Insufficient permissions for global npm install"
        log_info "  - Network connectivity issues"
        exit 1
    fi
}

# Source the centralized GitHub token helper  
source "$SCRIPT_DIR/github-token-helper.sh"

# Setup GitHub MCP Server environment for Copilot CLI
setup_github_mcp_environment() {
    log_info "Setting up GitHub MCP Server environment for Copilot CLI..."
    
    # Use centralized token management
    setup_github_tokens
    
    # For Copilot CLI MCP server, we need GITHUB_PERSONAL_ACCESS_TOKEN
    local copilot_token
    copilot_token=$(get_token_for_runtime "copilot")
    
    if [[ -n "$copilot_token" ]]; then
        # Set GITHUB_PERSONAL_ACCESS_TOKEN for Copilot CLI's automatic GitHub MCP Server setup
        export GITHUB_PERSONAL_ACCESS_TOKEN="$copilot_token"
        log_success "GitHub MCP Server environment configured"
        log_info "Copilot CLI will automatically set up GitHub MCP Server on first run"
    else
        log_warning "No GitHub token found for automatic MCP server setup"
        log_info "Set GITHUB_COPILOT_PAT, GITHUB_APM_PAT, or GITHUB_TOKEN to enable automatic GitHub MCP Server"
        log_info "You can still configure MCP servers manually using 'apm install'"
    fi
}

# Create basic Copilot CLI directory structure
setup_copilot_directory() {
    log_info "Setting up Copilot CLI directory structure..."
    
    local copilot_config_dir="$HOME/.copilot"
    local mcp_config_file="$copilot_config_dir/mcp-config.json"
    
    # Create config directory if it doesn't exist
    if [[ ! -d "$copilot_config_dir" ]]; then
        log_info "Creating Copilot config directory: $copilot_config_dir"
        mkdir -p "$copilot_config_dir"
    fi
    
    # Create empty MCP configuration template only if file doesn't exist
    if [[ ! -f "$mcp_config_file" ]]; then
        log_info "Creating empty MCP configuration template..."
        cat > "$mcp_config_file" << 'EOF'
{
  "mcpServers": {}
}
EOF
        log_info "Empty MCP configuration created at $mcp_config_file"
        log_info "Use 'apm install' to configure MCP servers"
    else
        log_info "MCP configuration already exists at $mcp_config_file"
    fi
}

# Test Copilot CLI installation
test_copilot_installation() {
    log_info "Testing Copilot CLI installation..."
    
    if command -v copilot >/dev/null 2>&1; then
        if copilot --version >/dev/null 2>&1; then
            local version=$(copilot --version)
            log_success "Copilot CLI installed successfully! Version: $version"
        else
            log_warning "Copilot CLI binary found but version check failed"
            log_info "It may still work, but there might be authentication issues"
        fi
    else
        log_error "Copilot CLI not found in PATH after installation"
        log_info "You may need to restart your terminal or check your npm global installation path"
        exit 1
    fi
}

# Main setup function
setup_copilot() {
    log_info "Setting up GitHub Copilot CLI runtime..."
    
    # Check prerequisites
    check_node_version
    check_npm_version
    
    # Check and setup GitHub npm authentication
    if ! check_github_npm_auth; then
        setup_github_npm_auth
    fi
    
    # Install Copilot CLI
    install_copilot_cli
    
    # Setup directory structure (unless vanilla mode)
    if [[ "$VANILLA_MODE" == "false" ]]; then
        setup_copilot_directory
        # Setup GitHub MCP Server environment for automatic configuration
        setup_github_mcp_environment
    else
        log_info "Vanilla mode: Skipping APM directory setup"
        log_info "You can configure MCP servers manually in ~/.copilot/mcp-config.json"
    fi
    
    # Test installation
    test_copilot_installation
    
    # Show next steps
    echo ""
    log_info "Next steps:"
    
    if [[ "$VANILLA_MODE" == "false" ]]; then
        echo "1. Set up your APM project with MCP dependencies:"
        echo "   - Initialize project: apm init my-project"
        echo "   - Install MCP servers: apm install"
        echo "2. Then run: apm run start --param name=YourGitHubHandle"
        echo ""
        log_success "✨ GitHub Copilot CLI installed and configured!"
        echo "   - Use 'apm install' to configure MCP servers for your projects"
        echo "   - Copilot CLI provides advanced AI coding assistance"
        echo "   - Interactive mode available: just run 'copilot'"
    else
        echo "1. Configure Copilot CLI as needed (run 'copilot' for interactive setup)"
        echo "2. Then run with APM: apm run start"
    fi
    
    echo ""
    log_info "GitHub Copilot CLI Features:"
    echo "   - Interactive mode: copilot"
    echo "   - Direct prompts: copilot -p \"your prompt\""
    echo "   - Auto-approval: copilot --full-auto"
    echo "   - Directory access: copilot --add-dir /path/to/directory"
    echo "   - Logging: copilot --log-dir --log-level debug"
}

# Run setup if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_copilot "$@"
fi
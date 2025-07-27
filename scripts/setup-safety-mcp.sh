#!/bin/bash
# Setup Safety MCP Integration for VS Code
# This script configures Safety's Model Context Protocol integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[SETUP]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_status "Setting up Safety MCP Integration for VS Code..."

# Check if VS Code is installed
if ! command -v code &> /dev/null; then
    print_error "VS Code not found. Please install VS Code first."
    exit 1
fi

# Define paths
VSCODE_SETTINGS_DIR="$HOME/.config/Code/User"
MCP_CONFIG="$VSCODE_SETTINGS_DIR/mcp.json"
SETTINGS_JSON="$VSCODE_SETTINGS_DIR/settings.json"

# Check if VS Code settings directory exists
if [[ ! -d "$VSCODE_SETTINGS_DIR" ]]; then
    print_error "VS Code settings directory not found: $VSCODE_SETTINGS_DIR"
    exit 1
fi

print_status "Backing up existing configurations..."

# Backup existing configurations
if [[ -f "$MCP_CONFIG" ]]; then
    cp "$MCP_CONFIG" "$MCP_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    print_success "MCP config backed up"
fi

if [[ -f "$SETTINGS_JSON" ]]; then
    cp "$SETTINGS_JSON" "$SETTINGS_JSON.backup.$(date +%Y%m%d_%H%M%S)"
    print_success "VS Code settings backed up"
fi

print_status "Adding Safety MCP server to configuration..."

# Check if mcp.json exists and add Safety server
if [[ -f "$MCP_CONFIG" ]]; then
    # Use jq to add the safety-mcp server if it doesn't exist
    if command -v jq &> /dev/null; then
        # Check if safety-mcp already exists
        if jq -e '.servers."safety-mcp"' "$MCP_CONFIG" > /dev/null 2>&1; then
            print_warning "Safety MCP server already configured"
        else
            # Add safety-mcp server to existing configuration
            jq '.servers."safety-mcp" = {
                "type": "sse",
                "url": "https://mcp.safetycli.com/sse",
                "headers": {
                    "Authorization": "Bearer cbfb5d21-6a92-451d-8002-b4405bb6ca83"
                }
            }' "$MCP_CONFIG" > "${MCP_CONFIG}.tmp" && mv "${MCP_CONFIG}.tmp" "$MCP_CONFIG"
            print_success "Safety MCP server added to existing configuration"
        fi
    else
        print_warning "jq not found. You'll need to manually add Safety MCP to mcp.json"
        cat << 'EOF'

Add this to your mcp.json servers section:

"safety-mcp": {
    "type": "sse",
    "url": "https://mcp.safetycli.com/sse",
    "headers": {
        "Authorization": "Bearer cbfb5d21-6a92-451d-8002-b4405bb6ca83"
    }
}

EOF
    fi
else
    # Create new mcp.json with Safety server
    cat > "$MCP_CONFIG" << 'EOF'
{
    "inputs": [],
    "servers": {
        "safety-mcp": {
            "type": "sse",
            "url": "https://mcp.safetycli.com/sse",
            "headers": {
                "Authorization": "Bearer cbfb5d21-6a92-451d-8002-b4405bb6ca83"
            }
        }
    }
}
EOF
    print_success "Created new mcp.json with Safety MCP server"
fi

print_status "Adding VS Code MCP settings..."

# Check if settings.json exists and add MCP settings
if [[ -f "$SETTINGS_JSON" ]]; then
    if command -v jq &> /dev/null; then
        # Add MCP configuration to VS Code settings.json
        temp_settings=$(mktemp)
        jq '. + {
            "chat.mcp.discovery.enabled": true,
            "mcp": {
                "inputs": [],
                "servers": {
                    "safety-mcp": {
                        "url": "https://mcp.safetycli.com/sse",
                        "type": "sse",
                        "headers": {
                            "Authorization": "Bearer cbfb5d21-6a92-451d-8002-b4405bb6ca83"
                        }
                    }
                }
            }
        }' "$SETTINGS_JSON" > "$temp_settings" && mv "$temp_settings" "$SETTINGS_JSON"
        print_success "Added Safety MCP configuration to VS Code settings"
    else
        print_warning "jq not found. You'll need to manually add MCP settings to settings.json"
        cat << 'EOF'

Add this to your settings.json:

{
    "chat.mcp.discovery.enabled": true,
    "mcp": {
        "inputs": [],
        "servers": {
            "safety-mcp": {
                "url": "https://mcp.safetycli.com/sse", 
                "type": "sse",
                "headers": {
                    "Authorization": "Bearer cbfb5d21-6a92-451d-8002-b4405bb6ca83"
                }
            }
        }
    }
}

EOF
    fi
else
    # Create new settings.json with complete MCP configuration
    cat > "$SETTINGS_JSON" << 'EOF'
{
    "chat.mcp.discovery.enabled": true,
    "mcp": {
        "inputs": [],
        "servers": {
            "safety-mcp": {
                "url": "https://mcp.safetycli.com/sse",
                "type": "sse", 
                "headers": {
                    "Authorization": "Bearer cbfb5d21-6a92-451d-8002-b4405bb6ca83"
                }
            }
        }
    }
}
EOF
    print_success "Created new settings.json with complete MCP configuration"
fi

print_status "Setting up Copilot instructions for Safety integration..."

# Safety instructions for Copilot
SAFETY_INSTRUCTIONS="Every time you import a Python package or add a package to a requirements.txt or pyproject.toml, use the safety-mcp to check if the version you have chosen is secure and is the latest version of the package. Make sure you always use the latest_secure_version (returned by safety-mcp) for any package."

VULNERABILITY_CHECK_INSTRUCTIONS="If a package already exists in a codebase, and a user asks you to check it for vulnerabilities, use the safety-mcp and evaluate whether there are any secure versions in the same major version and acknowledge these options. Additionally, inform the user of the latest secure version of the package."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                    SAFETY MCP INTEGRATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "Safety MCP server configured for VS Code"
print_success "MCP discovery enabled"
print_success "Configuration files backed up"

echo ""
print_status "Next Steps:"
echo "1. Restart VS Code to apply MCP configuration"
echo "2. Switch to agent mode in Copilot chat"
echo "3. Add these instructions to your Copilot chat instructions:"
echo ""
echo -e "${YELLOW}Package Security Check:${NC}"
echo "   $SAFETY_INSTRUCTIONS"
echo ""
echo -e "${YELLOW}Vulnerability Assessment:${NC}"
echo "   $VULNERABILITY_CHECK_INSTRUCTIONS"
echo ""
echo "4. Test by asking Copilot to check a package: '@safety-mcp check numpy'"
echo ""
print_success "Safety MCP integration setup complete! 🛡️"

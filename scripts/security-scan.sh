#!/bin/bash
# Universal Security Scanner - Auto-generated
# Downloads and runs the latest comprehensive security scanner

set -e

REPO_NAME=$(basename "$(pwd)")
SCRIPT_URL="https://raw.githubusercontent.com/kairin/pass-git-helper/main/scripts/universal-security-scan.sh"

echo "🔍 Running universal security scan for: $REPO_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v curl &> /dev/null; then
    curl -sSL "$SCRIPT_URL" | bash
elif command -v wget &> /dev/null; then
    wget -qO- "$SCRIPT_URL" | bash
else
    echo "❌ Error: curl or wget required to download security scanner"
    echo "🔧 Please install curl or wget and try again"
    exit 1
fi

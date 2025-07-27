#!/bin/bash
# Quick Universal Safety Setup

echo "🔧 Setting up Universal Safety Configuration..."

# 1. Configure Safety globally
echo "Setting default stage to development..."
source .venv/bin/activate
safety configure --stage development

# 2. Set up environment variables
echo "Creating ~/.safety_env..."
cat > ~/.safety_env << 'EOF'
# Safety CLI Environment Variables
export SAFETY_API_KEY="cbfb5d21-6a92-451d-8002-b4405bb6ca83"
export SAFETY_STAGE="development"

# Universal aliases
alias security-scan='universal-security-scan.sh'
alias pip-secure='safety pip'
alias poetry-secure='safety poetry'
alias uv-secure='safety uv'
EOF

# 3. Add to shell profiles
echo "Adding to shell profiles..."
if [ -f ~/.bashrc ] && ! grep -q "source ~/.safety_env" ~/.bashrc; then
    echo "source ~/.safety_env" >> ~/.bashrc
    echo "✅ Added to ~/.bashrc"
fi

if [ -f ~/.zshrc ] && ! grep -q "source ~/.safety_env" ~/.zshrc; then
    echo "source ~/.safety_env" >> ~/.zshrc  
    echo "✅ Added to ~/.zshrc"
fi

# 4. Source Safety profile
if [ -f ~/.safety/.safety_profile ]; then
    source ~/.safety/.safety_profile
    echo "✅ Safety profile activated"
fi

echo ""
echo "🎉 Universal Safety Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.safety_env"
echo "2. Your API key is set: cbfb5d21-6a92-451d-8002-b4405bb6ca83"  
echo "3. Safety Firewall is protecting pip/poetry/uv globally"
echo "4. Run 'safety scan' in any Python repo"
echo ""
echo "🌐 Dashboard: https://platform.safetycli.com/"

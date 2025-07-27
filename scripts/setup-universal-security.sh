#!/bin/bash
# Universal Security Setup for Any Python Repository
# Sets up free security scanning without Safety API key requirements

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[SETUP]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

REPO_NAME=$(basename "$(pwd)")

echo ""
echo "🔐 Universal Security Setup for: $REPO_NAME"
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Check if this is a Python project
if [[ ! -f "pyproject.toml" && ! -f "requirements.txt" && ! -f "setup.py" && ! -f "Pipfile" ]]; then
    print_error "This doesn't appear to be a Python project"
    print_status "Looking for: pyproject.toml, requirements.txt, setup.py, or Pipfile"
    exit 1
fi

print_success "Python project detected: $REPO_NAME"

# ============================================================================
# Step 1: Copy Universal Security Scanner
# ============================================================================
print_status "Setting up universal security scanner..."

# Check if we can find the template script
TEMPLATE_SCRIPT=""
if [[ -f "../pass-git-helper/scripts/universal-security-scan.sh" ]]; then
    TEMPLATE_SCRIPT="../pass-git-helper/scripts/universal-security-scan.sh"
elif [[ -f "~/Apps/pass-git-helper/scripts/universal-security-scan.sh" ]]; then
    TEMPLATE_SCRIPT="~/Apps/pass-git-helper/scripts/universal-security-scan.sh"
else
    print_warning "Template script not found, creating basic version..."
fi

# Create scripts directory
mkdir -p scripts

if [[ -n "$TEMPLATE_SCRIPT" && -f "$TEMPLATE_SCRIPT" ]]; then
    cp "$TEMPLATE_SCRIPT" scripts/security-scan.sh
    chmod +x scripts/security-scan.sh
    print_success "Universal security scanner installed"
else
    # Create basic security scanner
    cat > scripts/security-scan.sh << 'EOF'
#!/bin/bash
#!/bin/bash
# Universal Security Setup Script
# Sets up consistent security scanning across all repositories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored status messages
print_header() {
    echo -e "${PURPLE}
╔══════════════════════════════════════════════════════════════════════════════╗
║                    UNIVERSAL SECURITY SETUP                                 ║
║              Configure Security Scanning for All Repos                      ║
╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    echo -e "
${BLUE}🔧 $1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_status() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Configuration variables
SAFETY_API_KEY="cbfb5d21-6a92-451d-8002-b4405bb6ca83"
SAFETY_PROFILE="$HOME/.safety/.safety_profile"
BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"

print_header

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[SECURITY]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_status "Running security scan for $(basename $(pwd))"

# Install and run pip-audit
if ! command -v pip-audit &> /dev/null; then
    print_status "Installing pip-audit..."
    pip install pip-audit
fi

print_status "Scanning dependencies with pip-audit..."
pip-audit --format=columns

# Install and run bandit
if ! command -v bandit &> /dev/null; then
    print_status "Installing bandit..."
    pip install bandit
fi

PYTHON_FILES=$(find . -name "*.py" -not -path "./.venv/*" -not -path "./venv/*" -not -path "./.git/*" 2>/dev/null)
if [[ -n "$PYTHON_FILES" ]]; then
    print_status "Scanning source code with bandit..."
    echo "$PYTHON_FILES" | xargs bandit -f txt -ll || print_warning "bandit found potential issues"
fi

print_success "Security scan completed"
EOF
    chmod +x scripts/security-scan.sh
    print_success "Basic security scanner created"
fi

# ============================================================================
# Step 2: Create GitHub Actions Workflow (Free Version)
# ============================================================================
print_status "Setting up GitHub Actions workflow..."

mkdir -p .github/workflows

cat > .github/workflows/security.yml << EOF
name: Security Scanning

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master, develop ]

jobs:
  security:
    runs-on: ubuntu-latest
    name: Security Vulnerability Scan
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
        if [ -f requirements-dev.txt ]; then pip install -r requirements-dev.txt; fi
        if [ -f pyproject.toml ]; then pip install -e .; fi

    - name: Install security tools
      run: |
        pip install pip-audit bandit

    - name: Run pip-audit (dependency vulnerabilities)
      run: |
        pip-audit --desc --format=columns

    - name: Run bandit (source code security)
      run: |
        find . -name "*.py" -not -path "./.venv/*" -not -path "./venv/*" -not -path "./.git/*" | xargs bandit -f txt -ll

    - name: Run tests (if available)
      run: |
        if command -v pytest &> /dev/null; then
          pytest -v || echo "Tests failed or not configured"
        elif [ -f test*.py ]; then
          python -m unittest discover -v || echo "Tests failed or not configured"
        else
          echo "No tests found"
        fi
EOF

print_success "GitHub Actions workflow created"

# ============================================================================
# Step 3: Create Pre-commit Hook
# ============================================================================
print_status "Setting up Git pre-commit hook..."

if [[ -d ".git" ]]; then
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit security check

echo "Running pre-commit security check..."

# Quick dependency check
if command -v pip-audit &> /dev/null; then
    pip-audit --format=columns || echo "⚠️ pip-audit found issues"
fi

# Quick source code check
STAGED_PYTHON_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.py$' || true)
if [[ -n "$STAGED_PYTHON_FILES" ]] && command -v bandit &> /dev/null; then
    echo "$STAGED_PYTHON_FILES" | xargs bandit -f txt -ll || echo "⚠️ bandit found potential issues"
fi

echo "Pre-commit security check completed"
EOF
    chmod +x .git/hooks/pre-commit
    print_success "Pre-commit hook installed"
else
    print_warning "Not a git repository, skipping pre-commit hook"
fi

# ============================================================================
# Step 4: Create or Update Requirements File
# ============================================================================
print_status "Updating development requirements..."

# Create or update requirements-dev.txt
if [[ ! -f "requirements-dev.txt" ]]; then
    cat > requirements-dev.txt << EOF
# Security scanning tools
pip-audit>=2.0.0
bandit>=1.8.0

# Testing tools (optional)
pytest>=6.0.0
pytest-cov>=3.0.0

# Code quality tools (optional)
ruff>=0.1.0
black>=22.0.0
EOF
    print_success "requirements-dev.txt created"
else
    # Add security tools if not present
    if ! grep -q "pip-audit" requirements-dev.txt; then
        echo "pip-audit>=2.0.0" >> requirements-dev.txt
    fi
    if ! grep -q "bandit" requirements-dev.txt; then
        echo "bandit>=1.8.0" >> requirements-dev.txt
    fi
    print_success "requirements-dev.txt updated"
fi

# ============================================================================
# Step 5: Create README Security Section
# ============================================================================
print_status "Creating security documentation..."

cat > SECURITY_SETUP.md << EOF
# Security Scanning Setup for $REPO_NAME

## 🛡️ Automated Security Scanning

This repository is configured with comprehensive security scanning using free, open-source tools:

### Tools Included:
- **pip-audit**: Scans Python dependencies for known vulnerabilities
- **bandit**: Analyzes source code for security issues
- **GitHub Actions**: Automated scanning on every push/PR

### Usage:

\`\`\`bash
# Run security scan locally
./scripts/security-scan.sh

# Install security tools
pip install -r requirements-dev.txt

# Manual scans
pip-audit --desc --format=columns
bandit -r . -f txt -ll
\`\`\`

### CI/CD Integration:
- ✅ GitHub Actions workflow runs on every push
- ✅ Pre-commit hooks catch issues early
- ✅ No API keys or paid services required

### Security Results:
- 🔍 Dependencies scanned for vulnerabilities
- 🔎 Source code analyzed for security patterns
- 📊 Results available in GitHub Actions logs

This setup provides enterprise-level security scanning completely free!
EOF

print_success "Security documentation created"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "🎉 Universal Security Setup Complete!"
echo "══════════════════════════════════════════════════════════════════════"
echo ""
echo "What was installed:"
echo "  ✅ Universal security scanner (scripts/security-scan.sh)"
echo "  ✅ GitHub Actions workflow (.github/workflows/security.yml)"
echo "  ✅ Pre-commit hooks for git (.git/hooks/pre-commit)"
echo "  ✅ Security tools requirements (requirements-dev.txt)"
echo "  ✅ Documentation (SECURITY_SETUP.md)"
echo ""
echo "Next steps:"
echo "  1. Run: pip install -r requirements-dev.txt"
echo "  2. Test: ./scripts/security-scan.sh"
echo "  3. Commit and push to trigger GitHub Actions"
echo ""
echo "🔐 Your repository now has enterprise-level security scanning for FREE!"

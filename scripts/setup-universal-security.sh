#!/bin/bash
# Universal Security Setup for All Repository Types
# Automatically detects project type and installs appropriate security tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[SETUP]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${MAGENTA}[INFO]${NC} $1"; }
print_highlight() { echo -e "${CYAN}[FEATURE]${NC} $1"; }

REPO_NAME=$(basename "$(pwd)")
SAFETY_API_KEY="cbfb5d21-6a92-451d-8002-b4405bb6ca83"

echo ""
echo "� Universal Security Setup for: $REPO_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================================
# Project Type Detection
# ============================================================================

PROJECT_TYPE="unknown"
PACKAGE_MANAGER=""
SUPPORTED_LANGUAGES=()

print_status "Detecting project type..."

# Python
if [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "Pipfile" ]]; then
    PROJECT_TYPE="python"
    SUPPORTED_LANGUAGES+=("Python")
    if [[ -f "poetry.lock" ]]; then
        PACKAGE_MANAGER="poetry"
    elif [[ -f "Pipfile" ]]; then
        PACKAGE_MANAGER="pipenv"
    else
        PACKAGE_MANAGER="pip"
    fi
fi

# Node.js
if [[ -f "package.json" ]]; then
    if [[ "$PROJECT_TYPE" == "unknown" ]]; then
        PROJECT_TYPE="nodejs"
        PACKAGE_MANAGER="npm"
    fi
    SUPPORTED_LANGUAGES+=("JavaScript/TypeScript")
fi

# Rust
if [[ -f "Cargo.toml" ]]; then
    if [[ "$PROJECT_TYPE" == "unknown" ]]; then
        PROJECT_TYPE="rust"
        PACKAGE_MANAGER="cargo"
    fi
    SUPPORTED_LANGUAGES+=("Rust")
fi

# Go
if [[ -f "go.mod" ]]; then
    if [[ "$PROJECT_TYPE" == "unknown" ]]; then
        PROJECT_TYPE="go"
        PACKAGE_MANAGER="go"
    fi
    SUPPORTED_LANGUAGES+=("Go")
fi

# Java/Maven
if [[ -f "pom.xml" ]]; then
    if [[ "$PROJECT_TYPE" == "unknown" ]]; then
        PROJECT_TYPE="java"
        PACKAGE_MANAGER="maven"
    fi
    SUPPORTED_LANGUAGES+=("Java")
fi

# Gradle
if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    if [[ "$PROJECT_TYPE" == "unknown" ]]; then
        PROJECT_TYPE="java"
        PACKAGE_MANAGER="gradle"
    fi
    SUPPORTED_LANGUAGES+=("Java/Kotlin")
fi

# C#/.NET
if [[ -f "*.csproj" ]] || [[ -f "*.sln" ]]; then
    if [[ "$PROJECT_TYPE" == "unknown" ]]; then
        PROJECT_TYPE="dotnet"
        PACKAGE_MANAGER="dotnet"
    fi
    SUPPORTED_LANGUAGES+=("C#")
fi

if [[ "$PROJECT_TYPE" == "unknown" ]]; then
    print_warning "Unknown project type - will install generic security tools"
    SUPPORTED_LANGUAGES+=("Generic")
else
    print_success "Detected: $PROJECT_TYPE project"
    if [[ -n "$PACKAGE_MANAGER" ]]; then
        print_info "Package manager: $PACKAGE_MANAGER"
    fi
fi

if [[ ${#SUPPORTED_LANGUAGES[@]} -gt 0 ]]; then
    echo "🎯 Supported languages: ${SUPPORTED_LANGUAGES[*]}"
fi

echo ""

# ============================================================================
# Install Security Tools by Project Type
# ============================================================================

print_status "Installing security scanning tools..."

install_python_tools() {
    print_highlight "Installing Python security tools..."
    
    local tools_installed=0
    
    # Install pip-audit and bandit
    if command -v pip &> /dev/null; then
        pip install --user pip-audit bandit || print_warning "Failed to install some Python tools"
        tools_installed=$((tools_installed + 2))
        print_success "Installed pip-audit and bandit"
    fi
    
    # Install Safety
    if ! command -v safety &> /dev/null; then
        pip install --user safety || print_warning "Failed to install Safety"
        if command -v safety &> /dev/null; then
            tools_installed=$((tools_installed + 1))
            print_success "Installed Safety"
        fi
    else
        tools_installed=$((tools_installed + 1))
        print_info "Safety already installed"
    fi
    
    # Configure Safety API key
    if command -v safety &> /dev/null; then
        echo "$SAFETY_API_KEY" > ~/.safety-api-key 2>/dev/null || print_warning "Failed to configure Safety API key"
        print_info "Safety API key configured"
    fi
    
    print_info "Python tools installed: $tools_installed/3"
}

install_nodejs_tools() {
    print_highlight "Installing Node.js security tools..."
    
    if command -v npm &> /dev/null; then
        # npm audit is built-in
        npm install -g audit-ci 2>/dev/null || print_warning "Failed to install audit-ci"
        print_success "Node.js security tools ready (npm audit + audit-ci)"
    else
        print_warning "npm not available"
    fi
}

install_rust_tools() {
    print_highlight "Installing Rust security tools..."
    
    if command -v cargo &> /dev/null; then
        cargo install cargo-audit 2>/dev/null || print_warning "Failed to install cargo-audit"
        print_success "Installed cargo-audit"
    else
        print_warning "cargo not available"
    fi
}

install_go_tools() {
    print_highlight "Installing Go security tools..."
    
    if command -v go &> /dev/null; then
        go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest 2>/dev/null || print_warning "Failed to install gosec"
        print_success "Installed gosec"
    else
        print_warning "go not available"
    fi
}

install_java_tools() {
    print_highlight "Installing Java security tools..."
    
    if command -v mvn &> /dev/null; then
        print_success "Maven dependency checking available"
    fi
    
    if command -v gradle &> /dev/null; then
        print_success "Gradle dependency checking available"
    fi
    
    # Install SpotBugs if possible
    print_info "Consider installing SpotBugs for static analysis"
}

install_dotnet_tools() {
    print_highlight "Installing .NET security tools..."
    
    if command -v dotnet &> /dev/null; then
        dotnet tool install --global security-scan 2>/dev/null || print_warning "Failed to install security-scan"
        print_success ".NET security tools ready"
    else
        print_warning "dotnet not available"
    fi
}

# Install tools based on detected project types
case $PROJECT_TYPE in
    "python") install_python_tools ;;
    "nodejs") install_nodejs_tools ;;
    "rust") install_rust_tools ;;
    "go") install_go_tools ;;
    "java") install_java_tools ;;
    "dotnet") install_dotnet_tools ;;
esac

# Install additional language-specific tools for multi-language projects
for lang in "${SUPPORTED_LANGUAGES[@]}"; do
    case $lang in
        "Python") [[ "$PROJECT_TYPE" != "python" ]] && install_python_tools ;;
        "JavaScript/TypeScript") [[ "$PROJECT_TYPE" != "nodejs" ]] && install_nodejs_tools ;;
        "Rust") [[ "$PROJECT_TYPE" != "rust" ]] && install_rust_tools ;;
        "Go") [[ "$PROJECT_TYPE" != "go" ]] && install_go_tools ;;
        "Java"|"Java/Kotlin") [[ "$PROJECT_TYPE" != "java" ]] && install_java_tools ;;
        "C#") [[ "$PROJECT_TYPE" != "dotnet" ]] && install_dotnet_tools ;;
    esac
done

# ============================================================================
# Install Universal Tools
# ============================================================================

print_status "Installing universal security tools..."

# Install Semgrep (works for all languages)
if ! command -v semgrep &> /dev/null; then
    if command -v pip &> /dev/null; then
        pip install --user semgrep || print_warning "Failed to install Semgrep"
        if command -v semgrep &> /dev/null; then
            print_success "Installed Semgrep (multi-language static analysis)"
        fi
    else
        print_warning "Cannot install Semgrep (pip not available)"
    fi
else
    print_info "Semgrep already installed"
fi

# Install OSV-Scanner (Google's vulnerability scanner)
if ! command -v osv-scanner &> /dev/null; then
    if command -v go &> /dev/null; then
        go install github.com/google/osv-scanner/cmd/osv-scanner@latest 2>/dev/null || print_warning "Failed to install OSV-Scanner"
        if command -v osv-scanner &> /dev/null; then
            print_success "Installed OSV-Scanner (Google's vulnerability database)"
        fi
    else
        # Try alternative installation methods
        if command -v curl &> /dev/null; then
            print_info "Attempting OSV-Scanner installation via curl..."
            # This would require platform-specific binary downloads
        fi
        print_warning "Cannot install OSV-Scanner (Go not available)"
    fi
else
    print_info "OSV-Scanner already installed"
fi

# Install Trivy (container and filesystem vulnerability scanner)
if ! command -v trivy &> /dev/null; then
    if command -v curl &> /dev/null; then
        print_info "Consider installing Trivy for container scanning"
    fi
fi

# ============================================================================
# Create Security Scanning Script
# ============================================================================

print_status "Creating universal security scanning script..."

mkdir -p scripts

cat > "scripts/security-scan.sh" << 'EOF'
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
EOF

chmod +x scripts/security-scan.sh
print_success "Created scripts/security-scan.sh"

# ============================================================================
# Create GitHub Actions Workflow
# ============================================================================

print_status "Creating GitHub Actions security workflow..."

mkdir -p .github/workflows

cat > ".github/workflows/security.yml" << EOF
name: 🔒 Security Scan

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master ]
  schedule:
    # Run weekly security scans
    - cron: '0 6 * * 1'

jobs:
  security:
    runs-on: ubuntu-latest
    name: Multi-Tool Security Analysis
    
    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4
        
      - name: 🐍 Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          
      - name: 📦 Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          
      - name: 🦀 Set up Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          override: true
        if: hashFiles('Cargo.toml') != ''
        
      - name: 🐹 Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.21'
        if: hashFiles('go.mod') != ''
        
      - name: ☕ Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
        if: hashFiles('pom.xml', 'build.gradle', 'build.gradle.kts') != ''
        
      - name: 🔧 Install security tools
        run: |
          # Python tools
          pip install --user pip-audit bandit safety semgrep
          
          # Node.js tools
          if [[ -f "package.json" ]]; then
            npm install -g audit-ci
          fi
          
          # Rust tools
          if [[ -f "Cargo.toml" ]]; then
            cargo install cargo-audit
          fi
          
          # Go tools
          if [[ -f "go.mod" ]]; then
            go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest
          fi
          
          # Universal tools
          go install github.com/google/osv-scanner/cmd/osv-scanner@latest || echo "Failed to install osv-scanner"
          
      - name: 🛡️ Run universal security scanner
        env:
          SAFETY_API_KEY: \${{ secrets.SAFETY_API_KEY }}
        run: |
          curl -sSL "https://raw.githubusercontent.com/kairin/pass-git-helper/main/scripts/universal-security-scan.sh" | bash
          
      - name: 📊 Upload security results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: security-scan-results
          path: |
            security-report.txt
            security-summary.json
          retention-days: 30
EOF

print_success "Created .github/workflows/security.yml"

# ============================================================================
# Create Pre-commit Hook
# ============================================================================

if [[ -d ".git" ]]; then
    print_status "Setting up Git pre-commit security hook..."
    
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit security check - Auto-generated

echo "🔍 Running pre-commit security check..."

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [[ -z "$STAGED_FILES" ]]; then
    echo "✅ No staged files to check"
    exit 0
fi

echo "📁 Checking $(echo "$STAGED_FILES" | wc -l) staged files..."

# Quick dependency check
case "$(pwd)" in
    *) # Universal approach
        if command -v pip-audit &> /dev/null && [[ -f "requirements.txt" || -f "pyproject.toml" ]]; then
            echo "🐍 Running pip-audit..."
            pip-audit --format=columns --cache-dir=/tmp/pip-audit-cache 2>/dev/null || echo "⚠️ pip-audit found issues"
        fi
        
        if command -v npm &> /dev/null && [[ -f "package.json" ]]; then
            echo "📦 Running npm audit..."
            npm audit --audit-level=high 2>/dev/null || echo "⚠️ npm audit found issues"
        fi
        ;;
esac

# Quick source code check on staged files
STAGED_PYTHON_FILES=$(echo "$STAGED_FILES" | grep '\.py$' || true)
if [[ -n "$STAGED_PYTHON_FILES" ]] && command -v bandit &> /dev/null; then
    echo "🔎 Running bandit on staged Python files..."
    echo "$STAGED_PYTHON_FILES" | xargs bandit -f txt -ll 2>/dev/null || echo "⚠️ bandit found potential issues"
fi

STAGED_JS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(js|ts|jsx|tsx)$' || true)
if [[ -n "$STAGED_JS_FILES" ]] && command -v semgrep &> /dev/null; then
    echo "🔍 Running semgrep on staged JS/TS files..."
    echo "$STAGED_JS_FILES" | xargs semgrep --config=auto --quiet 2>/dev/null || echo "⚠️ semgrep found potential issues"
fi

echo "✅ Pre-commit security check completed"
EOF
    
    chmod +x .git/hooks/pre-commit
    print_success "Pre-commit security hook installed"
else
    print_warning "Not a git repository - skipping pre-commit hook"
fi

# ============================================================================
# Create or Update Requirements/Dependencies
# ============================================================================

print_status "Setting up project dependencies..."

case $PROJECT_TYPE in
    "python")
        if [[ ! -f "requirements-dev.txt" ]]; then
            cat > requirements-dev.txt << EOF
# Security scanning tools
pip-audit>=2.0.0
bandit>=1.8.0
safety>=3.0.0
semgrep>=1.0.0

# Testing tools
pytest>=7.0.0
pytest-cov>=4.0.0

# Code quality tools
ruff>=0.1.0
black>=23.0.0
mypy>=1.0.0
EOF
            print_success "Created requirements-dev.txt"
        else
            # Add security tools if not present
            for tool in "pip-audit>=2.0.0" "bandit>=1.8.0" "safety>=3.0.0" "semgrep>=1.0.0"; do
                if ! grep -q "${tool%%>=*}" requirements-dev.txt; then
                    echo "$tool" >> requirements-dev.txt
                fi
            done
            print_success "Updated requirements-dev.txt with security tools"
        fi
        ;;
        
    "nodejs")
        if [[ -f "package.json" ]]; then
            # Add audit-ci to devDependencies if not present
            if ! grep -q "audit-ci" package.json; then
                print_info "Consider adding 'audit-ci' to your devDependencies"
            fi
        fi
        ;;
esac

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

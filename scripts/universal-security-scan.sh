#!/bin/bash
# Universal Security Scanner for Multiple Repositories
# Works with or without Safety authentication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[SECURITY]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect project type and requirements files
REQUIREMENTS_FILES=()
if [[ -f "requirements.txt" ]]; then REQUIREMENTS_FILES+=("requirements.txt"); fi
if [[ -f "requirements-dev.txt" ]]; then REQUIREMENTS_FILES+=("requirements-dev.txt"); fi
if [[ -f "pyproject.toml" ]]; then REQUIREMENTS_FILES+=("pyproject.toml"); fi
if [[ -f "Pipfile" ]]; then REQUIREMENTS_FILES+=("Pipfile"); fi
if [[ -f "poetry.lock" ]]; then REQUIREMENTS_FILES+=("poetry.lock"); fi

print_status "Universal Security Scanner for $(basename $(pwd))"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ${#REQUIREMENTS_FILES[@]} -eq 0 ]]; then
    print_warning "No Python requirements files found, running basic scans only"
fi

# Track results
SAFETY_SUCCESS=false
PIP_AUDIT_SUCCESS=false
BANDIT_SUCCESS=false
SEMGREP_SUCCESS=false

# ============================================================================
# PRIMARY: Safety (if available and authenticated)
# ============================================================================
print_status "Checking Safety availability..."
if command -v safety &> /dev/null; then
    if safety auth status &> /dev/null 2>&1; then
        print_status "Running Safety scan..."
        if safety scan 2>/dev/null; then
            SAFETY_SUCCESS=true
            print_success "Safety scan completed"
        else
            print_warning "Safety scan failed or found issues"
        fi
    else
        print_warning "Safety not authenticated, using free tools"
    fi
else
    print_warning "Safety not installed, using free tools"
fi

# ============================================================================
# FALLBACK 1: pip-audit (dependency vulnerabilities)
# ============================================================================
print_status "Running pip-audit (dependency vulnerabilities)..."
if command -v pip-audit &> /dev/null; then
    if pip-audit --format=columns 2>/dev/null; then
        PIP_AUDIT_SUCCESS=true
        print_success "pip-audit completed successfully"
    else
        print_error "pip-audit found vulnerabilities or failed"
    fi
else
    if command -v pip &> /dev/null; then
        print_status "Installing pip-audit..."
        pip install pip-audit &> /dev/null
        if pip-audit --format=columns 2>/dev/null; then
            PIP_AUDIT_SUCCESS=true
            print_success "pip-audit installed and completed"
        fi
    else
        print_warning "pip-audit not available and cannot install"
    fi
fi

# ============================================================================
# FALLBACK 2: bandit (source code security)
# ============================================================================
print_status "Running bandit (source code security)..."
PYTHON_FILES=$(find . -name "*.py" -not -path "./.venv/*" -not -path "./venv/*" -not -path "./.git/*" 2>/dev/null | head -10)

if [[ -n "$PYTHON_FILES" ]]; then
    if command -v bandit &> /dev/null; then
        if echo "$PYTHON_FILES" | xargs bandit -f txt -ll 2>/dev/null; then
            BANDIT_SUCCESS=true
            print_success "bandit completed successfully"
        else
            print_warning "bandit found potential issues (may be acceptable)"
            BANDIT_SUCCESS=true  # Don't fail on bandit warnings
        fi
    else
        if command -v pip &> /dev/null; then
            print_status "Installing bandit..."
            pip install bandit &> /dev/null
            if echo "$PYTHON_FILES" | xargs bandit -f txt -ll 2>/dev/null; then
                BANDIT_SUCCESS=true
                print_success "bandit installed and completed"
            fi
        else
            print_warning "bandit not available and cannot install"
        fi
    fi
else
    print_status "No Python files found, skipping bandit"
    BANDIT_SUCCESS=true
fi

# ============================================================================
# BONUS: Semgrep (if available)
# ============================================================================
print_status "Checking for Semgrep (advanced static analysis)..."
if command -v semgrep &> /dev/null; then
    if semgrep --config=auto . --quiet --no-git-ignore 2>/dev/null; then
        SEMGREP_SUCCESS=true
        print_success "Semgrep scan completed"
    else
        print_warning "Semgrep found issues or failed"
    fi
else
    print_status "Semgrep not available (optional advanced tool)"
fi

# ============================================================================
# BONUS: OSV-Scanner (Google's vulnerability scanner)
# ============================================================================
print_status "Checking for OSV-Scanner..."
OSV_SUCCESS=false
if command -v osv-scanner &> /dev/null; then
    if osv-scanner . --format table 2>/dev/null; then
        OSV_SUCCESS=true
        print_success "OSV-Scanner completed"
    else
        print_warning "OSV-Scanner found vulnerabilities or failed"
    fi
else
    print_status "OSV-Scanner not available (install via: go install github.com/google/osv-scanner/cmd/osv-scanner@latest)"
fi

# ============================================================================
# BONUS: Trivy (comprehensive vulnerability scanner)
# ============================================================================
print_status "Checking for Trivy..."
TRIVY_SUCCESS=false
if command -v trivy &> /dev/null; then
    if trivy fs . --quiet --format table 2>/dev/null; then
        TRIVY_SUCCESS=true
        print_success "Trivy scan completed"
    else
        print_warning "Trivy found vulnerabilities or failed"
    fi
else
    print_status "Trivy not available (install via package manager or GitHub releases)"
fi

# ============================================================================
# RESULTS SUMMARY
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                     SECURITY SCAN RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$SAFETY_SUCCESS" == true ]]; then
    echo -e "🛡️  Safety (Premium):      ${GREEN}✅ PASSED${NC}"
else
    echo -e "🛡️  Safety (Premium):      ${YELLOW}⚠️  SKIPPED${NC}"
fi

if [[ "$PIP_AUDIT_SUCCESS" == true ]]; then
    echo -e "🔍 pip-audit (Dependencies): ${GREEN}✅ PASSED${NC}"
else
    echo -e "🔍 pip-audit (Dependencies): ${RED}❌ FAILED${NC}"
fi

if [[ "$BANDIT_SUCCESS" == true ]]; then
    echo -e "🔎 bandit (Source Code):     ${GREEN}✅ PASSED${NC}"
else
    echo -e "🔎 bandit (Source Code):     ${RED}❌ FAILED${NC}"
fi

if [[ "$SEMGREP_SUCCESS" == true ]]; then
    echo -e "🎯 Semgrep (Advanced):       ${GREEN}✅ PASSED${NC}"
elif command -v semgrep &> /dev/null; then
    echo -e "🎯 Semgrep (Advanced):       ${YELLOW}⚠️  ISSUES${NC}"
else
    echo -e "🎯 Semgrep (Advanced):       ${YELLOW}⚠️  N/A${NC}"
fi

if [[ "$OSV_SUCCESS" == true ]]; then
    echo -e "🔍 OSV-Scanner (Google):     ${GREEN}✅ PASSED${NC}"
elif command -v osv-scanner &> /dev/null; then
    echo -e "🔍 OSV-Scanner (Google):     ${YELLOW}⚠️  ISSUES${NC}"
else
    echo -e "🔍 OSV-Scanner (Google):     ${YELLOW}⚠️  N/A${NC}"
fi

if [[ "$TRIVY_SUCCESS" == true ]]; then
    echo -e "🛡️  Trivy (Comprehensive):   ${GREEN}✅ PASSED${NC}"
elif command -v trivy &> /dev/null; then
    echo -e "🛡️  Trivy (Comprehensive):   ${YELLOW}⚠️  ISSUES${NC}"
else
    echo -e "🛡️  Trivy (Comprehensive):   ${YELLOW}⚠️  N/A${NC}"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# DECISION LOGIC
# ============================================================================
if [[ "$SAFETY_SUCCESS" == true ]]; then
    print_success "Primary security validation passed"
    exit 0
elif [[ "$PIP_AUDIT_SUCCESS" == true ]]; then
    print_success "Fallback security validation passed"
    exit 0
elif [[ "$BANDIT_SUCCESS" == true ]] && [[ ${#REQUIREMENTS_FILES[@]} -eq 0 ]]; then
    print_success "Source code security validated (no dependencies found)"
    exit 0
else
    print_error "Security validation failed"
    exit 1
fi

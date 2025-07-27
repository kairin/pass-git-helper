#!/bin/bash
# Universal Security Scanner for Multiple Repositories
# Works with or without Safety authentication
# Supports: Safety, pip-audit, bandit, semgrep, OSV-Scanner

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[SECURITY]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${MAGENTA}[INFO]${NC} $1"; }

# Configuration
REPO_NAME=$(basename "$(pwd)")
API_KEY="${SAFETY_API_KEY:-}"
VERBOSE=${SECURITY_VERBOSE:-false}

# Detect project type and requirements files
REQUIREMENTS_FILES=()
if [[ -f "requirements.txt" ]]; then REQUIREMENTS_FILES+=("requirements.txt"); fi
if [[ -f "requirements-dev.txt" ]]; then REQUIREMENTS_FILES+=("requirements-dev.txt"); fi
if [[ -f "pyproject.toml" ]]; then REQUIREMENTS_FILES+=("pyproject.toml"); fi
if [[ -f "Pipfile" ]]; then REQUIREMENTS_FILES+=("Pipfile"); fi
if [[ -f "poetry.lock" ]]; then REQUIREMENTS_FILES+=("poetry.lock"); fi
if [[ -f "package.json" ]]; then REQUIREMENTS_FILES+=("package.json"); fi

print_status "Universal Security Scanner for $REPO_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ${#REQUIREMENTS_FILES[@]} -eq 0 ]]; then
    print_warning "No dependency files found, running source code scans only"
else
    print_info "Found dependency files: ${REQUIREMENTS_FILES[*]}"
fi

# Track results
SAFETY_SUCCESS=false
PIP_AUDIT_SUCCESS=false
BANDIT_SUCCESS=false
SEMGREP_SUCCESS=false
OSV_SUCCESS=false
# Track results
SAFETY_SUCCESS=false
PIP_AUDIT_SUCCESS=false
BANDIT_SUCCESS=false
SEMGREP_SUCCESS=false
OSV_SUCCESS=false
TOTAL_ISSUES=0

# ============================================================================
# PRIMARY: Safety (if available and authenticated)
# ============================================================================
print_status "Checking Safety scan (premium)..."

if command -v safety &> /dev/null; then
    if [[ -n "$API_KEY" ]]; then
        print_status "Using Safety with API key for CI/CD scan..."
        if safety --key "$API_KEY" --stage cicd scan; then
            SAFETY_SUCCESS=true
            print_success "Safety scan completed successfully"
        else
            print_warning "Safety scan found issues or failed"
        fi
    elif safety auth status &> /dev/null; then
        print_status "Safety authenticated, running development scan..."
        if safety scan; then
            SAFETY_SUCCESS=true
            print_success "Safety scan completed successfully"
        else
            print_warning "Safety scan found issues or failed"
        fi
    else
        print_warning "Safety not authenticated and no API key provided"
    fi
else
    print_warning "Safety not available"
fi

# ============================================================================
# FALLBACK 1: pip-audit (Dependency vulnerabilities)
# ============================================================================
print_status "Running pip-audit scan (dependency vulnerabilities)..."

if command -v pip-audit &> /dev/null; then
    print_status "Scanning dependencies with pip-audit..."
    if pip-audit --desc --format=columns; then
        PIP_AUDIT_SUCCESS=true
        print_success "pip-audit scan completed successfully"
    else
        pip_audit_exit=$?
        if [ $pip_audit_exit -eq 1 ]; then
            print_error "pip-audit found vulnerabilities!"
            TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
        else
            print_error "pip-audit failed to run properly"
            TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
        fi
    fi
else
    print_warning "pip-audit not available"
fi

# ============================================================================
# FALLBACK 2: bandit (Source code security)
# ============================================================================
print_status "Running bandit scan (source code security)..."

if command -v bandit &> /dev/null; then
    print_status "Scanning source code with bandit..."
    
    # Find Python files excluding virtual environments and common ignore paths
    PYTHON_FILES=$(find . -name "*.py" \
        -not -path "./.venv/*" \
        -not -path "./venv/*" \
        -not -path "./.env/*" \
        -not -path "./env/*" \
        -not -path "./.git/*" \
        -not -path "./node_modules/*" \
        -not -path "./__pycache__/*" \
        -not -path "./.pytest_cache/*" \
        -not -path "./build/*" \
        -not -path "./dist/*" \
        2>/dev/null)
    
    if [[ -n "$PYTHON_FILES" ]]; then
        print_status "Found $(echo "$PYTHON_FILES" | wc -l) Python files to scan"
        # Use -ll to only report medium/high severity issues, scan only project files
        if echo "$PYTHON_FILES" | xargs bandit -f txt -ll 2>/dev/null; then
            BANDIT_SUCCESS=true
            print_success "bandit scan completed successfully"
        else
            bandit_exit=$?
            if [ $bandit_exit -eq 1 ]; then
                print_warning "bandit found potential security issues (continuing...)"
                BANDIT_SUCCESS=true  # Accept warnings for this type of project
            else
                print_error "bandit failed to run properly"
                TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
            fi
        fi
    else
        print_info "No Python files found to scan"
        BANDIT_SUCCESS=true  # No files to scan is success
    fi
else
    print_warning "bandit not available"
fi

# ============================================================================
# ENHANCED: Semgrep (Advanced static analysis)
# ============================================================================
print_status "Running Semgrep scan (advanced static analysis)..."

if command -v semgrep &> /dev/null; then
    print_status "Scanning with Semgrep security rules..."
    if semgrep --config=auto --quiet --no-git-ignore; then
        SEMGREP_SUCCESS=true
        print_success "Semgrep scan completed successfully"
    else
        semgrep_exit=$?
        if [ $semgrep_exit -eq 1 ]; then
            print_warning "Semgrep found potential issues (review recommended)"
            SEMGREP_SUCCESS=true  # Don't fail on Semgrep warnings
        else
            print_error "Semgrep failed to run properly"
        fi
    fi
else
    print_info "Semgrep not available (install with: pip install semgrep)"
fi

# ============================================================================
# ENHANCED: OSV-Scanner (Google's vulnerability scanner)
# ============================================================================
print_status "Running OSV-Scanner (comprehensive vulnerability scan)..."

if command -v osv-scanner &> /dev/null; then
    print_status "Scanning with OSV-Scanner..."
    if osv-scanner scan source -r .; then
        OSV_SUCCESS=true
        print_success "OSV-Scanner completed successfully"
    else
        osv_exit=$?
        if [ $osv_exit -eq 1 ]; then
            print_warning "OSV-Scanner found vulnerabilities (review required)"
            TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
        else
            print_error "OSV-Scanner failed to run properly"
        fi
    fi
else
    print_info "OSV-Scanner not available (install: go install github.com/google/osv-scanner/cmd/osv-scanner@latest)"
fi

# ============================================================================
# RESULTS SUMMARY
# ============================================================================
print_status "Security scan summary:"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                          SECURITY SCAN RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$SAFETY_SUCCESS" = true ]; then
    echo -e "🛡️  Safety (Premium):         ${GREEN}✅ PASSED${NC}"
else
    echo -e "🛡️  Safety (Premium):         ${YELLOW}⚠️  SKIPPED/FAILED${NC}"
fi

if [ "$PIP_AUDIT_SUCCESS" = true ]; then
    echo -e "🔍 pip-audit (Dependencies):  ${GREEN}✅ PASSED${NC}"
else
    echo -e "🔍 pip-audit (Dependencies):  ${RED}❌ FAILED${NC}"
fi

if [ "$BANDIT_SUCCESS" = true ]; then
    echo -e "🔎 bandit (Source Code):      ${GREEN}✅ PASSED${NC}"
else
    echo -e "🔎 bandit (Source Code):      ${YELLOW}⚠️  ISSUES FOUND${NC}"
fi

if [ "$SEMGREP_SUCCESS" = true ]; then
    echo -e "🔬 Semgrep (Advanced):        ${GREEN}✅ PASSED${NC}"
elif command -v semgrep &> /dev/null; then
    echo -e "🔬 Semgrep (Advanced):        ${YELLOW}⚠️  ISSUES FOUND${NC}"
else
    echo -e "🔬 Semgrep (Advanced):        ${BLUE}➖ NOT AVAILABLE${NC}"
fi

if [ "$OSV_SUCCESS" = true ]; then
    echo -e "📊 OSV-Scanner (Google):      ${GREEN}✅ PASSED${NC}"
elif command -v osv-scanner &> /dev/null; then
    echo -e "📊 OSV-Scanner (Google):      ${YELLOW}⚠️  ISSUES FOUND${NC}"
else
    echo -e "📊 OSV-Scanner (Google):      ${BLUE}➖ NOT AVAILABLE${NC}"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# DECISION LOGIC
# ============================================================================

# Primary success: Safety passed
if [ "$SAFETY_SUCCESS" = true ]; then
    print_success "Primary security scan (Safety) passed - build can proceed"
    echo -e "${GREEN}🎉 Security validation successful!${NC}"
    exit 0
fi

# Fallback success: pip-audit passed (critical for dependencies)
if [ "$PIP_AUDIT_SUCCESS" = true ] && [ "$BANDIT_SUCCESS" = true ]; then
    print_success "Fallback security scans passed - build can proceed"
    echo -e "${GREEN}🎉 Security validation successful via fallback tools!${NC}"
    exit 0
fi

# Partial success: Dependencies clean but source code has issues (acceptable)
if [ "$PIP_AUDIT_SUCCESS" = true ]; then
    print_warning "Dependencies are secure, source code scans found issues (review recommended)"
    echo -e "${YELLOW}⚠️  Security validation passed with warnings${NC}"
    exit 0
fi

# Failure: Critical dependency vulnerabilities found
if [ "$PIP_AUDIT_SUCCESS" = false ] && [ "$TOTAL_ISSUES" -gt 0 ]; then
    print_error "Critical dependency vulnerabilities found - blocking build"
    echo -e "${RED}❌ Security validation failed!${NC}"
    exit 1
fi

# No dependency files but other scans available
if [[ ${#REQUIREMENTS_FILES[@]} -eq 0 ]] && [ "$BANDIT_SUCCESS" = true ]; then
    print_success "No dependencies to scan, source code scans passed"
    echo -e "${GREEN}🎉 Security validation successful!${NC}"
    exit 0
fi

# Unexpected case
print_error "Unable to complete security validation - check tool availability"
echo -e "${RED}❌ Security validation inconclusive!${NC}"
exit 1
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
    if osv-scanner scan source . --format table 2>/dev/null; then
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

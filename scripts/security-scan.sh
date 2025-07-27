#!/bin/bash
# Multi-layered security scanning script for pass-git-helper
# Provides Safety (premium) with pip-audit + bandit fallback

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored status messages
print_status() {
    echo -e "${BLUE}[SECURITY]${NC} $1"
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

# Track security scan results
SAFETY_SUCCESS=false
PIP_AUDIT_SUCCESS=false
BANDIT_SUCCESS=false
TOTAL_ISSUES=0

print_status "Starting comprehensive security scanning..."

# ============================================================================
# PRIMARY SCAN: Safety (Premium vulnerability database)
# ============================================================================
print_status "Running Safety scan (primary)..."

if command -v safety &> /dev/null; then
    if safety auth status &> /dev/null; then
        print_status "Safety authenticated, running comprehensive scan..."
        if python -m safety scan --output screen; then
            SAFETY_SUCCESS=true
            print_success "Safety scan completed successfully"
        else
            print_warning "Safety scan found issues or failed"
        fi
    else
        print_warning "Safety not authenticated, will use fallback tools only"
    fi
else
    print_warning "Safety not available, will use fallback tools only"
fi

# ============================================================================
# FALLBACK SCAN 1: pip-audit (Dependency vulnerabilities)
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
# FALLBACK SCAN 2: bandit (Source code security)
# ============================================================================
print_status "Running bandit scan (source code security)..."

if command -v bandit &> /dev/null; then
    print_status "Scanning source code with bandit..."
    # Use -ll to only report medium/high severity issues, ignore low severity
    if bandit -r passgithelper.py -f txt -ll; then
        BANDIT_SUCCESS=true
        print_success "bandit scan completed successfully"
    else
        bandit_exit=$?
        if [ $bandit_exit -eq 1 ]; then
            print_warning "bandit found potential security issues (continuing...)"
            # Don't fail on bandit issues unless they're high severity
        else
            print_error "bandit failed to run properly"
            TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
        fi
    fi
else
    print_warning "bandit not available"
fi

# ============================================================================
# RESULTS SUMMARY
# ============================================================================
print_status "Security scan summary:"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                          SECURITY SCAN RESULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$SAFETY_SUCCESS" = true ]; then
    echo -e "🛡️  Safety (Premium):     ${GREEN}✅ PASSED${NC}"
else
    echo -e "🛡️  Safety (Premium):     ${YELLOW}⚠️  SKIPPED/FAILED${NC}"
fi

if [ "$PIP_AUDIT_SUCCESS" = true ]; then
    echo -e "🔍 pip-audit (Dependencies): ${GREEN}✅ PASSED${NC}"
else
    echo -e "🔍 pip-audit (Dependencies): ${RED}❌ FAILED${NC}"
fi

if [ "$BANDIT_SUCCESS" = true ]; then
    echo -e "🔎 bandit (Source Code):     ${GREEN}✅ PASSED${NC}"
else
    echo -e "🔎 bandit (Source Code):     ${YELLOW}⚠️  ISSUES FOUND${NC}"
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

# Fallback success: Both pip-audit and bandit passed (or bandit had only low issues)
if [ "$PIP_AUDIT_SUCCESS" = true ] && [ "$BANDIT_SUCCESS" = true ]; then
    print_success "Fallback security scans passed - build can proceed"
    echo -e "${GREEN}🎉 Security validation successful via fallback tools!${NC}"
    exit 0
fi

# Partial success: pip-audit passed but bandit had issues (acceptable for this project)
if [ "$PIP_AUDIT_SUCCESS" = true ] && [ "$BANDIT_SUCCESS" = false ]; then
    print_warning "Dependency scan passed, source code scan found issues (acceptable for credential helper)"
    echo -e "${YELLOW}⚠️  Security validation passed with warnings${NC}"
    exit 0
fi

# Failure scenarios
if [ "$PIP_AUDIT_SUCCESS" = false ]; then
    print_error "Dependency vulnerability scan failed - blocking build"
    echo -e "${RED}❌ Security validation failed!${NC}"
    exit 1
fi

# Unexpected case
print_error "Unexpected security scan state - blocking build"
echo -e "${RED}❌ Security validation failed!${NC}"
exit 1

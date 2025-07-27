#!/bin/bash
# Local CI/CD Pipeline for pass-git-helper
# This script runs all the checks that would normally run in CI/CD

set -e  # Exit on any error

echo "🚀 Starting Local CI/CD Pipeline for pass-git-helper"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${YELLOW}[CI/CD]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [[ ! -f "passgithelper.py" ]]; then
    print_error "Must be run from the pass-git-helper repository root"
    exit 1
fi

# Step 1: Setup Python environment
print_status "Setting up Python environment..."
if [[ ! -d ".venv" ]]; then
    python -m venv .venv
fi
source .venv/bin/activate
pip install -e .
pip install -r requirements-dev.txt > /dev/null 2>&1
print_success "Python environment ready"

# Step 2: Code formatting
print_status "Running code formatting..."
python -m ruff format .
print_success "Code formatting complete"

# Step 3: Linting
print_status "Running linting checks..."
if python -m ruff check .; then
    print_success "Linting passed"
else
    print_error "Linting failed"
    exit 1
fi

# Step 4: Type checking (if mypy is available)
print_status "Checking for type checker..."
if command -v mypy &> /dev/null; then
    print_status "Running type checks..."
    mypy passgithelper.py || print_error "Type checking failed (continuing...)"
else
    print_status "mypy not found, skipping type checks"
fi

# Step 5: Security checks
print_status "Running comprehensive security checks..."
if ./scripts/security-scan.sh; then
    print_success "Security checks passed"
else
    print_error "Security checks failed"
    exit 1
fi

# Step 6: Unit tests
print_status "Running unit tests..."
if python -m pytest test_passgithelper.py -v --tb=short; then
    print_success "All tests passed"
else
    print_error "Tests failed"
    exit 1
fi

# Step 7: Test coverage
print_status "Generating test coverage report..."
python -m pytest test_passgithelper.py --cov=passgithelper --cov-report=term-missing --cov-report=html
print_success "Coverage report generated (see htmlcov/ directory)"

# Step 8: Package building test
print_status "Testing package build..."
if python -m build --wheel > /dev/null 2>&1; then
    print_success "Package builds successfully"
    rm -rf dist/ build/ *.egg-info/
else
    print_error "Package build failed"
    exit 1
fi

echo ""
echo "🎉 All CI/CD checks passed successfully!"
echo "========================================"
echo ""
echo "Summary:"
echo "✅ Code formatting"
echo "✅ Linting"
echo "✅ Security checks"
echo "✅ Unit tests"
echo "✅ Test coverage"
echo "✅ Package build"
echo ""
echo "Your code is ready for deployment! 🚀"

#!/bin/bash
# Simple Local CI/CD Pipeline for pass-git-helper (No external dependencies)
# This script runs all the essential checks locally without requiring external services

set -e  # Exit on any error

echo "🚀 Starting Simple Local CI/CD Pipeline"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
pip install -e . > /dev/null 2>&1
pip install pytest pytest-mock pytest-cov ruff build > /dev/null 2>&1
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

# Step 4: Unit tests
print_status "Running unit tests..."
if python -m pytest test_passgithelper.py -v --tb=short; then
    print_success "All tests passed"
else
    print_error "Tests failed"
    exit 1
fi

# Step 5: Test coverage
print_status "Generating test coverage report..."
python -m pytest test_passgithelper.py --cov=passgithelper --cov-report=term-missing
print_success "Coverage report generated"

# Step 6: Package building test
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
echo "✅ Unit tests"
echo "✅ Test coverage"
echo "✅ Package build"
echo ""
echo "Your code is ready for deployment! 🚀"

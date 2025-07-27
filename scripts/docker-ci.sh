#!/bin/bash
# Docker-based CI/CD runner
# Provides complete isolation and reproducible builds

set -e

echo "🐳 Starting Docker-based CI/CD Pipeline"
echo "======================================="

# Build the CI image
echo "📦 Building CI Docker image..."
docker build -f Dockerfile.ci -t pass-git-helper-ci .

# Run linting
echo "🔍 Running linting in Docker..."
docker run --rm pass-git-helper-ci python -m ruff check .

# Run tests
echo "🧪 Running tests in Docker..."
docker run --rm pass-git-helper-ci python -m pytest test_passgithelper.py -v

# Run security checks
echo "🔒 Running security checks in Docker..."
docker run --rm pass-git-helper-ci python -m safety scan

echo ""
echo "🎉 Docker CI/CD completed successfully!"
echo "======================================"

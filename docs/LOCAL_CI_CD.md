# Local CI/CD Setup Guide

This repository now supports **100% free local CI/CD** to avoid GitHub Actions costs while maintaining high code quality.

## 🏠 Available CI/CD Options

### 1. **Simple Local CI** (Recommended for daily use)
Run essential checks quickly:
```bash
./scripts/simple-ci.sh
```

### 2. **Full Local CI** (Complete pipeline)
Includes all checks + security scanning:
```bash
./scripts/local-ci.sh
```

### 3. **Docker CI** (Isolated environment)
Runs in Docker for complete isolation:
```bash
./scripts/docker-ci.sh
```

### 4. **Pre-commit Hooks** (Automatic)
Automatically runs on each commit:
- Linting
- Quick tests

## 🛠 Setup Instructions

### One-time Setup
```bash
# Clone and enter repository
git clone https://github.com/kairin/pass-git-helper.git
cd pass-git-helper

# Install development dependencies
python -m venv .venv
source .venv/bin/activate
pip install -e .
pip install -r requirements-dev.txt

# Test the setup
./scripts/simple-ci.sh
```

### Setting Up Self-Hosted GitHub Runner (Optional)
If you want to keep using GitHub Actions but run them locally:

1. **Go to your repository on GitHub**
2. **Settings** → **Actions** → **Runners** → **New self-hosted runner**
3. **Follow GitHub's setup instructions**
4. **Runner will use the modified `.github/workflows/ci.yml`**

## 📋 What Each CI Option Checks

| Check | Simple CI | Full CI | Docker CI | Pre-commit |
|-------|-----------|---------|-----------|------------|
| Code Formatting | ✅ | ✅ | ✅ | ❌ |
| Linting | ✅ | ✅ | ✅ | ✅ |
| Unit Tests | ✅ | ✅ | ✅ | ✅ |
| Test Coverage | ✅ | ✅ | ✅ | ❌ |
| Security Scan | ❌ | ✅ | ✅ | ❌ |
| Package Build | ✅ | ✅ | ✅ | ❌ |
| Type Checking | ❌ | ✅ | ❌ | ❌ |

## 🔄 Development Workflow

1. **Make changes to code**
2. **Pre-commit hook runs automatically** (basic checks)
3. **Run local CI before pushing:**
   ```bash
   ./scripts/simple-ci.sh  # Quick check
   ```
4. **Push to GitHub** (self-hosted runner executes if configured)

## 💰 Cost Breakdown

- **GitHub Actions (cloud)**: ~$0.008 per minute
- **Self-hosted runners**: $0 (uses your hardware)
- **Local CI scripts**: $0 (runs on your machine)
- **Docker CI**: $0 (runs locally in containers)

## 🚀 Benefits of Local CI/CD

- ✅ **100% Free** - No GitHub Actions minutes consumed
- ✅ **Faster feedback** - No queue waiting times
- ✅ **Privacy** - Code never leaves your machine
- ✅ **Customizable** - Full control over the environment
- ✅ **Offline capable** - Works without internet
- ✅ **Consistent** - Same environment every time

## 🔧 Customization

Edit the scripts in `scripts/` to add your own checks or modify existing ones:

- `scripts/simple-ci.sh` - Basic quality checks
- `scripts/local-ci.sh` - Full pipeline with security
- `scripts/docker-ci.sh` - Containerized pipeline
- `.git/hooks/pre-commit` - Git pre-commit hook

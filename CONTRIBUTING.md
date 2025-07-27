# Contributing to pass-git-helper

## Development Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/kairin/pass-git-helper.git
   cd pass-git-helper
   ```

2. **Set up Python environment**:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   pip install -e .
   pip install -r requirements-dev.txt
   ```

3. **Run tests**:
   ```bash
   python -m pytest test_passgithelper.py -v
   ```

4. **Run linting**:
   ```bash
   python -m ruff check .
   python -m ruff format .
   ```

5. **Check security**:
   ```bash
   python -m safety scan
   ```

## Making Changes

1. Create a feature branch: `git checkout -b feature/your-feature-name`
2. Make your changes
3. Run tests and linting
4. Commit with conventional commit messages
5. Push and create a pull request

## Code Quality

- All code must pass the existing test suite
- New features should include tests
- Follow the existing code style
- Use type hints where appropriate

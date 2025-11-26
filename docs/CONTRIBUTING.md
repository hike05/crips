# Contributing to Crips

Thank you for your interest in contributing to Crips!

## Development Setup

1. Fork and clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/crips.git
cd crips
```

2. Create a feature branch:
```bash
git checkout -b feature/your-feature
```

3. Make your changes

4. Test locally:
```bash
cd deployment
./install.sh
```

5. Commit with clear messages:
```bash
git commit -m "Add: feature description"
```

6. Push and create a pull request:
```bash
git push origin feature/your-feature
```

## Testing

Before submitting, verify your changes:

### Basic Mode
```bash
cd deployment
docker compose down -v
rm -f .env

# Test basic installation
echo "proxy.test.local
admin@test.local
testuser
testpass123
n" | ./install.sh

# Verify services
COMPOSE_PROFILES=basic docker compose ps
docker exec crips-crowdsec cscli bouncers list
docker compose logs caddy | grep "started"
```

### REALITY Mode
```bash
cd deployment
docker compose down -v
rm -f .env

# Test REALITY installation
echo "proxy.test.local
admin@test.local
testuser
testpass123
y
reality.test.local
www.microsoft.com" | ./install.sh

# Verify services
COMPOSE_PROFILES=reality docker compose ps
docker compose logs singbox
```

## Code Style

- Use clear, descriptive variable names
- Add comments for complex logic
- Follow existing formatting conventions
- Keep shell scripts POSIX-compatible where possible
- Use 4 spaces for indentation in shell scripts
- Use 2 spaces for YAML and JSON files

## Pull Request Guidelines

Your PR should:
- Have a clear description of what it does
- Reference any related issues
- Include testing steps
- Update documentation if needed
- Pass all existing tests

### PR Title Format

- `Add: new feature description`
- `Fix: bug description`
- `Update: component/documentation description`
- `Refactor: code improvement description`

## Areas for Contribution

### Caddy Build
- Update plugin versions
- Add new useful plugins
- Optimize build process
- Improve CI/CD automation

### Deployment
- Improve install.sh user experience
- Add configuration validation
- Better error handling
- Support more platforms

### Documentation
- Improve clarity and examples
- Add troubleshooting guides
- Translate to other languages
- Create video tutorials

### Testing
- Add automated tests
- Improve test coverage
- Create test scenarios
- Performance benchmarks

## Reporting Issues

When reporting bugs, include:

- Operating system and version
- Docker and Docker Compose versions
- Mode (basic or REALITY)
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs: `docker compose logs`
- Configuration (sanitized, no secrets)

### Issue Template

```markdown
**Environment:**
- OS: 
- Docker version: 
- Docker Compose version: 
- Mode: basic / reality

**Description:**
Brief description of the issue

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Logs:**
```
Paste relevant logs here
```
```

## Security

**Do not open public issues for security vulnerabilities.**

Report security issues privately by:
1. Opening a security advisory on GitHub
2. Or emailing the maintainers directly

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Component Updates

### Caddy Build
When updating Caddy or plugins:
1. Update `caddy-build/Dockerfile`
2. Test build locally: `docker build -t crips:test caddy-build/`
3. Test both deployment modes
4. Update version in documentation
5. Update CHANGELOG.md

### Dependencies
When updating Docker images:
1. Update image tags in `docker-compose.yml`
2. Test compatibility
3. Document any breaking changes
4. Update migration guide if needed

### Documentation
When updating docs:
1. Keep language clear and concise
2. Include code examples
3. Update all relevant files
4. Check for broken links
5. Verify commands work as documented

## Release Process

Maintainers follow this process for releases:

1. Update CHANGELOG.md with version and date
2. Update version references in documentation
3. Build and test Caddy image
4. Create git tag: `git tag -a v1.0.0 -m "Release v1.0.0"`
5. Push tag: `git push origin v1.0.0`
6. GitHub Actions builds and publishes Docker image
7. Create GitHub release with changelog

## Questions?

- Check existing documentation
- Search closed issues
- Open a discussion on GitHub
- Review architecture documentation

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow project guidelines

## License

By contributing, you agree that your contributions will be licensed under the same terms as the project components.

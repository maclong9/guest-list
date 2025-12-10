# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them privately:

1. **Email**: hello@maclong.uk
2. **GitHub Security Advisories**: Use the [Security tab](../../security/advisories/new) to privately report vulnerabilities

### What to Include

Please include the following information:
- Type of vulnerability
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the vulnerability
- Any possible mitigations you've identified

### Response Timeline

- **Initial response**: Within 48 hours
- **Status update**: Within 7 days
- **Fix timeline**: Depends on severity
  - Critical: 1-3 days
  - High: 1-2 weeks
  - Medium: 2-4 weeks
  - Low: Best effort

## Security Best Practices

### For Contributors

1. **Never commit secrets**
   - No API keys, passwords, or tokens in code
   - Use `.env` files (never committed)
   - Check with `git diff` before committing

2. **Validate all inputs**
   - Sanitize user input
   - Use parameterized queries (prevent SQL injection)
   - Validate and escape HTML (prevent XSS)

3. **Use secure dependencies**
   - Keep dependencies up to date
   - Review security advisories
   - Run `swift package show-dependencies` regularly

4. **Follow secure coding practices**
   - Use strong typing (Swift 6 Sendable)
   - Avoid force unwrapping (`!`)
   - Handle errors properly
   - Use `async/await` for concurrency safety

### For Deployments

1. **Environment configuration**
   - Use strong secrets (min 32 characters)
   - Rotate JWT secrets regularly
   - Never use development secrets in production

2. **Network security**
   - Enable TLS/HTTPS
   - Configure CORS properly
   - Implement rate limiting

3. **Database security**
   - Use strong passwords
   - Limit database user permissions
   - Enable connection encryption
   - Regular backups

4. **Container security**
   - Use official base images
   - Keep images updated
   - Scan for vulnerabilities
   - Run as non-root user

## Vulnerability Disclosure Policy

We follow coordinated vulnerability disclosure:

1. Researcher reports vulnerability privately
2. We acknowledge receipt within 48 hours
3. We investigate and develop a fix
4. We release a patched version
5. We publish a security advisory
6. Researcher can publish findings 90 days after fix or with our approval

## Security Features

### Authentication
- JWT tokens with configurable expiration
- Refresh token rotation
- Password hashing (bcrypt/argon2)
- Rate limiting on auth endpoints

### Authorization
- Role-based access control (RBAC)
- Venue owners, staff, performers, guests
- Per-resource permissions

### Ticket Security
- HMAC-signed QR codes
- Replay attack prevention (Redis cache)
- Offline validation capability
- Time-limited validity

### API Security
- Rate limiting (Redis-based)
- Input validation
- SQL injection prevention (parameterized queries)
- XSS prevention (WebUI escaping)
- CSRF protection
- Request size limits

### Data Protection
- TLS in transit
- Encrypted connections to PostgreSQL/Redis
- Password hashing
- Secure session management
- Audit logging

## Security Checklist for PRs

Before submitting a PR, ensure:

- [ ] No secrets in code or commits
- [ ] Input validation for all user data
- [ ] SQL queries use parameterized statements
- [ ] HTML output is properly escaped
- [ ] Authentication/authorization checked where needed
- [ ] Error messages don't leak sensitive info
- [ ] Tests include security scenarios
- [ ] Dependencies are up to date
- [ ] Code follows swift-format rules
- [ ] `make lint` passes

## Known Security Considerations

### Development Environment
- Default `.env` file contains weak passwords (for dev only)
- Containers run with default passwords
- **Never use development configuration in production**

### Production Deployment
See deployment documentation for:
- TLS/SSL configuration
- Secret management
- Database hardening
- Network security
- Monitoring and alerting

## Security Tools

We use:
- **swift-format**: Code quality and consistency
- **TruffleHog**: Secret scanning (CI/CD)
- **GitHub Security Advisories**: Dependency vulnerability alerts
- **Swift Testing**: Security-focused test cases

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Swift Security Guide](https://www.swift.org/documentation/security/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [Hummingbird Security](https://docs.hummingbird.codes/2.0/documentation/hummingbird/security/)

## Contact

- **Security issues**: security@example.com
- **General questions**: Use GitHub Discussions
- **Bug reports**: Use GitHub Issues (non-security only)

---

**Last updated**: 2025-12-09

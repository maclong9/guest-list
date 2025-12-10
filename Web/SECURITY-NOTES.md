# Security Notes for Web Server

## Critical Security Checklist

### Before Production Deployment

- [ ] **Environment Variables**
  - [ ] Generate strong JWT_SECRET (min 32 random characters)
  - [ ] Generate strong database password
  - [ ] Generate strong Redis password
  - [ ] Set unique passwords for each environment
  - [ ] Never use development secrets in production

- [ ] **Database Security**
  - [ ] Enable SSL/TLS for PostgreSQL connections
  - [ ] Use restricted database user (not postgres superuser)
  - [ ] Disable unnecessary database extensions
  - [ ] Configure connection limits
  - [ ] Enable audit logging
  - [ ] Set up regular backups
  - [ ] Test backup restoration

- [ ] **Redis Security**
  - [ ] Enable password authentication (already done)
  - [ ] Disable dangerous commands (CONFIG, EVAL, etc.)
  - [ ] Enable TLS for connections
  - [ ] Configure maxmemory and eviction policy
  - [ ] Restrict network access

- [ ] **Application Security**
  - [ ] Enable rate limiting
  - [ ] Configure CORS properly
  - [ ] Set secure cookie attributes (HttpOnly, Secure, SameSite)
  - [ ] Implement CSRF protection
  - [ ] Add security headers (CSP, HSTS, X-Frame-Options, etc.)
  - [ ] Validate and sanitize all inputs
  - [ ] Use parameterized queries (prevent SQL injection)
  - [ ] Escape HTML output (prevent XSS)

- [ ] **Authentication & Authorization**
  - [ ] Implement JWT token rotation
  - [ ] Set appropriate token expiration times
  - [ ] Implement refresh token mechanism
  - [ ] Use bcrypt/argon2 for password hashing
  - [ ] Implement account lockout after failed attempts
  - [ ] Add 2FA support (future)

- [ ] **Network Security**
  - [ ] Configure TLS/SSL (Let's Encrypt or commercial cert)
  - [ ] Use TLS 1.3 (disable TLS 1.0, 1.1)
  - [ ] Configure strong cipher suites
  - [ ] Enable HSTS
  - [ ] Set up firewall rules
  - [ ] Use reverse proxy (nginx/Caddy) in production

- [ ] **Container Security**
  - [ ] Run containers as non-root user
  - [ ] Use minimal base images (Swift slim images)
  - [ ] Scan images for vulnerabilities (trivy, grype)
  - [ ] Keep images updated
  - [ ] Set resource limits (CPU, memory)
  - [ ] Use separate networks for services
  - [ ] Enable container security scanning
  - [ ] Consider apple/container for Swift-optimized images

- [ ] **Monitoring & Logging**
  - [ ] Set up centralized logging
  - [ ] Enable audit trails
  - [ ] Monitor for suspicious activity
  - [ ] Set up alerts for errors and security events
  - [ ] Implement log rotation
  - [ ] Sanitize logs (no sensitive data)

- [ ] **Dependency Security**
  - [ ] Audit all dependencies
  - [ ] Enable automated security updates
  - [ ] Subscribe to security advisories
  - [ ] Pin versions in production
  - [ ] Regular security scans

## Environment Variables Security

### Development (.env)
```sh
# Weak passwords are OK for local development
POSTGRES_PASSWORD=dev_password
REDIS_PASSWORD=dev_redis
JWT_SECRET=dev_jwt_secret_min_32_chars
```

### Production (.env.production)
```sh
# Generate strong random values:
POSTGRES_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 48)

# Or use a password manager
# Never commit this file to git
```

## Generating Secure Secrets

```sh
# Generate random password (32 bytes, base64)
openssl rand -base64 32

# Generate random hex (64 characters)
openssl rand -hex 32

# Using Swift
swift -e 'import Foundation; print([UInt8](repeating: 0, count: 32).map { _ in UInt8.random(in: 0...255) }.map { String(format: "%02x", $0) }.joined())'
```

## Security Headers

Add these headers to all responses:

```swift
// In middleware
response.headers.replaceOrAdd(name: "X-Content-Type-Options", value: "nosniff")
response.headers.replaceOrAdd(name: "X-Frame-Options", value: "DENY")
response.headers.replaceOrAdd(name: "X-XSS-Protection", value: "1; mode=block")
response.headers.replaceOrAdd(name: "Strict-Transport-Security", value: "max-age=31536000; includeSubDomains")
response.headers.replaceOrAdd(name: "Content-Security-Policy", value: "default-src 'self'")
response.headers.replaceOrAdd(name: "Referrer-Policy", value: "strict-origin-when-cross-origin")
response.headers.replaceOrAdd(name: "Permissions-Policy", value: "geolocation=(), microphone=(), camera=()")
```

## Rate Limiting Configuration

```swift
// Per-IP limits
"/api/v1/auth/login" -> 5 requests per 15 minutes
"/api/v1/auth/register" -> 3 requests per hour
"/api/v1/*" -> 100 requests per minute
"/chat/*" -> 1000 messages per hour
```

## CORS Configuration

```swift
// Only allow specific origins in production
let allowedOrigins = [
    "https://guestlist.example.com",
    "https://app.guestlist.example.com"
]

// Never use "*" in production
```

## Database Connection String

```sh
# Development (SSL not required)
DATABASE_URL=postgresql://user:pass@localhost:5432/db

# Production (require SSL)
DATABASE_URL=postgresql://user:pass@prod-db:5432/db?sslmode=require

# Production with certificate verification
DATABASE_URL=postgresql://user:pass@prod-db:5432/db?sslmode=verify-full&sslrootcert=/path/to/ca.pem
```

## Common Vulnerabilities to Avoid

1. **SQL Injection**
   - ✅ Use parameterized queries
   - ❌ Never concatenate user input into SQL

2. **XSS (Cross-Site Scripting)**
   - ✅ Escape all HTML output
   - ✅ Use Content-Security-Policy header
   - ❌ Never use `innerHTML` with user data

3. **CSRF (Cross-Site Request Forgery)**
   - ✅ Use CSRF tokens
   - ✅ Verify origin/referer headers
   - ✅ Use SameSite cookies

4. **Authentication Bypass**
   - ✅ Validate JWT signature and expiration
   - ✅ Use secure session management
   - ❌ Never trust client-side authentication

5. **Information Disclosure**
   - ✅ Use generic error messages
   - ✅ Sanitize logs
   - ❌ Never expose stack traces in production

## Security Testing

```sh
# Check for secrets in code
git secrets --scan

# Scan dependencies
swift package show-dependencies

# Run security tests
swift test --filter Security

# Static analysis (add SAST tool)
# swiftlint analyze

# Dynamic analysis (manual)
# - Test authentication bypasses
# - Test authorization checks
# - Test input validation
# - Test rate limiting
```

## Incident Response

If a security incident occurs:
1. Isolate affected systems
2. Preserve logs and evidence
3. Notify stakeholders
4. Investigate root cause
5. Implement fixes
6. Update security measures
7. Document lessons learned
8. Follow disclosure policy (SECURITY.md)

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Swift Security Best Practices](https://www.swift.org/documentation/security/)
- [Hummingbird Security Guide](https://docs.hummingbird.codes/2.0/documentation/hummingbird/security/)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/security.html)
- [Redis Security](https://redis.io/docs/management/security/)

---

**Review this file before each production deployment.**

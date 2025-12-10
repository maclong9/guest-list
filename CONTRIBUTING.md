# Contributing to GuestList

Thank you for your interest in contributing to GuestList! This document provides guidelines and instructions for contributing.

## Code of Conduct

This project follows the [Swift Community Code of Conduct](https://www.swift.org/code-of-conduct/). By participating, you agree to uphold this code.

## How Can I Contribute?

### Reporting Bugs

**Before submitting a bug report:**
- Check existing issues to avoid duplicates
- Update to the latest version to see if the issue persists
- Collect relevant information (OS, Swift version, steps to reproduce)

**Submitting a bug report:**
1. Use a clear, descriptive title
2. Describe the exact steps to reproduce
3. Provide specific examples
4. Describe the observed vs. expected behavior
5. Include screenshots if applicable
6. Note your environment (OS, Swift version, Xcode version)

### Suggesting Enhancements

**Before suggesting an enhancement:**
- Check if it's already been suggested
- Consider if it fits the project's scope
- Think about how it would benefit other users

**Submitting an enhancement suggestion:**
1. Use a clear, descriptive title
2. Provide a detailed description of the proposed functionality
3. Explain why this enhancement would be useful
4. List any alternative solutions you've considered
5. Include mockups or examples if applicable

### Pull Requests

**Before starting work:**
1. Check existing issues and PRs
2. For major changes, open an issue first to discuss
3. Fork the repository and create a branch from `main`
4. Name your branch descriptively (e.g., `feature/websocket-chat`, `fix/auth-token-expiry`)

**Making changes:**
1. Follow the coding standards (see below)
2. Write/update tests for your changes
3. Update documentation as needed
4. Ensure all tests pass (`make test`)
5. Run code formatting (`make format`)
6. Check that linting passes (`make lint`)

**Submitting a pull request:**
1. Write a clear PR title and description
2. Reference related issues (e.g., "Fixes #123")
3. Describe what changed and why
4. Include screenshots for UI changes
5. List any breaking changes
6. Ensure CI checks pass

## Development Setup

### Prerequisites
```sh
# Install required tools
brew install swift-format

# Clone the repository
git clone https://github.com/your-username/GuestList.git
cd GuestList

# Copy environment template
cd Web && cp .env.example .env && cd ..

# Generate Xcode projects


# Build container images
make containers-build

# Start containers
make containers-up

# Build everything
make build

# Run tests
make test
```

### Development Workflow
```sh
# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ... edit files ...

# Format code
make format

# Run tests
make test

# Commit your changes
git add .
git commit -m "Add your feature"

# Push to your fork
git push origin feature/your-feature-name

# Open a pull request on GitHub
```

## Coding Standards

### Swift Style
- Follow `.swift-format` configuration (based on apple/container)
- Use Swift 6 strict concurrency
- Prefer value types over reference types
- Use `async/await` for asynchronous code
- Make types `Sendable` where appropriate
- Avoid force unwrapping (`!`) and force try (`try!`)
- Use meaningful variable and function names

### Code Organization
```swift
// MARK: - Type Definition
struct MyType: Codable, Sendable {
    // MARK: Properties
    let id: UUID
    let name: String

    // MARK: Initialization
    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }

    // MARK: Methods
    func doSomething() {
        // Implementation
    }
}

// MARK: - Extensions
extension MyType {
    static func mock() -> Self {
        Self(id: UUID(), name: "Test")
    }
}
```

### Commit Messages
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

**Examples:**
```
feat(api): add WebSocket chat endpoint

Implement real-time chat using WebSockets.
Messages are persisted to PostgreSQL and
broadcast to connected clients.

Closes #42
```

```
fix(auth): validate JWT expiration correctly

Previously, expired tokens were being accepted
due to incorrect date comparison.

Fixes #123
```

## Testing

### Writing Tests
- Use Swift Testing framework (not XCTest)
- Test one thing per test
- Use descriptive test names
- Follow Arrange-Act-Assert pattern
- Mock external dependencies
- Test edge cases and error conditions

### Test Structure
```swift
import Testing
@testable import GuestListShared

@Suite("Event Tests")
struct EventTests {
    @Test("Creates event with valid data")
    func testEventCreation() {
        // Arrange
        let id = UUID()
        let name = "Concert"

        // Act
        let event = Event(
            id: id,
            venueID: UUID(),
            name: name,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            status: .upcoming
        )

        // Assert
        #expect(event.id == id)
        #expect(event.name == name)
    }
}
```

### Running Tests
```sh
# All tests
make test

# Specific package
cd Shared && swift test
cd Web && swift test

# Platform tests
make test-xcode

# With coverage
swift test --enable-code-coverage
```

## Documentation

### Code Documentation
- Document public APIs with doc comments
- Use triple-slash (`///`) comments
- Include parameter descriptions
- Provide usage examples

```swift
/// Fetches events for a specific venue.
///
/// - Parameters:
///   - venueID: The unique identifier of the venue
///   - status: Optional filter for event status
/// - Returns: An array of events matching the criteria
/// - Throws: `APIError` if the request fails
func fetchEvents(
    for venueID: UUID,
    status: EventStatus? = nil
) async throws -> [Event] {
    // Implementation
}
```

### README Updates
- Update README.md for user-facing changes
- Update CLAUDE.md for development changes
- Update Web/README.md for server changes

## Project Structure

```
GuestList/
├── Shared/           # Cross-platform Swift package
├── Web/              # Hummingbird server (backend + frontend)
├── iOS/              # iOS/iPadOS app
├── macOS/            # macOS app
├── visionOS/         # visionOS app
├── watchOS/          # watchOS app (iOS companion)
├── .github/          # CI/CD workflows
├── Makefile          # Common tasks
└── .swift-format     # Formatting rules
```

### Adding Files
- **Shared**: New models, services, or utilities
- **Web**: API controllers, services, or WebUI pages
- **Platform apps**: Screens, components, or resources

New Swift files are automatically detected by Xcode.

## Dependencies

### Adding Dependencies

**For Web/Shared packages:**
Edit `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/example/package.git", from: "1.0.0")
],
targets: [
    .target(
        name: "Web",
        dependencies: [
            .product(name: "PackageName", package: "package")
        ]
    )
]
```

**For platform apps:**
Add packages via Xcode:
1. Open `GuestList.xcworkspace`
2. File > Add Package Dependencies
3. Enter package URL
4. Select version/branch
5. Choose targets to add to

### Updating Dependencies
```sh
# Check for updates
cd Web && swift package show-dependencies

# Update all
cd Web && swift package update

# Test after updating
make test
```

## Release Process

1. Update version numbers
2. Update CHANGELOG.md
3. Create release branch
4. Run full test suite
5. Tag release: `git tag v1.0.0`
6. Push tag: `git push origin v1.0.0`
7. GitHub Actions creates release automatically
8. Publish release notes

## Getting Help

- **Questions**: Use GitHub Discussions
- **Bugs**: Open an issue
- **Security**: See SECURITY.md
- **Chat**: Join our community (TBD)

## Recognition

Contributors are recognized in:
- CONTRIBUTORS.md (coming soon)
- Release notes
- Git commit history

Thank you for contributing to GuestList! 🎉

---

**Last updated**: 2025-12-09

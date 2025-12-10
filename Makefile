# ──────────────────────────
# GuestList Makefile
# ──────────────────────────

PROJECT_NAME ?= GuestList

# ──────────────────────────
# Paths
# ──────────────────────────
SHARED_DIR := Shared
WEB_DIR := Web
APPS_DIR := Apps

# Source paths for formatting
SWIFT_SOURCES := \
	$(SHARED_DIR)/Sources \
	$(SHARED_DIR)/Tests \
	$(WEB_DIR)/Sources \
	$(WEB_DIR)/Tests \
	$(APPS_DIR)/iOS \
	$(APPS_DIR)/macOS \
	$(APPS_DIR)/Watch \
	$(APPS_DIR)/Vision

# Container images
POSTGRES_IMAGE := guestlist-postgres
REDIS_IMAGE := guestlist-redis
WEB_IMAGE := guestlist-web

# Container names
POSTGRES_CONTAINER := guestlist-postgres
REDIS_CONTAINER := guestlist-redis

# ──────────────────────────
# Phony targets
# ──────────────────────────
.PHONY: help format lint build test clean \
	containers-build containers-up containers-down containers-logs containers-clean \
	run-web

# ──────────────────────────
# Help
# ──────────────────────────
help:
	@echo "$(PROJECT_NAME) - Full-Stack Swift Project"
	@echo ""
	@echo "Development:"
	@echo "  format             - Format all Swift code"
	@echo "  lint               - Check Swift formatting"
	@echo "  build              - Build all packages and projects"
	@echo "  test               - Run all tests"
	@echo "  clean              - Clean build artifacts"
	@echo ""
	@echo "Containers:"
	@echo "  containers-build   - Build container images"
	@echo "  containers-up      - Start PostgreSQL + Redis"
	@echo "  containers-down    - Stop containers"
	@echo "  containers-logs    - View container logs"
	@echo "  containers-clean   - Remove containers and volumes"
	@echo ""
	@echo "Platform:"
	@echo "  run-web            - Start web server"

# ──────────────────────────
# Development commands
# ──────────────────────────
format:
	@echo "Formatting Swift code..."
	@swift format --in-place --recursive --parallel $(SWIFT_SOURCES)
	@echo "✅ Formatting complete"

lint:
	@echo "Linting Swift code..."
	@swift format lint --recursive --parallel $(SWIFT_SOURCES)
	@echo "✅ Linting complete"

# ──────────────────────────
# Build commands
# ──────────────────────────
build: build-shared build-web build-xcode
	@echo "✅ All builds complete"

build-shared:
	@echo "Building Shared package..."
	@cd $(SHARED_DIR) && swift build

build-web:
	@echo "Building Web server..."
	@cd $(WEB_DIR) && swift build

build-xcode:
	@echo "Building Xcode projects..."
	@echo "Building macOS..."
	@xcodebuild -workspace $(PROJECT_NAME).xcworkspace \
		-scheme $(PROJECT_NAME)-Mac \
		-destination 'platform=macOS' \
		-quiet build
	@echo "Note: iOS build skipped (iOS SDK not installed)"

# ──────────────────────────
# Test commands
# ──────────────────────────
test: test-shared test-web
	@echo "✅ All tests complete"
	@echo "Note: Xcode tests skipped (no test files yet)"

test-shared:
	@echo "Testing Shared package..."
	@cd $(SHARED_DIR) && swift test

test-web:
	@echo "Testing Web server..."
	@cd $(WEB_DIR) && swift test

test-xcode:
	@echo "Testing macOS..."
	@xcodebuild test -workspace $(PROJECT_NAME).xcworkspace \
		-scheme $(PROJECT_NAME)-Mac \
		-destination 'platform=macOS' \
		-quiet
	@echo "Note: iOS tests skipped (iOS SDK not installed)"

# ──────────────────────────
# Container commands
# ──────────────────────────
containers-build:
	@echo "Building container images..."
	@cd $(WEB_DIR) && container build -t $(POSTGRES_IMAGE) -f Containers/postgres.Containerfile Containers/
	@cd $(WEB_DIR) && container build -t $(REDIS_IMAGE) -f Containers/redis.Containerfile Containers/
	@cd $(WEB_DIR) && container build -t $(WEB_IMAGE) -f Containerfile .
	@echo "✅ Container images built"

containers-up:
	@echo "Starting PostgreSQL + Redis containers..."
	@if [ ! -f $(WEB_DIR)/.env ]; then \
		echo "❌ Error: $(WEB_DIR)/.env not found. Copy from .env.example"; \
		exit 1; \
	fi
	@. $(WEB_DIR)/.env && \
		container run -d --name $(POSTGRES_CONTAINER) \
			-p $${POSTGRES_PORT:-5432}:5432 \
			-e POSTGRES_USER=$${POSTGRES_USER} \
			-e POSTGRES_PASSWORD=$${POSTGRES_PASSWORD} \
			-e POSTGRES_DB=$${POSTGRES_DB} \
			-v guestlist-postgres-data:/var/lib/postgresql/data \
			$(POSTGRES_IMAGE) 2>/dev/null || echo "PostgreSQL already running"
	@. $(WEB_DIR)/.env && \
		container run -d --name $(REDIS_CONTAINER) \
			-p $${REDIS_PORT:-6379}:6379 \
			-e REDIS_PASSWORD=$${REDIS_PASSWORD} \
			-v guestlist-redis-data:/data \
			$(REDIS_IMAGE) 2>/dev/null || echo "Redis already running"
	@echo "✅ Containers started"
	@echo "   PostgreSQL: localhost:5432"
	@echo "   Redis: localhost:6379"

containers-down:
	@echo "Stopping containers..."
	@container stop $(POSTGRES_CONTAINER) $(REDIS_CONTAINER) 2>/dev/null || true
	@container rm $(POSTGRES_CONTAINER) $(REDIS_CONTAINER) 2>/dev/null || true
	@echo "✅ Containers stopped"

containers-logs:
	@echo "─── PostgreSQL logs ───"
	@container logs $(POSTGRES_CONTAINER) --tail 50 2>/dev/null || echo "PostgreSQL not running"
	@echo ""
	@echo "─── Redis logs ───"
	@container logs $(REDIS_CONTAINER) --tail 50 2>/dev/null || echo "Redis not running"

containers-clean:
	@echo "Removing containers and volumes..."
	@container stop $(POSTGRES_CONTAINER) $(REDIS_CONTAINER) 2>/dev/null || true
	@container rm $(POSTGRES_CONTAINER) $(REDIS_CONTAINER) 2>/dev/null || true
	@container volume rm guestlist-postgres-data guestlist-redis-data 2>/dev/null || true
	@echo "✅ Containers and volumes removed"

# ──────────────────────────
# Platform commands
# ──────────────────────────
run-web:
	@echo "Starting web server on http://localhost:8080..."
	@cd $(WEB_DIR) && swift run Web

# ──────────────────────────
# Cleanup
# ──────────────────────────
clean:
	@echo "Cleaning build artifacts..."
	@cd $(SHARED_DIR) && swift package clean 2>/dev/null || true
	@cd $(WEB_DIR) && swift package clean 2>/dev/null || true
	@rm -rf $(APPS_DIR)/$(PROJECT_NAME).xcodeproj/xcuserdata
	@rm -rf .build $(SHARED_DIR)/.build $(WEB_DIR)/.build
	@echo "✅ Clean complete"

<<<<<<< HEAD
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
||||||| (empty tree)
=======
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

# Docker Compose
COMPOSE_FILE := compose.yml
COMPOSE_ENV := $(WEB_DIR)/.env

# ──────────────────────────
# Phony targets
# ──────────────────────────
.PHONY: help format lint build test clean \
	services-up services-down services-logs services-clean services-restart services-up-full \
	dev run-web

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
	@echo "Services (Docker Compose):"
	@echo "  services-up        - Start PostgreSQL + Redis only"
	@echo "  services-up-dev    - Start all + Web container with hot reload (recommended)"
	@echo "  services-up-full   - Start all + Web container (production test)"
	@echo "  services-down      - Stop services"
	@echo "  services-logs      - View service logs"
	@echo "  services-restart   - Restart services"
	@echo "  services-clean     - Remove services and volumes"
	@echo ""
	@echo "Development (native Swift, faster iteration):"
	@echo "  dev                - Hot reload with native Swift binary"
	@echo "  run-web            - Start web server natively (no hot reload)"

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
# Docker Compose commands
# ──────────────────────────
services-up:
	@echo "Starting PostgreSQL + Redis services..."
	@if [ ! -f $(COMPOSE_ENV) ]; then \
		echo "❌ Error: $(COMPOSE_ENV) not found. Copy from Web/.env.example"; \
		exit 1; \
	fi
	@docker compose --env-file $(COMPOSE_ENV) up -d
	@echo "✅ Services started"
	@echo "   PostgreSQL: localhost:5432"
	@echo "   Redis: localhost:6379"

services-up-dev:
	@echo "Starting PostgreSQL + Redis + Web (development mode with hot reload)..."
	@if [ ! -f $(COMPOSE_ENV) ]; then \
		echo "❌ Error: $(COMPOSE_ENV) not found. Copy from Web/.env.example"; \
		exit 1; \
	fi
	@docker compose --env-file $(COMPOSE_ENV) --profile dev up -d --build
	@echo "✅ Development stack started"
	@echo "   PostgreSQL: localhost:5432"
	@echo "   Redis: localhost:6379"
	@echo "   Web (containerized): http://localhost:8080"
	@echo "   📝 Hot reload enabled - edit files in Web/Sources to trigger rebuild"
	@echo ""
	@echo "View logs: docker compose logs -f web-dev"

services-down:
	@echo "Stopping services..."
	@docker compose down
	@echo "✅ Services stopped"

services-logs:
	@docker compose logs -f

services-restart:
	@echo "Restarting services..."
	@docker compose restart
	@echo "✅ Services restarted"

services-clean:
	@echo "Removing services and volumes..."
	@docker compose down -v
	@echo "✅ Services and volumes removed"

services-up-full:
	@echo "Starting PostgreSQL + Redis + Web server..."
	@if [ ! -f $(COMPOSE_ENV) ]; then \
		echo "❌ Error: $(COMPOSE_ENV) not found. Copy from Web/.env.example"; \
		exit 1; \
	fi
	@docker compose --env-file $(COMPOSE_ENV) --profile full up -d --build
	@echo "✅ Full stack started"
	@echo "   PostgreSQL: localhost:5432"
	@echo "   Redis: localhost:6379"
	@echo "   Web: http://localhost:8080"

# ──────────────────────────
# Development commands
# ──────────────────────────
dev:
	@echo "Starting development mode with hot reload..."
	@if ! command -v watchexec >/dev/null 2>&1; then \
		echo "❌ Error: watchexec not found. Install with: brew install watchexec"; \
		exit 1; \
	fi
	@if [ ! -f $(COMPOSE_ENV) ]; then \
		echo "❌ Error: $(COMPOSE_ENV) not found. Copy from Web/.env.example"; \
		exit 1; \
	fi
	@echo "📦 Ensuring services are running..."
	@$(MAKE) services-up >/dev/null 2>&1 || true
	@echo "🔄 Watching for changes in $(WEB_DIR)/Sources..."
	@echo "🚀 Server will auto-restart on file changes"
	@echo ""
	@cd $(WEB_DIR) && set -a && . .env && set +a && watchexec -w Sources -e swift -r -- swift run Web

run-web:
	@echo "Starting web server on http://localhost:8080..."
	@if [ ! -f $(COMPOSE_ENV) ]; then \
		echo "❌ Error: $(COMPOSE_ENV) not found. Copy from Web/.env.example"; \
		exit 1; \
	fi
	@cd $(WEB_DIR) && set -a && . .env && set +a && swift run Web

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
>>>>>>> b75037e (Project initialized 🚀)

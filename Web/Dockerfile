# ──────────────────────────────────────────────────────────
# GuestList Web - Production Dockerfile
# Multi-stage build for Hummingbird application
# ──────────────────────────────────────────────────────────

# ══════════════════════════════════════════════════════════
# Build Stage
# ══════════════════════════════════════════════════════════
FROM swift:6.0-noble as build

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libjemalloc-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy package manifests first for better layer caching
COPY ./Package.* ./
RUN swift package resolve --skip-update

# Copy source code
COPY . .

# Build with optimizations
RUN swift build -c release \
    --static-swift-stdlib \
    -Xlinker -ljemalloc

# ══════════════════════════════════════════════════════════
# Staging: Prepare runtime artifacts
# ══════════════════════════════════════════════════════════
WORKDIR /staging

# Copy compiled binary
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/Web" ./

# Copy Swift backtrace tool for crash reporting
RUN cp "/usr/libexec/swift/linux/swift-backtrace-static" ./

# Copy SPM resources if any
RUN find -L "$(swift build --package-path /build -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \;

# Copy public directory if exists (for static assets)
RUN [ -d /build/public ] && { mv /build/public ./public && chmod -R a-w ./public; } || true

# ══════════════════════════════════════════════════════════
# Runtime Stage
# ══════════════════════════════════════════════════════════
FROM ubuntu:noble

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
    libjemalloc2 \
    ca-certificates \
    tzdata \
    && rm -r /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app hummingbird

WORKDIR /app

# Copy artifacts from staging
COPY --from=build --chown=hummingbird:hummingbird /staging /app

# Enable Swift backtrace for better crash reporting
ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no,swift-backtrace=./swift-backtrace-static

# Switch to non-root user
USER hummingbird:hummingbird

# Expose HTTP port
EXPOSE 8080

# Run server
ENTRYPOINT ["./Web"]
CMD ["--hostname", "0.0.0.0", "--port", "8080"]

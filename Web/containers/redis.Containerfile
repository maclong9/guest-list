# Redis Container for GuestList
# Build with: container build -t guestlist-redis -f Containers/redis.Containerfile Containers/
# Run with: container run -p 6379:6379 --env-file .env guestlist-redis

FROM redis:7-alpine

# Copy redis configuration and set permissions
COPY redis.conf /usr/local/etc/redis/redis.conf
RUN chown redis:redis /usr/local/etc/redis/redis.conf && \
    chmod 644 /usr/local/etc/redis/redis.conf

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=5 \
    CMD redis-cli ping || exit 1

# Expose Redis port
EXPOSE 6379

# Run Redis with config
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]

# PostgreSQL Container for GuestList
# Build with: container build -t guestlist-postgres -f Containers/postgres.Containerfile Containers/
# Run with: container run -p 5432:5432 --env-file .env guestlist-postgres

FROM postgres:16-alpine

# Environment variables (override with --env-file)
ENV POSTGRES_USER=guestlist
ENV POSTGRES_PASSWORD=change_me
ENV POSTGRES_DB=guestlist
ENV PGDATA=/var/lib/postgresql/data/pgdata

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=5 \
    CMD pg_isready -U ${POSTGRES_USER} || exit 1

# Expose PostgreSQL port
EXPOSE 5432

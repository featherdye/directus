FROM directus/directus:11-alpine

# Set working directory
WORKDIR /directus

# Copy extensions if any
COPY extensions /directus/extensions

# Copy schema files for reference (optional)
COPY schemas /directus/schemas
COPY templates /directus/templates
COPY migrations /directus/migrations

# Expose Directus port
EXPOSE 8055

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8055/server/health || exit 1

# Start Directus
CMD ["node", "cli.js", "bootstrap"]

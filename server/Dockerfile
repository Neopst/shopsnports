FROM node:18-alpine AS builder
# Install build deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --production

# Copy app source
COPY . .

# Final runtime image
FROM node:18-alpine
WORKDIR /app
# Create non-root user for better security
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /app /app
RUN chown -R app:app /app
USER app

ENV NODE_ENV=production
EXPOSE 3000

# Healthcheck expects /health to return 200
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 CMD wget -q --spider http://localhost:3000/health || exit 1

CMD ["node", "index.js"]

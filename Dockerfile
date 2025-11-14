# Multi-stage build for production deployment

# Stage 1: Build the site
FROM squidfunk/mkdocs-material:9.7.0 AS builder

WORKDIR /docs

# Copy requirements and install plugins
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source files
COPY . .

# Build the static site
RUN mkdocs build

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy built site from builder stage
COPY --from=builder /docs/site /usr/share/nginx/html

# Copy custom nginx config if needed
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

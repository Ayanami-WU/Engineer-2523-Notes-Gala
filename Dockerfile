# Multi-stage build for production deployment

# Stage 1: Build the site
FROM squidfunk/mkdocs-material:9.7.0 AS builder

WORKDIR /docs

# Copy requirements and install plugins
COPY requirements.txt .

# Upgrade pip and install dependencies
# This layer will be cached unless requirements.txt changes
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Show installed MkDocs packages for debugging
RUN echo "=== Installed MkDocs packages ===" && \
    pip list | grep -i mkdocs && \
    echo "==================================="

# Copy source files
COPY . .

# Build the static site
# If any plugin is missing, mkdocs build will report it
RUN mkdocs build --verbose

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy built site from builder stage
COPY --from=builder /docs/site /usr/share/nginx/html

# Copy custom nginx config to enable directory listing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

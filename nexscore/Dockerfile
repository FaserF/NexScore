# Stage 1: Build Flutter Web application
FROM ubuntu:24.04 AS build-env

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git wget unzip xz-utils libglu1-mesa ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Use a clean path for Flutter
RUN git clone https://github.com/flutter/flutter.git /opt/flutter \
    --branch stable \
    --depth 1

# Setup environment variables
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

# Pre-warm the Flutter tool cache
RUN flutter precache --web --no-android --no-ios

WORKDIR /app
COPY . .

# Build for Web with WASM
ARG IS_BETA=false
RUN flutter clean
RUN flutter pub get
RUN if [ "$IS_BETA" = "true" ]; then \
      flutter build web --wasm --release --base-href="/" --dart-define=IS_BETA=true; \
    else \
      flutter build web --wasm --release --base-href="/"; \
    fi

# Stage 2: Serve with Nginx (Alpine) - Optimized Runtime
FROM nginx:1.27-alpine3.20-slim

# Copy the Flutter web build output
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration for correct MIME types and SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

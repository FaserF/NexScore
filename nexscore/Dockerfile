# Stage 1: Build Flutter Web application (Optional if pre-built)
FROM ubuntu:24.04@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c AS build-env

# Setup environment variables
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

WORKDIR /app
COPY . .

# Argument to pass pre-built assets path (e.g., build/web)
ARG PREBUILT_PATH=""
ARG IS_BETA=false

RUN if [ -n "$PREBUILT_PATH" ] && [ -d "$PREBUILT_PATH" ]; then \
      echo "Using pre-built assets from $PREBUILT_PATH"; \
      mkdir -p build/web && cp -R $PREBUILT_PATH/* build/web/; \
    else \
      echo "Building from source..."; \
      apt-get update && apt-get install -y --no-install-recommends curl git wget unzip xz-utils libglu1-mesa ca-certificates && rm -rf /var/lib/apt/lists/*; \
      git clone https://github.com/flutter/flutter.git /opt/flutter --branch stable --depth 1; \
      flutter precache --web --no-android --no-ios; \
      flutter pub get; \
      if [ "$IS_BETA" = "true" ]; then \
        flutter build web --wasm --release --base-href="/" --dart-define=IS_BETA=true; \
      else \
        flutter build web --wasm --release --base-href="/"; \
      fi; \
    fi

# Stage 2: Serve with Nginx (Alpine) - Optimized Runtime
FROM nginx:1.27-alpine3.20-slim@sha256:5a56ae385906c5b43ccc99379bce883aa93dc0556d7f705ba501d819925e8fa1

# Copy the Flutter web build output
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration for correct MIME types and SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

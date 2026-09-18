# Stage 1: Build the Flutter web app
FROM ubuntu:22.04 AS build

# Install dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter -b stable
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

WORKDIR /app
COPY . .

# Build the app
RUN flutter pub get
RUN flutter build web

# Stage 2: Serve the app securely using a distroless image (Zero CVEs)
FROM cgr.dev/chainguard/nginx:latest
COPY --from=build /app/build/web /usr/share/nginx/html

# Default port for non-root Chainguard Nginx is 8080
EXPOSE 8080

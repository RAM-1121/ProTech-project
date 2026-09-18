# Stage 1: Build the Flutter web app
FROM ubuntu:22.04 AS build

# Install dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Create a non-root user to avoid tar ownership errors on Render
RUN useradd -m flutteruser
USER flutteruser
WORKDIR /home/flutteruser/app

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /home/flutteruser/flutter -b stable
ENV PATH="/home/flutteruser/flutter/bin:/home/flutteruser/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Precache flutter for web only
RUN flutter config --enable-web
RUN flutter precache --web

COPY --chown=flutteruser:flutteruser . .

# Build the app
RUN flutter pub get
RUN flutter build web

# Stage 2: Serve the app securely using a distroless image (Zero CVEs)
FROM cgr.dev/chainguard/nginx:latest
COPY --from=build /app/build/web /usr/share/nginx/html

# Default port for non-root Chainguard Nginx is 8080
EXPOSE 8080

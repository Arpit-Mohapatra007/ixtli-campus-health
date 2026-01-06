# Stage 1: Build the Flutter Web App
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy files
COPY . .

# Install dependencies and build
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy the build output to Nginx html folder
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration (for GoRouter support)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
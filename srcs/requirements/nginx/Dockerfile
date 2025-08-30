FROM debian:bullseye

# Install NGINX
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/default.conf /etc/nginx/sites-available/default
COPY tools/docker-entrypoint.sh /usr/local/bin/

# Make script executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create SSL directory
RUN mkdir -p /etc/nginx/ssl

# Remove default site link
RUN rm -f /etc/nginx/sites-enabled/default

# Expose port
EXPOSE 443

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
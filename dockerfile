FROM alpine:latest

# Install required tools
RUN apk add --no-cache curl jq tzdata grep bash

# Set the timezone
RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

# Create necessary directories
RUN mkdir /app /app/state

# Copy the entrypoint script and hookie script into the container
COPY entrypoint.sh /app/entrypoint.sh
COPY hookie.sh /app/hookie.sh

# Make sure the scripts are executable
RUN chmod +x /app/entrypoint.sh && \
    chmod +x /app/hookie.sh && \
    chmod -R +r /app/state

# Set the working directory
WORKDIR /app

# Set the entrypoint to the entrypoint.sh script
ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]

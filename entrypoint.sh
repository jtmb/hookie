#!/bin/bash

# Ensure that PUID and PGID are set, default to 1000 if not provided
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

# Avoid GID 0 since it's reserved for root (in case PGID is set to 0 in the environment variable)
if [ "$PGID" -eq 0 ]; then
  echo "PGID cannot be 0. Setting PGID to 1000 [DONE]"
  PGID=1000
fi

# Avoid UID 0 since it's reserved for the root user (in case PUID is set to 0 in the environment variable)
if [ "$PUID" -eq 0 ]; then
  echo "PUID cannot be 0. Setting PUID to 1000 [DONE]"
  PUID=1000
fi

# Create the app group and user if they don't exist
if ! getent group appgroup > /dev/null; then
    echo "Creating group appgroup with GID $PGID [DONE]"
    addgroup -g "$PGID" appgroup
fi

if ! getent passwd appuser > /dev/null; then
    echo "Creating user appuser with UID $PUID [DONE]"
    adduser -u "$PUID" -G appgroup -S appuser
fi

# Change ownership of the app directory
echo "Changing ownership of /app and /app/state to appuser:appgroup [DONE]"
chown -R appuser:appgroup /app /app/state

# Switch to the non-root user and run the command
echo "Switching to user appuser and running /app/hookie.sh [DONE]"
su -s /bin/bash appuser -c "/bin/bash /app/hookie.sh $@"

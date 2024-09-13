#!/usr/bin/env sh

set -e

# Check if user is root
if [ "$(id -u)" = '0' ]; then
    # Create group and user based on environment variables
    if [ ! "$(getent group "$PGID")" ]; then
        # If groupadd exists, use it
        if command -v groupadd > /dev/null; then
            groupadd -g "$PGID" jellyplex_group
        elif command -v addgroup > /dev/null; then
            addgroup -g "$PGID" jellyplex_group
        fi
    fi

    if [ ! "$(getent passwd "$PUID")" ]; then
        # If useradd exists, use it
        if command -v useradd > /dev/null; then
            useradd --no-create-home -u "$PUID" -g "$PGID" jellyplex_user
        elif command -v adduser > /dev/null; then
            adduser -D -H -u "$PUID" -G jellyplex_group jellyplex_user
        fi
    fi
else 
    # If user is not root, set the PUID and PGID to the current user
    PUID=$(id -u)
    PGID=$(id -g)
fi

# Get directory of log and mark file to create base folder if it doesnt exist
LOG_DIR=$(dirname "$LOG_FILE")
# If LOG_DIR is set, create the directory
if [ -n "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

MARK_DIR=$(dirname "$MARK_FILE")
if [ -n "$MARK_DIR" ]; then
    mkdir -p "$MARK_DIR"  
fi

# If root run as the created user
if [ "$(id -u)" = '0' ]; then
    chown -R "$PUID:$PGID" "$LOG_DIR"
    chown -R "$PUID:$PGID" "$MARK_DIR"

    # Run the application as the created user
    exec gosu "$PUID:$PGID" "$@"
fi

# Run the application as the current user
exec "$@"

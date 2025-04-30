#!/bin/bash
set -e

# redis-autoconfig.sh
# Recalculates maxmemory and restarts Redis with updated config

CONF_FILE="/etc/redis/redis.conf"
PASS_FILE="/etc/redis/.redis-pass"
BOOT_ENV="/etc/redis/boot-env"
DATA_DIR="/var/lib/redis"

# Load password from boot-env if set
if [ -f "$BOOT_ENV" ]; then
  source "$BOOT_ENV"
fi

# Generate or reuse password
if [ -z "$REDIS_PASSWORD" ] && [ -f "$PASS_FILE" ]; then
  REDIS_PASSWORD=$(cat "$PASS_FILE")
elif [ -z "$REDIS_PASSWORD" ]; then
  REDIS_PASSWORD=$(openssl rand -base64 32)
  echo "$REDIS_PASSWORD" > "$PASS_FILE"
  chmod 600 "$PASS_FILE"
else
  echo "$REDIS_PASSWORD" > "$PASS_FILE"
  chmod 600 "$PASS_FILE"
fi

# Calculate memory allocation (70% of total RAM)
TOTAL_MB=$(free -m | awk '/^Mem:/{print $2}')
MAX_MB=$(( TOTAL_MB * 70 / 100 ))
PRIVATE_IP=$(hostname -I | awk '{print $1}')

# Generate redis.conf
cat <<EOF > "$CONF_FILE"
bind 0.0.0.0
protected-mode yes
port 6379
requirepass $REDIS_PASSWORD
dir $DATA_DIR
maxmemory ${MAX_MB}mb
maxmemory-policy allkeys-lru
appendonly no
daemonize no
supervised systemd
EOF

# Restart Redis
systemctl restart redis

exit 0


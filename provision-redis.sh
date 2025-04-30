#!/bin/bash
set -e

# Redis Provisioning Script
# Installs Redis 7.2.4, sets up secure config, systemd services, and dynamic memory tuning.

REDIS_VERSION="7.2.4"
REDIS_USER="ec2-user"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/redis"
DATA_DIR="/var/lib/redis"
PASS_FILE="$CONFIG_DIR/.redis-pass"
BOOT_ENV="$CONFIG_DIR/boot-env"

# === Check if Redis is already installed with correct version ===
if command -v redis-server &>/dev/null; then
  INSTALLED_VERSION=$(redis-server --version | grep -oE 'v=[0-9]+\.[0-9]+\.[0-9]+' | cut -d= -f2)
  if [ "$INSTALLED_VERSION" = "$REDIS_VERSION" ]; then
    echo "[✓] Redis $REDIS_VERSION is already installed. Skipping installation."
    SKIP_REDIS_INSTALL=true
  else
    echo "[!] Redis $INSTALLED_VERSION is installed, but we need $REDIS_VERSION. Will reinstall."
  fi
fi

# === Create redis user/data/config dirs ===
echo "[+] Creating Redis directories..."
sudo mkdir -p $DATA_DIR $CONFIG_DIR
sudo chown $REDIS_USER:$REDIS_USER $DATA_DIR
sudo chmod 700 $DATA_DIR

if [ "$SKIP_REDIS_INSTALL" != "true" ]; then
  # === Install dependencies ===
  echo "[+] Installing dependencies..."
  if command -v yum &>/dev/null; then
    sudo dnf swap curl-minimal curl --allowerasing -y || true
    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y jemalloc-devel tcl curl tar wget openssl-devel
  elif command -v apt &>/dev/null; then
    sudo apt update
    sudo apt install -y build-essential libjemalloc-dev tcl curl tar wget libssl-dev
  else
    echo "[!] Unsupported OS. Exiting."
    exit 1
  fi

  # === Download and build Redis ===
  echo "[+] Downloading Redis $REDIS_VERSION..."
  curl -sO http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz
  tar xzf redis-$REDIS_VERSION.tar.gz
  cd redis-$REDIS_VERSION
  make distclean || true
  make BUILD_TLS=yes
  sudo make install
  cd ..
fi

# === Install redis-autoconfig ===
echo "[+] Installing redis-autoconfig service and script..."
sudo cp redis-autoconfig.sh /usr/local/bin/redis-autoconfig.sh
sudo chmod +x /usr/local/bin/redis-autoconfig.sh
sudo cp systemd/redis-autoconfig.service /etc/systemd/system/redis-autoconfig.service

# === Install redis-show-pass ===
echo "[+] Installing redis-show-pass helper..."
sudo cp redis-show-pass /usr/local/bin/redis-show-pass
sudo chmod +x /usr/local/bin/redis-show-pass

# === Install redis-connection-info ===
echo "[+] Installing redis-connection-info helper..."
sudo cp redis-connection-info /usr/local/bin/redis-connection-info
sudo chmod +x /usr/local/bin/redis-connection-info

# === Install redis.service ===
echo "[+] Installing redis systemd service..."
sudo cp systemd/redis.service /etc/systemd/system/redis.service

# === Configure firewall for Redis remote access if firewall is enabled ===
echo "[+] Configuring firewall for Redis remote access..."
if command -v firewall-cmd &>/dev/null && sudo firewall-cmd --state &>/dev/null; then
  # For systems using firewalld (RHEL, CentOS, Fedora)
  sudo firewall-cmd --permanent --add-port=6379/tcp
  sudo firewall-cmd --reload
  echo "[✓] Firewalld configured to allow Redis traffic on port 6379."
elif command -v ufw &>/dev/null && sudo ufw status | grep -q "active"; then
  # For systems using ufw (Ubuntu, Debian)
  sudo ufw allow 6379/tcp
  echo "[✓] UFW configured to allow Redis traffic on port 6379."
else
  echo "[!] No supported firewall detected or firewall is not active."
fi

# === Run redis-autoconfig to set up remote access ===
echo "[+] Running redis-autoconfig to set up remote access..."
sudo /usr/local/bin/redis-autoconfig.sh

# === Enable and start services ===
sudo systemctl daemon-reexec
sudo systemctl enable redis redis-autoconfig
sudo systemctl restart redis

# === Finish ===
echo "[✓] Redis $REDIS_VERSION installed and configured."
echo "[🔐] Password stored in: $PASS_FILE"
echo "[⚙️] Memory auto-tuning enabled at boot."
echo "[🌐] Redis configured for remote access on port 6379."
echo "[📋] To view your Redis password: redis-show-pass"
echo "[🔌] To view connection information: redis-connection-info"


#!/bin/bash
set -e

SERVER_USER="Avorion"
INSTALL_DIR="/opt/avorion"
STEAMCMD_DIR="/opt/steamcmd"

GALAXY_NAME="avorion_galaxy"
SERVER_NAME="This is my Avorion Server"
PORT="27000"
QUERY_PORT="27003"

ADMIN_STEAM64="PUT_YOUR_STEAM64_ID_HERE"
SERVER_SEED="3288934782934"

PUBLIC="true"
LISTED="false"

# chatgpt, make it so if user doesnt update the ADMIN steam ID, let him know
if [ "$ADMIN_STEAM64" = "PUT_YOUR_STEAM64_ID_HERE" ] || [ -z "$ADMIN_STEAM64" ]; then
  echo "ERROR: Edit ADMIN_STEAM64 first."
  echo "Example: ADMIN_STEAM64=\"76561198445266160\""
  exit 1
fi

echo "=== Installing required packages ==="
dpkg --add-architecture i386 || true

apt update
apt install -y \
  ca-certificates \
  curl \
  wget \
  tar \
  gzip \
  sudo \
  ufw \
  lib32gcc-s1 \
  libc6-i386 \
  libstdc++6:i386 \
  libcurl4:i386

update-ca-certificates

echo "=== Creating Avorion user ==="
id -u "$SERVER_USER" >/dev/null 2>&1 || useradd -m -s /bin/bash "$SERVER_USER"

echo "=== Cleaning and installing SteamCMD ==="
rm -rf "$STEAMCMD_DIR"
mkdir -p "$STEAMCMD_DIR"
cd "$STEAMCMD_DIR"

curl -L \
  --fail \
  --retry 10 \
  --retry-delay 5 \
  --retry-connrefused \
  --connect-timeout 20 \
  -o steamcmd_linux.tar.gz \
  https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz

tar -xzf steamcmd_linux.tar.gz

echo "=== Testing SteamCMD ==="
"$STEAMCMD_DIR/steamcmd.sh" +quit

echo "=== Installing Avorion Dedicated Server ==="
mkdir -p "$INSTALL_DIR"
chown -R "$SERVER_USER:$SERVER_USER" "$INSTALL_DIR"

sudo -u "$SERVER_USER" "$STEAMCMD_DIR/steamcmd.sh" \
  +force_install_dir "$INSTALL_DIR" \
  +login anonymous \
  +app_update 565060 validate \
  +quit

echo "=== Creating start script ==="
cat > "$INSTALL_DIR/start.sh" <<EOL
#!/bin/bash
cd "$INSTALL_DIR"

./server.sh \\
  --galaxy-name "$GALAXY_NAME" \\
  --server-name "$SERVER_NAME" \\
  --port "$PORT" \\
  --query-port "$QUERY_PORT" \\
  --admin "$ADMIN_STEAM64" \\
  --seed "$SERVER_SEED" \\
  --public "$PUBLIC" \\
  --listed "$LISTED"
EOL

chmod +x "$INSTALL_DIR/start.sh"
chown "$SERVER_USER:$SERVER_USER" "$INSTALL_DIR/start.sh"

echo "=== Creating systemd service ==="
cat > /etc/systemd/system/avorion.service <<EOL
[Unit]
Description=Avorion Dedicated Server
After=network.target

[Service]
Type=simple
User=$SERVER_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/start.sh
Restart=always
RestartSec=10
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable avorion

echo "=== Opening firewall ports ==="
ufw allow ${PORT}/tcp || true
ufw allow ${PORT}/udp || true
ufw allow ${QUERY_PORT}/udp || true

echo "=== Starting Avorion ==="
systemctl restart avorion

echo "Made by Thunderlol"
echo "Github: https://github.com/the-real-thunderlol/Avorion-Server-Setup-Script"

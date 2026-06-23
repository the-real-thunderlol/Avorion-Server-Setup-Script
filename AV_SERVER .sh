USER64=""
GALAXY="mygalaxy"
SEED="mygalaxy"
RCON_PASS="insert_name"
MAX_PLAYERS="10"
PORT="27000"
QUERY_PORT="27003"
RCON_PORT="27015"

apt update && apt upgrade -y

dpkg --add-architecture i386
apt-get update
apt-get install -y software-properties-common
add-apt-repository multiverse -y
apt-get update
apt-get install -y lib32gcc-s1 libgl1:i386 steamcmd

useradd -m -s /bin/bash steam

su - steam -c "/usr/games/steamcmd +force_install_dir /home/steam/avorion +login anonymous +app_update 565060 validate +quit"

mkdir -p /home/steam/.avorion/galaxies/$GALAXY
chown -R steam:steam /home/steam/.avorion

echo "[General]" > /home/steam/.avorion/galaxies/$GALAXY/server.ini
echo "port=$PORT" >> /home/steam/.avorion/galaxies/$GALAXY/server.ini
echo "queryport=$QUERY_PORT" >> /home/steam/.avorion/galaxies/$GALAXY/server.ini
echo "rconport=$RCON_PORT" >> /home/steam/.avorion/galaxies/$GALAXY/server.ini
echo "rconpassword=$RCON_PASS" >> /home/steam/.avorion/galaxies/$GALAXY/server.ini
echo "maxPlayers=$MAX_PLAYERS" >> /home/steam/.avorion/galaxies/$GALAXY/server.ini
echo "seed=$SEED" >> /home/steam/.avorion/galaxies/$GALAXY/server.ini
echo "admin=$USER64" >> /home/steam/.avorion/galaxies/$GALAXY/server.ini

chown -R steam:steam /home/steam/.avorion

echo '#!/bin/bash' > /home/steam/start.sh
echo "cd /home/steam/avorion" >> /home/steam/start.sh
echo "./bin/AvorionServer --galaxy-name $GALAXY --port $PORT --query-port $QUERY_PORT --rcon-port $RCON_PORT --rcon-password $RCON_PASS --datapath /home/steam/.avorion" >> /home/steam/start.sh

chmod +x /home/steam/start.sh
chown steam:steam /home/steam/start.sh

systemctl restart avorion

echo "[Unit]" > /etc/systemd/system/avorion.service
echo "Description=Avorion Dedicated Server" >> /etc/systemd/system/avorion.service
echo "After=network.target" >> /etc/systemd/system/avorion.service
echo "" >> /etc/systemd/system/avorion.service
echo "[Service]" >> /etc/systemd/system/avorion.service
echo "User=steam" >> /etc/systemd/system/avorion.service
echo "ExecStart=/home/steam/start.sh" >> /etc/systemd/system/avorion.service
echo "Restart=on-failure" >> /etc/systemd/system/avorion.service
echo "RestartSec=10" >> /etc/systemd/system/avorion.service
echo "" >> /etc/systemd/system/avorion.service
echo "[Install]" >> /etc/systemd/system/avorion.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/avorion.service

systemctl daemon-reload
systemctl enable avorion
systemctl start avorion

#!/bin/bash

# Nexus install script for Ubuntu (tested on Ubuntu 20.04+)

set -e

NEXUS_VERSION="3.59.1-01"
NEXUS_USER="nexus"
NEXUS_INSTALL_DIR="/opt/nexus"
NEXUS_WORK_DIR="/opt/sonatype-work"
DOWNLOAD_URL="https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz"

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "Updating packages and installing OpenJDK 11..."
apt-get update
apt-get install -y openjdk-11-jdk wget

echo "Creating nexus user (if not exists)..."
if id "$NEXUS_USER" &>/dev/null; then
  echo "User $NEXUS_USER already exists."
else
  useradd -r -m -U -d $NEXUS_INSTALL_DIR -s /bin/bash $NEXUS_USER
  echo "User $NEXUS_USER created."
fi

echo "Downloading Nexus Repository OSS version $NEXUS_VERSION..."
wget -qO /tmp/nexus.tar.gz $DOWNLOAD_URL

echo "Removing old Nexus installation (if any)..."
rm -rf $NEXUS_INSTALL_DIR $NEXUS_WORK_DIR

echo "Extracting Nexus..."
tar -xzf /tmp/nexus.tar.gz -C /opt
mv /opt/nexus-${NEXUS_VERSION} $NEXUS_INSTALL_DIR

echo "Setting permissions..."
chown -R $NEXUS_USER:$NEXUS_USER $NEXUS_INSTALL_DIR $NEXUS_WORK_DIR

echo 'run_as_user="nexus"' > $NEXUS_INSTALL_DIR/bin/nexus.rc

echo "Creating systemd service file for Nexus..."

cat > /etc/systemd/system/nexus.service << EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=$NEXUS_USER
Group=$NEXUS_USER
ExecStart=$NEXUS_INSTALL_DIR/bin/nexus start
ExecStop=$NEXUS_INSTALL_DIR/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd daemon and enabling Nexus service..."
systemctl daemon-reload
systemctl enable nexus

echo "Starting Nexus service..."
systemctl start nexus

echo "Nexus installation completed!"
echo "Access Nexus UI at http://<your-server-ip>:8081"

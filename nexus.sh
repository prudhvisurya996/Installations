#!/bin/bash

set -e

echo "Updating package lists..."
sudo apt-get update

echo "Installing OpenJDK 11..."
sudo apt-get install -y openjdk-11-jdk

echo "Creating nexus user..."
if id -u nexus >/dev/null 2>&1; then
    echo "User nexus already exists"
else
    sudo useradd -r -m -d /opt/nexus -s /bin/bash nexus
fi

echo "Fetching latest Nexus version..."
LATEST_VERSION=$(curl -s https://download.sonatype.com/nexus/3/ | \
grep -oP 'nexus-\K[0-9]+\.[0-9]+\.[0-9]+-[0-9]+' | sort -V | tail -1)

if [[ -z "$LATEST_VERSION" ]]; then
    echo "Failed to fetch latest Nexus version. Exiting."
    exit 1
fi

echo "Latest Nexus version detected: $LATEST_VERSION"

DOWNLOAD_URL="https://download.sonatype.com/nexus/3/nexus-${LATEST_VERSION}-unix.tar.gz"
echo "Downloading Nexus from $DOWNLOAD_URL..."

wget -q --show-progress $DOWNLOAD_URL -O /tmp/nexus.tar.gz

echo "Extracting Nexus..."
sudo tar -xzf /tmp/nexus.tar.gz -C /opt

echo "Setting up Nexus directory and permissions..."
sudo mv /opt/nexus-${LATEST_VERSION} /opt/nexus
sudo chown -R nexus:nexus /opt/nexus

echo "Setting permissions for Sonatype Work directory..."
sudo mkdir -p /opt/sonatype-work
sudo chown -R nexus:nexus /opt/sonatype-work

echo "Creating systemd service file for Nexus..."

sudo tee /etc/systemd/system/nexus.service > /dev/null <<EOF
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling Nexus service to start on boot..."
sudo systemctl enable nexus

echo "Starting Nexus service..."
sudo systemctl start nexus

echo "Checking Nexus service status..."
sudo systemctl status nexus --no-pager

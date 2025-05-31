#!/bin/bash

# Exit on any error
set -e

# Variables
NEXUS_VERSION=3.68.0-01
NEXUS_USER=nexus
INSTALL_DIR=/opt
NEXUS_DIR=${INSTALL_DIR}/nexus
DATA_DIR=${INSTALL_DIR}/sonatype-work

# Update and install Java 8
echo "Installing OpenJDK 8..."
sudo apt update
sudo apt install -y openjdk-8-jdk wget

# Create nexus user
echo "Creating nexus user..."
sudo useradd -M -d $NEXUS_DIR -s /bin/false $NEXUS_USER

# Download and extract Nexus
echo "Downloading Nexus..."
cd $INSTALL_DIR
sudo wget https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz
sudo tar -xzf nexus-${NEXUS_VERSION}-unix.tar.gz
sudo mv nexus-${NEXUS_VERSION} nexus
sudo rm nexus-${NEXUS_VERSION}-unix.tar.gz

# Set ownership
echo "Setting permissions..."
sudo chown -R $NEXUS_USER:$NEXUS_USER $NEXUS_DIR
sudo chown -R $NEXUS_USER:$NEXUS_USER $DATA_DIR

# Set Nexus to run as nexus user
echo "Configuring run-as-user..."
echo "run_as_user=${NEXUS_USER}" | sudo tee ${NEXUS_DIR}/bin/nexus.rc

# Set Java path in environment
echo "Setting Java environment..."
echo 'INSTALL4J_JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' | sudo tee -a ${NEXUS_DIR}/bin/nexus.vmoptions

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/nexus.service > /dev/null <<EOF
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=${NEXUS_DIR}/bin/nexus start
ExecStop=${NEXUS_DIR}/bin/nexus stop
User=${NEXUS_USER}
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start Nexus
echo "Enabling and starting Nexus service..."
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

# Show status
echo "Nexus status:"
sudo systemctl status nexus

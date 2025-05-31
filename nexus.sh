#!/bin/bash

# Exit on any error
set -e

NEXUS_VERSION=3.66.0-01
NEXUS_USER=nexus
NEXUS_HOME=/opt/nexus
NEXUS_DATA=/opt/sonatype-work
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

echo "Checking if Nexus user exists..."
if id -u $NEXUS_USER >/dev/null 2>&1; then
    echo "User $NEXUS_USER already exists."
else
    echo "Creating Nexus user..."
    sudo useradd -r -m -d $NEXUS_HOME -s /bin/bash $NEXUS_USER
fi

echo "Installing OpenJDK 11..."
sudo apt-get update
sudo apt-get install -y openjdk-11-jdk

echo "Downloading Nexus ${NEXUS_VERSION}..."
cd /opt
sudo wget https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz

echo "Extracting Nexus..."
sudo tar -xvzf nexus-${NEXUS_VERSION}-unix.tar.gz
sudo rm nexus-${NEXUS_VERSION}-unix.tar.gz

echo "Renaming extracted directory to nexus..."
sudo mv nexus-${NEXUS_VERSION} nexus

echo "Setting ownership to $NEXUS_USER..."
sudo chown -R $NEXUS_USER:$NEXUS_USER $NEXUS_HOME
sudo chown -R $NEXUS_USER:$NEXUS_USER $NEXUS_DATA || sudo mkdir -p $NEXUS_DATA && sudo chown -R $NEXUS_USER:$NEXUS_USER $NEXUS_DATA

echo "Configuring Nexus to run as $NEXUS_USER..."
sudo sed -i "s#run_as_user=\"\"#run_as_user=\"$NEXUS_USER\"#" $NEXUS_HOME/bin/nexus

echo "Creating systemd service file for Nexus..."
sudo tee /etc/systemd/system/nexus.service > /dev/null <<EOF
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=$NEXUS_USER
Group=$NEXUS_USER
Environment=INSTALL4J_JAVA_HOME=$JAVA_HOME
ExecStart=$NEXUS_HOME/bin/nexus start
ExecStop=$NEXUS_HOME/bin/nexus stop
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

echo "Nexus installation and startup completed."
echo "You can access Nexus at http://<your-server-ip>:8081 after it finishes starting."

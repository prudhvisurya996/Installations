#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Updating package index..."
sudo apt update

echo "Installing Python3 and pip3..."
sudo apt install -y python3 python3-pip

echo "Installing software-properties-common (for add-apt-repository)..."
sudo apt install -y software-properties-common

echo "Adding Ansible PPA repository..."
sudo add-apt-repository --yes --update ppa:ansible/ansible

echo "Installing Ansible..."
sudo apt install -y ansible

echo "Verifying installations..."
echo -n "Python3 version: "; python3 --version
echo -n "Pip3 version: "; pip3 --version
echo -n "Ansible version: "; ansible --version | head -n 1

echo "Installation complete!"

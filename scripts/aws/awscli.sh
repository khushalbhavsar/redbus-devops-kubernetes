#!/bin/bash
# Script to install AWS CLI on Amazon Linux

# Update system packages
sudo yum update -y

# Install unzip package if not already installed
sudo yum install unzip curl -y

# Download the AWS CLI installer
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip the AWS CLI installer
unzip awscliv2.zip

# Run the AWS CLI installation script
sudo ./aws/install

# Clean up installation files
rm -rf awscliv2.zip aws/

# Verify installation
aws --version
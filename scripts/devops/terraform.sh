#!/bin/bash
# Script to install Terraform on Amazon Linux

# Update system packages
sudo yum update -y

# Install yum-utils for yum-config-manager
sudo yum install -y yum-utils

# Add HashiCorp repository
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

# Install Terraform
sudo yum install terraform -y

# Verify installation
terraform -v
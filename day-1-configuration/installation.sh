#!/bin/bash
sudo yum update -y

#---------------git install ---------------

sudo yum install git -y


sudo dnf update -y

# Install Java 21
sudo dnf install java-21-amazon-corretto-devel -y

# Verify Java
java -version

# Add Jenkins repo
sudo wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/redhat-stable/jenkins.repo

# Import key
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
sudo dnf install jenkins -y

# Enable + start
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Check status
sudo systemctl status jenkins


# ------------------install terraform ------------------

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
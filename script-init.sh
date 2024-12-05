#!/bin/bash
sudo yum update -y && sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
sudo docker run -p 8080:80 --name nginx-server nginx
sudo docker start nginx-server
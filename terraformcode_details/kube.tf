provider "aws" {
  region = "ap-south-1"
}
# Network setup
# Create a VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "TerraformVPC"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "my-ig" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "TerraformIG"
  }
}

# Customer Route table
resource "aws_route_table" "my-rt" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-ig.id
  }
  tags = {
    Name = "TerraformRT"
  }
}

# Subnet
resource "aws_subnet" "my-sn" {
  vpc_id                  = aws_vpc.my-vpc.id
  map_public_ip_on_launch = true
  cidr_block              = "10.0.0.0/24"
  tags = {
    Name = "TerraformSN"
  }
}

#Association with Subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my-sn.id
  route_table_id = aws_route_table.my-rt.id
}

# Security Group
resource "aws_security_group" "my-sg" {
  vpc_id = aws_vpc.my-vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh_http"
  }
}

# Network Interface
resource "aws_network_interface" "my-ni" {
  subnet_id       = aws_subnet.my-sn.id
  security_groups = [aws_security_group.my-sg.id]
  tags = {
    Name = "my-NI"
  }
}

# Elastic IP
data "aws_eip" "eip-ni" {
  id = "eipalloc-055af21d18e460de8"
}
resource "aws_eip_association" "eip-association" {
  allocation_id        = data.aws_eip.eip-ni.id
  network_interface_id = aws_network_interface.my-ni.id
  #instance = aws_instance.demo.id
}

# Ec2 Instance
resource "aws_instance" "demo" {
  ami           = "ami-02eb7a4783e7e9317"
  instance_type = "t2.medium"
  key_name      = "mumbaikey"
    root_block_device {
      volume_size = 20
      volume_type = "gp2"
   }
  tags = {
    Name = "TerraformDemoInstance"
  }
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.my-ni.id
  }
  provisioner "remote-exec" {
   inline = [
    "sudo apt-get update -y",
    "sudo apt-get install docker.io -y",
    "sudo systemctl start docker",
    "sudo wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
    "sudo chmod +x /home/ubuntu/minikube-linux-amd64",
    "sudo cp minikube-linux-amd64 /usr/local/bin/minikube",
    "curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl",
    "sudo chmod +x /home/ubuntu/kubectl",
    "sudo cp kubectl /usr/local/bin/kubectl",
    "sudo groupadd docker",
    "sudo usermod -aG docker ubuntu",
   ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("./mumbaikey.pem")
    }
  }
}

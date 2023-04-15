provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "kube-server" {
 ami = "ami-02eb7a4783e7e9317"
 instance_type          = "t2.large"
 vpc_security_group_ids = ["sg-0e2c22e36dc10d118"]
 # subnet_id              = "subnet-05a31b67b18113593" 
 key_name               = "mumbaikey"
   root_block_device {
      volume_size = 20
      volume_type = "gp2"
   }

  tags = {
    Name = "kube-server"
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

# Define Elastic IP resource
resource "aws_eip" "eip" {
  vpc = true
}

# Associate Elastic IP with EC2 instance
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.kube-server.id
  allocation_id = aws_eip.eip.id

  depends_on = [aws_instance.kube-server]
}

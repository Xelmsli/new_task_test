provider "aws" {
  region = "eu-central-1"
}

resource "aws_security_group" "devops_sg" {
  name        = "devops-sg"
  description = "Allow HTTP, SSH, Grafana, Prometheus, Node Exporter"

  # SSH
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }



  ingress {
    description      = "Prometheus"
    from_port        = 9090
    to_port          = 9090
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  ingress {
    description      = "Grafana"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  ingress {
    description      = "Node Exporter"
    from_port        = 9100
    to_port          = 9100
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-sg"
  }
}

resource "aws_instance" "devops_server" {
  ami           = "ami-1234567890abcdef0"
  instance_type = "t2.micro"
  key_name      = "anton_x"

  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io docker-compose
              systemctl enable docker
              systemctl start docker

              EOF

  tags = {
    Name = "devops-server"
  }
}


output "ec2_public_ip" {
  value = aws_instance.devops_server.public_ip
}

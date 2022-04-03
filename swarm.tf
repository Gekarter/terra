provider "aws" {
  region = "${var.region}"
}

resource "aws_instance" "manager" {
    ami = "ami-0069d66985b09d219"
    instance_type = "t2.micro"
    security_groups = ["${aws_security_group.swarm_sg.name}"]
    key_name = "key-pair"

    connection {
        user = "ec2-user"
        private_key = "${file("./key-pair.pem")}"
        host = self.public_ip
	}
  
    tags = {
        Name = "Swarm Manager"
    }

    provisioner "local-exec" {
        # Keep in a local file the swarm manager IP address
        command = "echo Manager IP: ${self.public_ip} > manager_ip.txt"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo yum update -y",
            "sudo yum install -y docker",
	    "sudo usermod -a -G docker ec2-user",
	    "sudo service docker status",
	    "sudo service docker restart",
	    "sudo systemctl enable docker",
	    "sudo dockerd",
	    "sudo service docker status",
	    "sudo chmod 666 /var/run/docker.sock",
	    "sudo service docker status",
            "docker swarm init --advertise-addr ${self.private_ip}",
            "docker swarm join-token worker --quiet > /home/ec2-user/worker-token.txt"
        ]
    }
}

resource "aws_instance" "worker" {
    count = 2
    ami = "ami-0069d66985b09d219"
    instance_type = "t2.micro"
    security_groups = ["${aws_security_group.swarm_sg.name}"]
    key_name = "key-pair"

    connection {
        user = "ec2-user"
	host = self.public_ip
        private_key = "${file("./key-pair.pem")}"
    }
  
    tags = {
        Name = "Swarm Worker ${count.index} "
    }
    
    provisioner "file" {
        source = "key-pair.pem"
        destination = "/home/ec2-user/key.pem"
  }

    provisioner "remote-exec" {
        inline = [
	    "sudo yum update -y",
            "sudo yum install -y docker",
            "sudo usermod -a -G docker ec2-user",
            "sudo service docker status",
            "sudo service docker restart",
            "sudo systemctl enable docker",
            "sudo dockerd",
            "sudo service docker status",
            "sudo chmod 666 /var/run/docker.sock",
            "sudo chmod 400 /home/ec2-user/key.pem",
            "sudo service docker status",
            "sudo scp -o StrictHostKeyChecking=no -o NoHostAuthenticationForLocalhost=yes -o UserKnownHostsFile=/dev/null -i key.pem ec2-user@${aws_instance.manager.private_ip}:/home/ec2-user/worker-token.txt .",
            "docker swarm join --token $(cat /home/ec2-user/worker-token.txt) ${aws_instance.manager.private_ip}:2377",
            "sudo service docker status"
        ]
    }

    depends_on = ["aws_instance.manager"]
}


resource "aws_instance" "mysql" {
    ami = "ami-0069d66985b09d219"
    instance_type = "t2.micro"
    user_data = <<-EOF
			#!/bin/bash
			yum install -y mysql56-server
		EOF

	tags = {        
	name = "MYSQL"
        }

}

resource "aws_s3_bucket" "BucketForMysql" {
	bucket = "nysqldb"
        tags = {
            name = "mysql"
            Environment ="Dev"
      }
}


variable "key_name" {
  default = "jenkins_ec2"
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.key.public_key_openssh
}

resource "aws_instance" "myec2" {
  ami                  = "ami-0669b163befffbdfc"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  security_groups      = [aws_security_group.dynamicSG.name]
  key_name             = aws_key_pair.generated_key.key_name

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.key.private_key_pem
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      //install jenkins
      "sudo sudo yum update –y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum upgrade",
      "sudo dnf install java-17-amazon-corretto -y",
      "sudo yum install jenkins -y",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",
      "sudo systemctl status jenkins --no-pager",
      //install git
      "sudo dnf install git-all -y",
      "sudo dd if=/dev/zero of=/swapfile bs=128M count=32",
      "sudo chmod 600 /swapfile",
      "sudo mkswap /swapfile",
      "sudo swapon /swapfile",
      "sudo chmod 777 /etc/fstab",
      "udo echo '/swapfile swap swap defaults 0 0' >> /etc/fstab",
      //install mvn
      "wget https://dlcdn.apache.org/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz -P /tmp",
      "sudo tar xf /tmp/apache-maven-*.tar.gz -C /opt",
      "sudo ln -s /opt/apache-maven-3.9.5 /opt/maven"
    ]
  }

  tags = {
    Name = "JenkinsEC2"
  }

}

resource "aws_secretsmanager_secret" "jenkins_ssh" {
  name = "jenkins_ssh"
}

resource "aws_secretsmanager_secret_version" "jenkins_ssh_public" {
  secret_id     = aws_secretsmanager_secret.jenkins_ssh.id
  secret_string = <<EOF
   {
    "key1": "${tls_private_key.key.public_key_pem}",
    "key2": "${tls_private_key.key.private_key_pem}"
   }
EOF
}

output "private_key" {
  value     = tls_private_key.key.private_key_pem
  sensitive = true
}

output "key_arn" {
  value     = aws_secretsmanager_secret.jenkins_ssh.arn
}

/*# Importing the AWS secrets created previously using arn.

data "aws_secretsmanager_secret" "secretmasterDB" {
  arn = aws_secretsmanager_secret.secretmasterDB.arn
}

# Importing the AWS secret version created previously using arn.

data "aws_secretsmanager_secret_version" "creds" {
  secret_id = data.aws_secretsmanager_secret.secretmasterDB.arn
}

# After importing the secrets storing into Locals

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)
}*/

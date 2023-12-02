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
      "pwd",
      "sudo sudo yum update –y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum upgrade",
      "sudo dnf install java-17-amazon-corretto -y",
      "pwd",
      "echo fails-----------------",
      "sudo yum install jenkins -y",
      "pwd",
      "echo fails-----------------",
      "sudo systemctl enable jenkins",
      "pwd",
      "sudo systemctl start jenkins",
      "sudo systemctl status jenkins --no-pager",
      "sudo dnf install git-all"
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

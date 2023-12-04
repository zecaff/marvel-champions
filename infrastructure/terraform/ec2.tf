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
      "sudo sudo yum update",
      "sudo yum upgrade",
      //install jdk
      "sudo dnf install java-17-amazon-corretto -y",
      //install docker
      "sudo yum search docker",
      "sudo yum install docker -y",
      "sudo usermod -a -G docker ec2-user",
      "sudo systemctl enable docker.service",
      "sudo systemctl start docker.service",
      //install mvn 
      "wget https://dlcdn.apache.org/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz -P /tmp",
      "sudo tar xf /tmp/apache-maven-*.tar.gz -C /opt",
      "sudo ln -s /opt/apache-maven-3.9.5 /opt/maven",
      //set maven for services
      "echo 'DefaultEnvironment=\"M2_HOME=/opt/maven\"'| sudo tee --append /etc/systemd/system.conf",
      "echo 'DefaultEnvironment=\"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/maven/bin\"'| sudo tee --append /etc/systemd/system.conf",
      "sudo systemctl daemon-reexec",
      //set maven on global environment
      "echo 'M2_HOME=\"/opt/maven\"'| sudo tee --append /etc/environment",
      "echo 'PATH=\"/opt/maven/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games\"'| sudo tee --append /etc/environment",
      //install git
      "sudo dnf install git-all -y",
      //create permanent swap file to add more virtual memory to t2.micro
      "sudo dd if=/dev/zero of=/swapfile bs=128M count=32",
      "sudo chmod 600 /swapfile",
      "sudo mkswap /swapfile",
      "sudo swapon /swapfile",
      "sudo chmod 777 /etc/fstab",
      "sudo echo '/swapfile swap swap defaults 0 0' >> /etc/fstab",
      //install jenkins,sudo systemctl status jenkins --no-pager on ec2 to get admin pass
      // systemctl edit jenkins to set for jenkins only
      // go Dashboard>Manage Jenkins>System and remove github api rate limit
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum install jenkins -y",
      "sudo systemctl enable jenkins",
      "sudo usermod -a -G docker jenkins",
      "sudo systemctl start jenkins",
      "sudo systemctl status jenkins --no-pager"
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

//"sudo chmod 777 /etc/environment",
//"sudo echo 'M2_HOME=\"/opt/maven\"' >> /etc/environment",
//"sudo echo 'PATH=\"/opt/maven/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games\"' >> /etc/environment",
//"sudo chmod 744 /etc/environment",
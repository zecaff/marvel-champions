resource "aws_security_group" "dynamicSG" {
  name        = "dynamicSG"
  description = "Allowed inbound traffic"

  //in bound rule of the security group
  dynamic "ingress" {
    for_each = var.sg_ports
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  //out bound rule of the security group
  dynamic "egress" {
    for_each = var.sg_ports
    iterator = port
    content {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_iam_role" "s3_ec2" {
  name = "s3_ec2"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.s3_ec2.id
}

resource "aws_iam_role_policy" "s3_ec2_policy" {
  name = "s3_ec2_policy"
  role = aws_iam_role.s3_ec2.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*",
          "s3-object-lambda:*"
        ],
        "Resource" : [
          "arn:aws:s3:::card-images-marvel-champions",
          "arn:aws:s3:::card-images-marvel-champions/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket" "images" {
  bucket = "card-images-marvel-champions"

  tags = {
    Name        = "Card Images Marvel Champions"
    Environment = "Dev"
  }
}

resource "aws_dynamodb_table" "cards" {
  name           = "CardTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "ID"
  range_key      = "Title"

  attribute {
    name = "ID"
    type = "S"
  }

  attribute {
    name = "Title"
    type = "S"
  }

  attribute {
    name = "Aspect"
    type = "S"
  }

  global_secondary_index {
    name               = "CardNameIndex"
    hash_key           = "Title"
    range_key          = "Aspect"
    write_capacity     = 5
    read_capacity      = 5
    projection_type    = "ALL"
  }

  tags = {
    Name        = "CardTable"
    Environment = "dev"
  }
}
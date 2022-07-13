terraform {
  backend "s3" {
    encrypt        = true
    bucket         = var.state_s3_bucket
    region         = var.state_region
    key            = var.state_key
    dynamodb_table = var.state_dynamodb_table
  }
}

provider "aws" {
  region  = var.aws_region
  # Add the assume_role fifth
  assume_role {
    role_arn     = aws_role_arn.terraform.arn
    session_name = "terraform"
  }
}

# Create this first
resource "aws_kms_key" "palmnft-main-terraform-state-key" {
  description             = "Encryption key for TF state"
  deletion_window_in_days = var.state_aws_kms_key
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "palmnft-main-terraform-state-storage-logging-s3" {
  bucket = var.state_logging_s3_bucket
  acl    = "log-delivery-write"

  versioning {
    #mfa_delete = true <maybe turn on later>
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.palmnft-main-terraform-state-key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket" "palmnft-main-terraform-state-storage-s3" {
  bucket = var.state_s3_bucket
  acl    = "private"

  versioning {
    #mfa_delete = true <maybe turn on later>
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.palmnft-main-terraform-state-key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  logging {
    target_bucket = aws_s3_bucket.palmnft-main-terraform-state-storage-logging-s3.id
    target_prefix = "terraform/"
  }

  lifecycle_rule {
    id      = "log"
    enabled = true

    prefix = "terraform/"

    tags = {
      "rule"      = "log"
      "autoclean" = "true"
    }

    transition {
      days          = var.state_logging_bucket_onezoneia_days
      storage_class = "ONEZONE_IA"
    }

    transition {
      days          = var.state_logging_bucket_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Create this second
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name           = "palmnft-main-terraform-state-lock-dynamo"
  hash_key       = "LockID"
  read_capacity  = var.state_dynamodb_table_read_cap
  write_capacity = var.state_dynamodb_table_write_cap
  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Create this fourth
data "aws_iam_policy_document" "terraform" {
  statement {
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.palmnft-main-terraform-state-storage-s3.arn,
      aws_s3_bucket.palmnft-main-terraform-state-storage-logging-s3.arn
    ]
  }

  statement {
    actions = ["dynamodb:*"]
    resources = [
      aws_dynamodb_table.dynamodb-terraform-state-lock.arn
    ]
  }

  statement {
    actions = ["kms:*"]
    resources = [
      aws_kms_key.palmnft-main-terraform-state-key.arn
    ]
  }

  statement {
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = [
      data.aws_secretsmanager_secret_version.one-pass-token.arn,
      data.aws_secretsmanager_secret_version.one-pass-secretkey.arn,
    ]
  }

  statement {
    actions = ["iam:GetRole", "iam:GetRolePolicy", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies"]
    resources = [
      "arn:aws:iam::<account>:role/terraform"
    ]
  }

}

resource "aws_iam_role" "terraform" {
  name = "terraform"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Principal": {
    "AWS": "arn:aws:iam::<account>:role/aws-reserved/sso.amazonaws.com/{{$var.aws_region}}/AWSReservedSSO_AWSAdministratorAccess_<random>"
    }
  }
}
EOF
}

resource "aws_iam_role_policy" "terraform" {
  name   = "terraform"
  role   = aws_iam_role.terraform.id
  policy = data.aws_iam_policy_document.terraform.json
}


## Process to reconcile:
# Option 1) 
#  Create new SG with Terraform and attach along side existing SG then manually remove old.
#
# Option 2)
#  Use terraform import on the resource, ie. terraform import aws_security_group.ipfs <securitygroup id>.

resource "aws_security_group" "ipfs" {
  name        = "ipfs"
  description = "Allow traffic"

  ingress {
    description = "Allow inbound traffic"
    from_port   = 4001
    to_port     = 4001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  ingress {
    description = "Allow inbound traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }
  
  ingress {
    description = "Allow inbound traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

}




resource "aws_instance" "ipfs1" {

  ami                         = var.ec2_ami
  associate_public_ip_address = false
  instance_type               = var.ec2_instance_size
  key_name                    = var.ipfs_keypair_name
  availability_zone           = var.ec2_az1
  vpc_security_group_ids      = [aws_security_group.ipfs.id]
  subnet_id                   = var.ec2_subnet1

}

resource "aws_instance" "ipfs2" {

  ami                         = var.ec2_ami
  associate_public_ip_address = false
  instance_type               = var.ec2_instance_size
  key_name                    = var.ipfs_keypair_name
  availability_zone           = var.ec2_az2
  vpc_security_group_ids      = [aws_security_group.ipfs.id]
  subnet_id                   = var.ec2_subnet2

}

resource "aws_instance" "ipfs3" {

  ami                         = var.ec2_ami
  associate_public_ip_address = false
  instance_type               = var.ec2_instance_size
  key_name                    = var.ipfs_keypair_name
  availability_zone           = var.ec2_az3
  vpc_security_group_ids      = [aws_security_group.ipfs.id]
  subnet_id                   = var.ec2_subnet3

}

resource "aws_ebs_volume" "ipfs1" {
  availability_zone = var.ec2_az1
  size              = var.ec2_ebs_volume_size
}

resource "aws_ebs_volume" "ipfs2" {
  availability_zone = var.ec2_az2
  size              = var.ec2_ebs_volume_size
}
resource "aws_ebs_volume" "ipfs3" {
  availability_zone = var.ec2_az3
  size              = var.ec2_ebs_volume_size
}

resource "aws_volume_attachment" "ipfs1" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ipfs1.id
  instance_id = aws_instance.ipfs1.id
}

resource "aws_volume_attachment" "ipfs2" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ipfs2.id
  instance_id = aws_instance.ipfs2.id
}

resource "aws_volume_attachment" "ipfs3" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ipfs3.id
  instance_id = aws_instance.ipfs3.id
}
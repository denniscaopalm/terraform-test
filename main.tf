terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "palmnft-main-terraform-remote-state-storage-s3"
    region         = "eu-west-1"
    key            = "master/palmnft-main-terraform/key"
    dynamodb_table = "palmnft-main-terraform-state-lock-dynamo"
  }
}

provider "aws" {
  region  = "eu-west-1"
  # Add the assume_role fifth
  assume_role {
    role_arn     = "arn:aws:iam::735775673300:role/terraform"
    session_name = "terraform"
  }
}

# Create this first
resource "aws_kms_key" "palmnft-main-terraform-state-key" {
  description             = "Encryption key for TF state"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "palmnft-main-terraform-state-storage-logging-s3" {
  bucket = "palmnft-main-terraform-state-storage-logging-s3"
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
  bucket = "palmnft-main-terraform-remote-state-storage-s3"
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

    prefix = "tf_tfe/"

    tags = {
      "rule"      = "log"
      "autoclean" = "true"
    }

    transition {
      days          = 30
      storage_class = "ONEZONE_IA"
    }

    transition {
      days          = 60
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
  read_capacity  = 20
  write_capacity = 20
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
    "AWS": "arn:aws:iam::<account>:role/aws-reserved/sso.amazonaws.com/eu-west-1/AWSReservedSSO_AWSAdministratorAccess_<random>"
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

resource "aws_instance" "ipfs1" {

  ami                         = "ami-abcd1234"
  associate_public_ip_address = false
  instance_type               = "t2.medium"
  key_name                    = "ipfs-keypair-name"
  availability_zone           = "eu-west-1a"
  vpc_security_group_ids      = ["sg-ipfs-arn"]
  subnet_id                   = "private-subnetid-1"

}

resource "aws_instance" "ipfs2" {

  ami                         = "ami-abcd1234"
  associate_public_ip_address = false
  instance_type               = "t2.medium"
  key_name                    = "ipfs-keypair-name"
  availability_zone           = "eu-west-1b"
  vpc_security_group_ids      = ["sg-ipfs-arn"]
  subnet_id                   = "private-subnetid-2"

}

resource "aws_ebs_volume" "ipfs1" {
  availability_zone = "eu-west-1a"
  size              = 100
}

resource "aws_ebs_volume" "ipfs2" {
  availability_zone = "eu-west-1a"
  size              = 100
}


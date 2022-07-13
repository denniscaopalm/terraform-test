# Terraform State / Access

variable "state_s3_bucket" {
  type    = string
  default = "palmnft-main-terraform-remote-state-storage-s3"
}

variable "state_logging_s3_bucket" {
  type    = string
  default = "palmnft-main-terraform-state-storage-logging-s3"
}

variable "state_region" {
  type    = string
  default = "eu-west-1"
}

variable "state_dynamodb_table" {
  type    = string
  default = "palmnft-main-terraform-state-lock-dynamo"
}

variable "aws_role_arn" {
  type    = string
  default = "arn:aws:iam::blabla:role/adminrole"
}

variable "state_aws_kms_key"
  type    = string
  default = "10"
}

variable "state_logging_bucket_onezoneia_days"
  type    = string
  default = "30"
}

variable "state_logging_bucket_glacier_days"
  type    = string
  default = "60"
}

variable "state_dynamodb_table_read_cap"
  type    = string
  default = "20"
}

variable "state_dynamodb_table_write_cap"
  type    = string
  default = "20"
}


# Systems

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "ec2_instance_size" {
  type    = string
  default = "t2.medium"
}

variable "ec2_ami" {
  type    = string
  default = "ami-abcd1234"
}

variable "ipfs_keypair_name" {
  type    = string
  default = "ipfs-keypair-name"
}

variable "ec2_az1" {
  type    = string
  default = "${var.ec2_region}a"
}

variable "ec2_az2" {
  type    = string
  default = "${var.ec2_region}b"
}

variable "ec2_az3" {
  type    = string
  default = "${var.ec2_region}c"
}

variable "ec2_subnet1" {
  type    = string
  default = "private-subnetid-1"
}

variable "ec2_subnet2" {
  type    = string
  default = "private-subnetid-2"
}

variable "ec2_subnet3" {
  type    = string
  default = "private-subnetid-3"
}

variable "ec2_ebs_volume_size" {
  type    = string
  default = "100"
}

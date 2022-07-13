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

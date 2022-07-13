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

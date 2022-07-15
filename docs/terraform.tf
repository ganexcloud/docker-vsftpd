module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "2.78.0"
  name                 = "vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1c", "us-east-1d"]
  public_subnets       = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnets      = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_s3_endpoint   = true
  enable_ipv6          = true
}

module "security_group_ftp" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "~> 3.0"
  name                = "Ftp"
  description         = "Ftp Security Group"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  use_name_prefix     = false
  ingress_with_cidr_blocks = [
    {
      from_port   = 21000
      to_port     = 21099
      protocol    = "tcp"
      description = "FTP Auth ports"
    },
    {
      from_port   = 21100
      to_port     = 21110
      protocol    = "tcp"
      description = "FTP Passive ports"
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "ec2_instance_ftp" {
  source                 = "git::https://gitlab.com/ganex-cloud/terraform/terraform-aws-ec2-instance.git?ref=0.12"
  name                   = "ftp"
  ami                    = "ami-0cff7528ff583bf9a"
  instance_type          = "t3.micro"
  key_name               = "ftp"
  vpc_security_group_ids = ["${module.security_group_ftp.this_security_group_id}"]
  subnet_id              = module.vpc.public_subnets[0]
  root_block_device = [
    {
      volume_size           = 10
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  ]
  ebs_block_device = [
    {
      device_name           = "/dev/xvdb"
      volume_size           = 8
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    },
    {
      device_name           = "/dev/xvdf"
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  ]
}

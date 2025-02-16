vpc_cidr        = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.201.0/24", "10.0.202.0/24"]
region          = "ap-south-1"
ami_id          = "ami-00bb6a80f01f03502"
instance_type   = "t2.micro"
key_name        = "default-aws-key-pair"
variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "private_subnets" {
  description = "Private Subnets CIDR"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public Subnets CIDR"
  type        = list(string)
}

variable "region" {
  description = "Default deployment region"
  type        = string
}

variable "ami_id" {
  description = "ami to use"
  type        = string
}

variable "instance_type" {
  description = "Instance type to spawn"
  type        = string
}

variable "key_name" {
  description = "Name of key pair to use"
  type        = string
}
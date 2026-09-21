variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc" {
  description = "VPC configuration"
  type = object({
    cidr                 = string
    public_subnet_cidrs  = list(string)
    private_subnet_cidrs = list(string)
    availability_zones   = list(string)
  })
}

variable "ec2" {
  description = "EC2 instances configuration"
  type = object({
    public_bastion = object({
      instance_type     = string
      ssh_key_name      = string
      allowed_ssh_cidrs = list(string)
    })
  })
}

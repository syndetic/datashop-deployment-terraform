variable "postgres_password" {
  type = string
  description = "Password for database; set in secrets/secrets.tfvars"
}

variable "webapp_domain_name" {
  type = string
  description = "Domain to run the datashop at including subdomain and TLD."
}

variable "worker_instance_class" {
  type = string
  default = "t2.medium"
}

variable "worker_autoscaling_desired_capacity" {
  type = number
  default = 3
}

variable "aws_profile" {
  type = string
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "vpc_name" {
  type = string
  default = "Datashop"
}
variable "vpc_azs" {
  type = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "db_instance_class" {
  type = string
  default = "db.t3.medium"
}

variable "db_instance_max_storage" {
  type = number
  default = 100
}

variable "db_instance_allocated_storage" {
  type = number
  default = 20
}

variable "s3_bucket_name" {
  type = string
  default = "datashop-bucket"
}


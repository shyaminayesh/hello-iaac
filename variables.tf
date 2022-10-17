variable "region" {
	type = string
	nullable = false
	description = "The region in which you would like to create AWS resources"
}

variable "private_subnet_cidr" {
	nullable = false
	type = list(string)
	default = [ "172.16.10.0/24", "172.16.20.0/24" ]
	description = "The list of CIDR blocks for private subnets"
}

variable "public_subnet_cidr" {
	nullable = false
	type = list(string)
	default = [ "172.16.110.0/24", "172.16.120.0/24" ]
	description = "The list of CIDR blocks for public subnets"
}
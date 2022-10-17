# VPC
resource "aws_vpc" "vpc" {
	cidr_block = "172.16.0.0/16"
	instance_tenancy = "default"
	enable_dns_support = true
	enable_dns_hostnames = true

	tags = {
		PROJECT = "IAAC-TF"
	}
}

# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
	vpc_id = aws_vpc.vpc.id
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
	count = 2
	cidr_block = tolist(var.private_subnet_cidr)[count.index]
	vpc_id = aws_vpc.vpc.id
	availability_zone = data.aws_availability_zones.availability_zones.names[count.index]
	depends_on = [ aws_vpc.vpc ]

	tags = {
		Name = "private-subnet-${count.index}"
		PROJECT = "IAAC-TF"
	}
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
	count = 2
	cidr_block = tolist(var.public_subnet_cidr)[count.index]
	vpc_id = aws_vpc.vpc.id
	availability_zone = data.aws_availability_zones.availability_zones.names[count.index]
	depends_on = [ aws_vpc.vpc ]

	tags = {
		Name = "public-subnet-${count.index}"
		PROJECT = "IAAC-TF"
	}
}

# Public Subnet Group
resource "aws_db_subnet_group" "rds_public_subnet_group" {
	name = "rds-public-subnet-group"
	subnet_ids = "${aws_subnet.public_subnet.*.id}"

	tags = {
		Name = "rds-public-subnet-group"
		PROJECT = "IAAC-TF"
	}
}

# RDS ( Primary )
resource "aws_db_instance" "rds_primary" {
	identifier = "rds-primary"
	engine = "mysql"
	db_name = "hello_db"
	username = "hello_db"
	password = "hello_db"
	allocated_storage = 5
	engine_version = 5.7
	skip_final_snapshot = true
	backup_retention_period = 7
	instance_class = "db.t2.micro"
	db_subnet_group_name = "rds-public-subnet-group"
	depends_on = [ aws_db_subnet_group.rds_public_subnet_group ]
	availability_zone = data.aws_availability_zones.availability_zones.names[0]

	tags = {
		Name = "rds-primary"
		PROJECT = "IAAC-TF"
	}
}

# RDS ( Replica )
resource "aws_db_instance" "rds-secondary" {
	identifier = "rds-secondary"
	skip_final_snapshot = true
	instance_class = "db.t2.micro"
	replicate_source_db = "${aws_db_instance.rds_primary.identifier}"
	availability_zone = data.aws_availability_zones.availability_zones.names[1]
	depends_on = [ aws_db_subnet_group.rds_public_subnet_group, aws_db_instance.rds_primary ]

	tags = {
		Name = "rds-secondary"
		PROJECT = "IAAC-TF"
	}
}

# ECR
resource "aws_ecr_repository" "ecr_repository" {
	name = "hello"
	image_tag_mutability = "MUTABLE"
	force_delete = true

	image_scanning_configuration {
		scan_on_push = false
	}

	tags = {
		Name = "ecr-repository"
		PROJECT = "IAAC-TF"
	}
}

# CodeBuild
resource "aws_codebuild_project" "codebuild_project" {
	name = "hello"
	build_timeout = 120
	service_role = aws_iam_role.iam_role.arn
	depends_on = [ aws_ecr_repository.ecr_repository ]

	artifacts {
	  type = "NO_ARTIFACTS"
	}

	source {
		type = "GITHUB"
		location = "https://github.com/shyaminayesh/hello-go.git"
		git_clone_depth = 1
	}

	environment {
		image = "aws/codebuild/standard:4.0"
		type = "LINUX_CONTAINER"
		compute_type = "BUILD_GENERAL1_SMALL"
		image_pull_credentials_type = "CODEBUILD"
		privileged_mode = true

		environment_variable {
			name = "AWS_REGION"
			type = "PLAINTEXT"
			value = var.region
		}

		environment_variable {
			name = "AWS_ACCOUNT_ID"
			type = "PLAINTEXT"
			value = data.aws_caller_identity.current.account_id
		}

		environment_variable {
			name = "AWS_ACCESS_KEY_ID"
			type = "PLAINTEXT"
			value = aws_iam_access_key.ecr_iam_user.id
		}

		environment_variable {
			name = "AWS_SECRET_ACCESS_KEY"
			type = "PLAINTEXT"
			value = aws_iam_access_key.ecr_iam_user.secret
		}

		environment_variable {
			name = "AWS_DEFAULT_REGION"
			type = "PLAINTEXT"
			value = var.region
		}
	}

	logs_config {
		cloudwatch_logs {
			status = "DISABLED"
		}
	}
}

# CodeBuild: Trigger
resource "null_resource" "codebuild_trigger_build" {
	provisioner "local-exec" {
		command = "aws codebuild start-build --project-name hello"
	}
	triggers = {
		always_run = "${timestamp()}"
	}
	depends_on = [ aws_codebuild_project.codebuild_project ]
}

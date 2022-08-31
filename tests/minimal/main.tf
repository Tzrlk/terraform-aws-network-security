# Test environment setup for all cases

terraform {
	required_version = "~> 1.2"
	required_providers {
		aws = {
			source  = "hashicorp/aws"
			version = "~> 4.28"
		}
		test = {
			source = "terraform.io/builtin/test"
		}
	}
}

provider "aws" {

	# Fake credentials
	access_key = "mock_access_key"
	secret_key = "mock_secret_key"
	region     = "us-east-1"

	# Settings for fakery
	s3_use_path_style           = true
	skip_credentials_validation = true
	skip_metadata_api_check     = true
	skip_requesting_account_id  = true

	# Faked services
	endpoints {
		ec2 = "http://localhost:4566"
	}
}

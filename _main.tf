# Module requirements, variables, and outputs.

# region Module Requirements ###################################################
terraform {
	required_version = ">= 0.12"
	experiments = [
		module_variable_optional_attrs,
	]
	required_providers {
		aws = {
			source = "hashicorp/aws"
		}
	}
}
# endregion ####################################################################

# region Input Variables #######################################################
variable "VpcId" {
	description = "The VPC to set the security groups up in if not overridden."
	type        = string
	validation {
		error_message = "Value must be a valid VPC id."
		condition     = length(regexall("^vpc-([\\da-f]{8}|[\\da-d]{17})$", var.VpcId)) == 0
	}
}
variable "CidrBlocks" {
	description = "Named CIDR address blocks to incorporate into rules."
	type        = map(string)
	validation {
		error_message = "All entries must be valid CIDR definitions."
		condition     = length([
			for name, cidr in var.CidrBlocks :
				format("%s: %s", name, cidr)
				if length(regexall("^(?:\\d{1,3}\\.){3}\\d{1,3}/\\d{1,2}$", cidr)) < 1
		]) == 0
	}
}
variable "SecurityGroupsExisting" {
	description = "Security groups that already exist and should be integrated."
	type        = map(string)
	validation {
		error_message = "All entries must be valid Security Group ids."
		condition     = length([
			for name, cidr in var.SecurityGroupsExisting :
				format("%s: %s", name, cidr)
				if length(regexall("^sg-([\\da-f]{8}|[\\da-f]{17})$", cidr)) < 1
		]) == 0
	}
}
variable "SecurityGroupsNew" {
	description = "Security groups to create before setting the rules up."
	type        = map(object({
		Name        = string
		Description = string
		VpcId       = optional(string)
		Tags        = optional(map(string))
	}))
	# TODO: complex validation, including desc/name regexes.
}
variable "PortRanges" {
	description = "Definitions for all the port ranges used in this config."
	type        = map(object({
		Proto = string
		Min   = number
		Max   = number
		Tags  = optional(map(string))
	}))
	# TODO: complex validation.
}
variable "Rules" {
	description = "Traffic allowed from where to where over which ranges."
	type        = map(map(set(string)))
}
# endregion ####################################################################

# region Output Values #########################################################
output "SecurityGroupsCreated" {
	description = "Ids of all the security groups created."
	value       = {
		for key in keys(var.SecurityGroupsNew) :
			key => aws_security_group.Group[key].id
	}
}
# endregion ####################################################################

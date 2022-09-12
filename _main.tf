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
variable "CidrBlocks" {
	description = "Named CIDR address blocks to incorporate into rules."
	type        = map(string)
	default     = {
		Anywhere = "0.0.0.0/0"
	}
	validation {
		error_message = "All entries must be valid CIDR definitions."
		condition     = length([
			for name, cidr in var.CidrBlocks :
				format("%s: %s", name, cidr)
				if length(regexall("^(?:\\d{1,3}\\.){3}\\d{1,3}/\\d{1,2}$", cidr)) < 1
		]) == 0
	}
}
variable "SecurityGroupIds" {
	description = "Security groups that already exist and should be integrated."
	type        = map(string)
	validation {
		error_message = "All entries must be valid Security Group ids."
		condition     = length([
			for name, cidr in var.SecurityGroupIds :
				format("%s: %s", name, cidr)
				if length(regexall("^sg-([\\da-f]{8}|[\\da-f]{17})$", cidr)) < 1
		]) == 0
	}
}
variable "PortRanges" {
	description = "Definitions for all the port ranges used in this config."
	type        = map(object({
		Proto = optional(string)
		Min   = number
		Max   = optional(number)
		Tags  = optional(map(string))
	}))
	# TODO: complex validation.
}
variable "Rules" {
	description = "Traffic allowed from where to where over which ranges."
	type        = map(map(set(string)))
}
# endregion ####################################################################

# region Data ##################################################################
data "aws_security_group" "Groups" {
	for_each = var.SecurityGroupIds

	id = each.value
}
# endregion ####################################################################

# region Output Values #########################################################
output "Rules" {
	description = "Ids of all the created rules."
	value       = {
		for key in keys(var.SecurityGroupIds) : key => concat([
			for rule in aws_security_group_rule.GroupEgress: rule.id
				if rule.security_group_id == key
		], [
			for rule in aws_security_group_rule.GroupIngress: rule.id
				if rule.security_group_id == key
		], [
			for rule in aws_security_group_rule.CidrEgress: rule.id
				if rule.security_group_id == key
		], [
			for rule in aws_security_group_rule.CidrIngress: rule.id
				if rule.security_group_id == key
		])
	}
}
# endregion ####################################################################

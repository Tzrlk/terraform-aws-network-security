# Module requirements, variables, and outputs.

# region Module Requirements ###################################################
terraform {
	required_version = ">= 1.3"
	required_providers {
		aws = {
			source = "hashicorp/aws"
		}
	}
}
# endregion ####################################################################

# region Input Variables #######################################################
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

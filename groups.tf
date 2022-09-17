
variable "CidrBlocks" {
	description = <<-CDATA
		Named CIDR address blocks to incorporate into rules. CIDR blocks don't
		have rules applied against them directly, so don't appear in outputs,
		but the Security Group part of the rule is included on the subject in
		question. CIDR to CIDR rules will be ignored.
	CDATA
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
	description = <<-CDATA
		Security groups that already exist and should be integrated with a
		specific rule configuration.
	CDATA
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
data "aws_security_group" "Groups" {
	for_each = var.SecurityGroupIds

	id = each.value
}

# TODO: Add security group creation.

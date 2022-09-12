# Rules are calculated and applied here.

locals {
	RuleListFull = flatten([
		for Subject, Objects in var.Rules : [
			for Object, Ports in Objects : [
				for Port in Ports : merge(var.PortRanges[Port], {
					Name    = "${Subject}${Object}${Port}"
					Subject = Subject
					Object  = Object
					Port    = Port
				})
			]
		]
	])
}

# region Group to Group ########################################################
locals {
	RuleListGroups = {
		for Rule in local.RuleListFull :
			Rule["Name"] => Rule
			if contains(keys(var.SecurityGroupIds), Rule["Subject"])
			&& contains(keys(var.SecurityGroupIds), Rule["Object"])
	}
}
resource "aws_security_group_rule" "GroupEgress" {
	for_each = local.RuleListGroups

	type                     = "egress"
	security_group_id        = data.aws_security_group.Groups[each.value["Subject"]].id
	source_security_group_id = data.aws_security_group.Groups[each.value["Object"]].id
	from_port                = each.value["Min"]
	to_port                  = coalesce(each.value["Max"], each.value["Min"])
	protocol                 = coalesce(each.value["Proto"], "tcp")
	description              = format("%s traffic from %s to %s",
			coalesce(each.value["Proto"], "tcp"),
			each.value["Object"],
			each.value["Subject"])
}
resource "aws_security_group_rule" "GroupIngress" {
	for_each = local.RuleListGroups

	type                     = "ingress"
	security_group_id        = data.aws_security_group.Groups[each.value["Object"]].id
	source_security_group_id = data.aws_security_group.Groups[each.value["Subject"]].id
	from_port                = each.value["Min"]
	to_port                  = coalesce(each.value["Max"], each.value["Min"])
	protocol                 = coalesce(each.value["Proto"], "tcp")
	description              = format("%s traffic from %s to %s",
			coalesce(each.value["Proto"], "tcp"),
			each.value["Object"],
			each.value["Subject"])
}
# endregion ####################################################################

# region Group -> CIDR, CIDR -> Group ##########################################
resource "aws_security_group_rule" "CidrEgress" {
	for_each = {
		for Rule in local.RuleListFull :
			Rule["Name"] => Rule
			if contains(keys(var.CidrBlocks), Rule["Object"])
	}

	type              = "egress"
	security_group_id = data.aws_security_group.Groups[each.value["Subject"]].id
	cidr_blocks       = [ var.CidrBlocks[each.value["Object"]] ]
	from_port         = each.value["Min"]
	to_port           = coalesce(each.value["Max"], each.value["Min"])
	protocol          = coalesce(each.value["Proto"], "tcp")
	description              = format("%s traffic from %s to %s",
			coalesce(each.value["Proto"], "tcp"),
			each.value["Object"],
			each.value["Subject"])
}
resource "aws_security_group_rule" "CidrIngress" {
	for_each = {
		for Rule in local.RuleListFull :
			Rule["Name"] => Rule
			if contains(keys(var.CidrBlocks), Rule["Subject"])
	}

	type              = "ingress"
	security_group_id = data.aws_security_group.Groups[each.value["Object"]].id
	cidr_blocks       = [ var.CidrBlocks[each.value["Subject"]] ]
	from_port         = each.value["Min"]
	to_port           = coalesce(each.value["Max"], each.value["Min"])
	protocol          = coalesce(each.value["Proto"], "tcp")
	description       = format("%s traffic from %s to %s",
			coalesce(each.value["Proto"], "tcp"),
			each.value["Object"],
			each.value["Subject"])
}
# endregion ####################################################################

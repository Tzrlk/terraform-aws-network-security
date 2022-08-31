# Rules are calculated and applied here.

locals {
	RuleListFull = flatten([
		for subject, objects in var.Rules : [
			for object, ports in objects : [
				for port in ports : merge(var.PortRanges[ port ], {
					Name    = "${subject}${object}${port}"
					Subject = subject
					Object  = object
					Port    = port
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
			if can(var.SecurityGroupIds[Rule["Subject"]])
			&& can(var.SecurityGroupIds[Rule["object"]])
	}
}
resource "aws_security_group_rule" "GroupEgress" {
	for_each = local.RuleListGroups

	type                     = "egress"
	security_group_id        = data.aws_security_group.Groups[each.value["Subject"]].id
	source_security_group_id = data.aws_security_group.Groups[each.value["Object"]].id
	from_port                = each.value["Min"]
	to_port                  = each.value["Max"]
	protocol                 = each.value["Proto"]
}
resource "aws_security_group_rule" "GroupIngress" {
	for_each = local.RuleListGroups

	type                     = "ingress"
	security_group_id        = data.aws_security_group.Groups[each.value["Object"]].id
	source_security_group_id = data.aws_security_group.Groups[each.value["Subject"]].id
	from_port                = each.value["Min"]
	to_port                  = each.value["Max"]
	protocol                 = each.value["Proto"]
	description              = format("%s traffic from %s to %s",
			each.value["Proto"],
			each.value["Object"],
			each.value["Subject"])
}
# endregion ####################################################################

# region Group -> CIDR, CIDR -> Group ##########################################
resource "aws_security_group_rule" "CidrEgress" {
	for_each = {
		for Rule in local.RuleListFull :
			Rule["Name"] => Rule
			if can(var.CidrBlocks[Rule["Object"]])
	}

	type              = "egress"
	security_group_id = data.aws_security_group.Groups[each.value["Subject"]].id
	cidr_blocks       = [ var.CidrBlocks[each.value["Object"]] ]
	from_port         = each.value["Min"]
	to_port           = each.value["Max"]
	protocol          = each.value["Proto"]
}
resource "aws_security_group_rule" "CidrIngress" {
	for_each = {
		for Rule in local.RuleListFull :
			Rule["Name"] => Rule
			if can(var.CidrBlocks[Rule["Subject"]])
	}

	type              = "ingress"
	security_group_id = data.aws_security_group.Groups[each.value["Object"]].id
	cidr_blocks       = [ var.CidrBlocks[each.value["Subject"]] ]
	from_port         = each.value["Min"]
	to_port           = each.value["Max"]
	protocol          = each.value["Proto"]
}
# endregion ####################################################################

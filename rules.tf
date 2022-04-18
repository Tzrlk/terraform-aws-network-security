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
	RuleListGroupsNew = {
		for Rule in local.RuleListFull :
			Rule["Name"] => Rule
			if can(var.SecurityGroupsNew[Rule["Subject"]])
			&& can(var.SecurityGroupsNew[Rule["object"]])
	}
}
resource "aws_security_group_rule" "GroupNewEgress" {
	for_each = local.RuleListGroupsNew

	type                     = "egress"
	security_group_id        = aws_security_group.Group[each.value["Subject"]]
	source_security_group_id = aws_security_group.Group[each.value["Object"]]
	from_port                = each.value["Min"]
	to_port                  = each.value["Max"]
	protocol                 = each.value["Proto"]
}
resource "aws_security_group_rule" "GroupNewIngress" {
	for_each = local.RuleListGroupsNew

	type                     = "ingress"
	security_group_id        = aws_security_group.Group[each.value["Object"]]
	source_security_group_id = aws_security_group.Group[each.value["Subject"]]
	from_port                = each.value["Min"]
	to_port                  = each.value["Max"]
	protocol                 = each.value["Proto"]
	description              = format("%s traffic from %s to %s",
			each.value["Proto"],
			each.value["Object"],
			each.value["Subject"])
}
# endregion ####################################################################

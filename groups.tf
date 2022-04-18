# Create the new security groups here.

resource "aws_security_group" "Group" {
	for_each = var.SecurityGroupsNew
	lifecycle {
		create_before_destroy = true
	}

	vpc_id      = var.VpcId
	name_prefix = each.value.Name # TODO: Have to do something about this.
	tags        = merge(lookup(each.value, "Tags", {}), {
		Name        = each.value.Name
		Description = each.value.Description
	})
}

# Identify provided existing security groups.
data "aws_security_group" "GroupExisting" {
	for_each = var.SecurityGroupsExisting

	id = each.value
}

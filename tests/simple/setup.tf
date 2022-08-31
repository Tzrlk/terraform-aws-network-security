
resource "aws_security_group" "GroupA" {
}

resource "aws_security_group" "GroupB" {
}

module "NetworkSecurity" {
	source = "../.."

	SecurityGroupIds = {
		GroupA = aws_security_group.GroupA.id
		GroupB = aws_security_group.GroupB.id
	}
	PortRanges       = {
		Http = { Min: 80, Max: 80 }
	}
	Rules            = {
		GroupA = {
			GroupB = [ "Http" ] # From GroupA to GroupB via Http
		}
	}
}

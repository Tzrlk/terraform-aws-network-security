# Only one resource needed for an empty config.

module "NetworkSecurity" {
	source = "../.."

	SecurityGroupIds = {} # TODO: Should probably throw an error if any of these are empty.
	PortRanges       = {}
	Rules            = {}
}

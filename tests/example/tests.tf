
resource "test_assertions" "RuleChecks" {
	component = "rules"

	equal "BothGroups" {
		description = "The rule count should be the total of all directions."
		got         = length(module.NetSec.Rules["Apps"])
		want        = 5 + 1
	}

	check "WithCidr" {
		description = "CIDRs aren't included in outputs."
		condition   = can(module.NetSec.Rules["Anywhere"])
	}

}

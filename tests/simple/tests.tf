
resource "test_assertions" "Static" {
	component = "module"

	equal "empty" { # TODO: Expecting this to fail.
		description = "With no security groups, we're expecting there to be no outputs."
		got         = module.NetworkSecurity.Rules
		want        = []
	}
}

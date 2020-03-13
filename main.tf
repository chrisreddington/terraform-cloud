provider "tfe" {
}

# Create an organization
#resource "tfe_organization" "org" {
#  name = "Theatreers"
#  email = "chris@theatreers.com"
#}

# Dummy Test
resource "tfe_workspace" "test" {
  name         = "my-workspace-name"
  organization = "Theatreers"
}

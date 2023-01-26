
variable "github_username" {
  type = string
}

variable "github_pat" {
  type = string
  description = "GitHub PAT with repo scope"
}

variable "org_name" {
  type = string
}

variable "github_org_pat" {
  type = string
  description = "GitHub PAT with admin:org scope"
}

variable "repo_owner" {
  type = string
}
variable "repo_name" {
  type = string
}
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "parameters" {
  description = "SSM parameters to create"
  type = map(object({
    value       = string
    type        = string # String, StringList, or SecureString
    description = string
  }))
}

variable "region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region = var.region
  # Credentials are picked up from the environment, shared credentials file, or instance profile.
}

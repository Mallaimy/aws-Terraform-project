# define varaible

variable "tags" {
    type = string
    default = "Terraform"
}

variable "az" {
    type = list(string)
    default = ["us-east-1a", "us-east-1b"]
}


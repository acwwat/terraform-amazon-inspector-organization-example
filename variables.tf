variable "enable_ec2" {
  description = "Whether Amazon EC2 scans should be enabled for both existing and new member accounts in the organization."
  type        = bool
  default     = true
}

variable "enable_ecr" {
  description = "Whether Amazon ECR scans should be enabled for both existing and new member accounts in the organization."
  type        = bool
  default     = true
}

variable "enable_lambda" {
  description = "Whether Lambda Function scans should be enabled for both existing and new member accounts in the organization."
  type        = bool
  default     = true
}

variable "enable_lambda_code" {
  description = "Whether Lambda code scans should be enabled for both existing and new member accounts in the organization."
  type        = bool
  default     = true
}

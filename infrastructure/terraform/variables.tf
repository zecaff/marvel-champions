variable "sg_ports" {
  type        = list(number)
  description = "ports used for ec2 security groups"
  default     = [22, 80, 443, 8080]
}
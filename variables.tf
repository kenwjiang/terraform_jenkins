variable "profile" {
  type    = string
  default = "default"
}

variable "instance-type" {
  default = "t3.micro"
  type    = string
}

variable "worker-count" {
  type    = number
  default = 1
}

variable "region" {
  type    = string
  default = "us-west-1"
}

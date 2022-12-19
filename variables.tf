variable "ssh_key" {
    description = "SSH Key"
    default = "~/.ssh/id_rsa"
}

variable "yc_user" {
    description = "User to run instance"
    default = "ubuntu"
}


variable "module" {
    description = "path to configs of containers"
    default = "/Users/andrew_borovets/cloud-terraform"
}


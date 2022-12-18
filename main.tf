terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-b"
}


resource "yandex_compute_instance" "vm-1" {
  name = "nginx"

  resources {
    cores  = 2
    memory = 2
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt install -y screen && sudo apt-get install -y nginx"
    ]
    connection {
      type = "ssh"
      user = var.yc_user
      private_key = file(var.ssh_key)
      host = self.network_interface[0].nat_ip_address
    }
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.yc_user}:${file("${var.ssh_key}.pub")}"
  }
}

resource "yandex_compute_instance" "vm-2" {
  name = "apache"

  resources {
    cores  = 4
    memory = 4
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y screen && sudo apt install -y apache2"
    ]
    connection {
      type = "ssh"
      user = var.yc_user
      private_key = file(var.ssh_key)
      host = self.network_interface[0].nat_ip_address
    }
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.yc_user}:${file("${var.ssh_key}.pub")}"
  }
}

resource "yandex_compute_instance" "vm-3" {
  name = "python"

  resources {
    cores  = 2
    memory = 2
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt install -y screen && cd /home/ubuntu && su - ubuntu && sudo screen -dm \"python3 -m http.server 80 --bind 0.0.0.0\"" # ???????
    ]
    connection {
      type = "ssh"
      user = var.yc_user
      private_key = file(var.ssh_key)
      host = self.network_interface[0].nat_ip_address
    }
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.yc_user}:${file("${var.ssh_key}.pub")}"
  }
}

resource "yandex_compute_instance" "vm-4" {
  name = "web-db-1"

  resources {
    cores  = 2
    memory = 2
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      # "sudo apt install apt-transport-https ca-certificates curl software-properties-common",
      # "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      # "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable\"",
      # "sudo apt update",
      # "apt-cache policy docker-ce",
      # "sudo apt install docker-ce",
      # "sudo systemctl status docker",
      # "sudo usermod -aG docker ${var.yc_user}",
      # "docker pull avborovets/restful_api_example",
      # "docker run -p 80:8099 --rm -d --name restful_api_example avborovets/restful_api_example"
    ]
    connection {
      type = "ssh"
      user = var.yc_user
      private_key = file(var.ssh_key)
      host = self.network_interface[0].nat_ip_address
    }
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.yc_user}:${file("${var.ssh_key}.pub")}"
  }
}

resource "yandex_compute_instance" "vm-5" {
  name = "web-db-2"

  resources {
    cores  = 2
    memory = 2
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      # "sudo apt install apt-transport-https ca-certificates curl software-properties-common",
      # "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      # "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable\"",
      # "sudo apt update",
      # "apt-cache policy docker-ce",
      # "sudo apt install docker-ce",
      # "sudo systemctl status docker",
      # "sudo usermod -aG docker ${var.yc_user}",
      # "docker pull avborovets/restful_api_example",
      # "docker run -p 80:8099 --rm -d --name restful_api_example avborovets/restful_api_example"
    ]
    connection {
      type = "ssh"
      user = var.yc_user
      private_key = file(var.ssh_key)
      host = self.network_interface[0].nat_ip_address
    }
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq6d0p8sij7h5qe3"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.yc_user}:${file("${var.ssh_key}.pub")}"
  }
}



resource "yandex_alb_target_group" "web_servers" {
  name      = "web-servers"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address   = "${yandex_compute_instance.vm-1.network_interface.0.ip_address}"
  }
  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address   = "${yandex_compute_instance.vm-2.network_interface.0.ip_address}"
  }
}

resource "yandex_alb_target_group" "python" {
  name      = "python"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address   = "${yandex_compute_instance.vm-3.network_interface.0.ip_address}"
  }
}

resource "yandex_alb_target_group" "web_dbs" {
  name      = "web-dbs"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address   = "${yandex_compute_instance.vm-4.network_interface.0.ip_address}"
  }
  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address   = "${yandex_compute_instance.vm-5.network_interface.0.ip_address}"
  }
}



resource "yandex_alb_backend_group" "web_servers_backend_group" {
  name      = "web-servers-backend-group"

  http_backend {
    name = "web-servers-http-backend"
    weight = 1
    port = 80
    target_group_ids = ["${yandex_alb_target_group.web_servers.id}"]
    load_balancing_config {
      panic_threshold = 50
    }
    healthcheck {
      timeout = "1s"
      interval = "1s"
      healthcheck_port = 80
      http_healthcheck {
        path  = "/"
      }
    }
  }
}

resource "yandex_alb_backend_group" "python_backend_group" {
  name      = "python-backend-group"

  http_backend {
    name = "python-http-backend"
    weight = 1
    port = 80
    target_group_ids = ["${yandex_alb_target_group.python.id}"]
    load_balancing_config {
      panic_threshold = 50
    }    
    healthcheck {
      timeout = "1s"
      interval = "1s"
      healthcheck_port = 80
      http_healthcheck {
        path  = "/"
      }
    }
  }
}

resource "yandex_alb_backend_group" "web_dbs_backend_group" {
  name      = "web-dbs-backend-group"

  http_backend {
    name = "web-dbs-http-backend"
    weight = 1
    port = 80
    target_group_ids = ["${yandex_alb_target_group.web_dbs.id}"]
    load_balancing_config {
      panic_threshold = 50
    }    
    healthcheck {
      timeout = "1s"
      interval = "1s"
      healthcheck_port = 80
      http_healthcheck {
        path  = "/"
      }
    }
  }
}


resource "yandex_alb_http_router" "my_router" {
  name      = "my-super-router"
  labels = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }

}




resource "yandex_alb_virtual_host" "virtual_host" {
  name           = "virtual-host"
  http_router_id = yandex_alb_http_router.my_router.id
  route {
    name = "route-for-web-servers"
    http_route {
      http_match {
        http_method = []
      	path {
      	  prefix = "/servers"
      	}
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_servers_backend_group.id
        timeout = "3s"
        prefix_rewrite = "/"
      }
    }
  }
  route {
    name = "route-for-web-dv"
    http_route {
      http_match {
        http_method = []
        path {
          prefix = "/db"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_servers_backend_group.id
        timeout = "3s"
        prefix_rewrite = "/"
      }
    }
  }
}



resource "yandex_alb_load_balancer" "my_load_balancer" {
  name        = "my-load-balancer"

  network_id  = yandex_vpc_network.network-1.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet-1.id 
    }
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }    
    http {
      handler {
        http_router_id = yandex_alb_http_router.my_router.id
      }

    }
  }    
}


resource "yandex_vpc_network" "network-1" {
  name = "network1"
}


resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "ip_address" {
  value = yandex_compute_instance.vm-1.network_interface[0].nat_ip_address
  description = "Public ip address"
}



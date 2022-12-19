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






#####################################################################################################################################
##  
##  yandex_compute_instance


resource "yandex_compute_instance" "vm-1" {
  name = "nginx"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt install -y nginx"
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
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt install -y apache2"
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
    core_fraction = 20
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      # "sudo apt-get install -y screen", пробовал сначала через screen, а не через nohup, но появлялась ошибка
      # "cd /home/ubuntu",
      "nohup sudo python3 -m http.server 80 --bind 0.0.0.0 > /dev/null 2>&1 &", # "sudo screen -dm python3 -m 'http.server 80 --bind 0.0.0.0'",
      "sleep 1"
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





#####################################################################################################################################
##  
##  containers


data "yandex_compute_image" "container-optimized-image" {
  family = "container-optimized-image"
}

resource "yandex_compute_instance" "container-web-db-1" {
  name = "container-web-db-1"

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.container-optimized-image.id
    }
  }

  resources {
    cores = 2
    memory = 2
    core_fraction = 20
  }

  metadata = {
    docker-container-declaration = file("${var.module}/declaration.yaml") # var.module = ~/cloud-terraform
    user-data = file("${var.module}/cloud_config.yaml")
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }
}

resource "yandex_compute_instance" "container-web-db-2" {
  name = "container-web-db-2"

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.container-optimized-image.id
    }
  }

  resources {
    cores = 2
    memory = 2
    core_fraction = 20
  }

  metadata = {
    docker-container-declaration = file("${var.module}/declaration.yaml") # var.module = ~/cloud-terraform
    user-data = file("${var.module}/cloud_config.yaml")
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }
}





#####################################################################################################################################
##  
##  yandex_alb_target_group


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
    ip_address   = "${yandex_compute_instance.container-web-db-1.network_interface.0.ip_address}"
  }
  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address   = "${yandex_compute_instance.container-web-db-2.network_interface.0.ip_address}"
  }
}





#####################################################################################################################################
##  
##  yandex_alb_backend_group


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
    port = 8099
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





#####################################################################################################################################
##  
##  yandex_alb_load_balancer, yandex_alb_http_router, yandex_alb_virtual_host


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
    name = "route-for-python"
    http_route {
      http_match {
        http_method = []
        path {
          prefix = "/python"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.python_backend_group.id
        timeout = "3s"
        prefix_rewrite = "/"
      }
    }
  }
  route {
    name = "route-for-web-db"
    http_route {
      http_match {
        http_method = []
        path {
          prefix = "/web-db"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_dbs_backend_group.id
        timeout = "3s"
        prefix_rewrite = "/users"
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





#####################################################################################################################################
##  
##  network


resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}





#####################################################################################################################################
##  
##  yandex_api_gateway


################### generated by swagger ###############
# curl -X 'POST' \
#   'https://d5dl0m97t15rpnevqp36.apigw.yandexcloud.net/users' \
#   -H 'accept: */*' \             
#   -H 'Content-Type: application/json' \
#   -d '{
#   "id": 0, 
#   "nickname": "kolya", 
#   "email": "bbb@ccc",   
#   "rating": 100500
# }'

################### generated by swagger ###############
# curl -X 'PUT' \
#   'https://d5dl0m97t15rpnevqp36.apigw.yandexcloud.net/users/11' \
#   -H 'accept: application/json' \
#   -H 'Content-Type: application/json' \
#   -d '{
#   "id": 11,
#   "nickname": "qqqqqq",
#   "email": "wwww@eeeee",
#   "rating": 1543
# }'


resource "yandex_api_gateway" "my-super-api-gateway" {
  name        = "my-super-api-gateway"
  description = "some description"
  labels      = {
    label       = "label"
    empty-label = ""
  }
  spec = <<-EOT
    openapi: 3.0.0
    info:
      title: Sample API
      version: 1.0.0
    servers:
    - url: https://d5dj41gj507llogo6m97.apigw.yandexcloud.net
    paths:
      /:
        get:
          x-yc-apigateway-integration:
            type: dummy
            content:
              '*': Hello, World!
            http_code: 200
            http_headers:
              Content-Type: text/plain
      /users:
        post:
          x-yc-apigateway-integration:
            type: http
            method: POST
            url: http://${yandex_compute_instance.container-web-db-1.network_interface.0.nat_ip_address}:8099/users
            headers:
              Content-Type: '{Content-Type}'
            timeouts:
              connect: 0.5
              read: 5
          parameters:
          - explode: true
            in: header
            name: Content-Type
            required: true
            schema:
              type: string
            style: form
          - explode: true
            in: query
            name: nickname
            required: true
            schema:
              type: string
            style: form
          - explode: true
            in: query
            name: email
            required: false
            schema:
              type: string
            style: form
          - explode: true
            in: query
            name: rating
            required: false
            schema:
              type: integer
            style: form
      /users/{id}:
        put:
          x-yc-apigateway-integration:
            type: http
            method: PUT
            url: http://${yandex_compute_instance.container-web-db-1.network_interface.0.nat_ip_address}:8099/users/{id}
            headers:
              Content-Type: '{Content-Type}'
            timeouts:
              connect: 0.5
              read: 5
          parameters:
          - explode: true
            in: path
            name: id
            required: true
            schema:
              type: string
            style: form
          - explode: true
            in: query
            name: id
            required: true
            schema:
              type: string
            style: form
          - explode: true
            in: header
            name: Content-Type
            required: true
            schema:
              type: string
            style: form
          - explode: true
            in: query
            name: nickname
            required: true
            schema:
              type: string
            style: form
          - explode: true
            in: query
            name: email
            required: false
            schema:
              type: string
            style: form
          - explode: true
            in: query
            name: rating
            required: false
            schema:
              type: integer
            style: form
  EOT
}

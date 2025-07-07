variable "name" {
  description = "Nombre del microservicio"
  type        = string
}

variable "image_order_create" {
  description = "Imagen Docker para order-create"
  type        = string
}

variable "port_order_create" {
  description = "Puerto para order-create"
  type        = number
}

variable "image_order_read" {
  description = "Imagen Docker para order-read"
  type        = string
}

variable "port_order_read" {
  description = "Puerto para order-read"
  type        = number
}

variable "image_order_add" {
  description = "Imagen Docker para order-add"
  type        = string
}

variable "port_order_add" {
  description = "Puerto para order-add"
  type        = number
}

variable "image_order_delete" {
  description = "Imagen Docker para order-delete"
  type        = string
}

variable "port_order_delete" {
  description = "Puerto para order-delete"
  type        = number
}

variable "mongo_url" {
  description = "URL de conexión a MongoDB"
  type        = string
}

variable "branch" {
  description = "Tag de Docker"
  type        = string
}

variable "vpc_id" {
  type    = string
  default = "vpc-0697808a974fef452"
}

variable "subnets" {
  type    = list(string)
  default = ["subnet-0049cf73cb42dc01f", "subnet-03bd5e4b54dfcfb6e"]
}

variable "ami_id" {
  type    = string
  default = "ami-020cba7c55df1f615"
}

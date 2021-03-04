# Definition of location
variable "location" {
  type = string
  description = "Azure region where infrastructure will be deployed"
  default = "West Europe"
}
# Definition of VM's specs
variable "vm_size" {
  type = string
  description = "Virtual machines size"
  default = "Standard_D2_v2" # 7 GB, 2 CPU 
}
# Definition of VM's names (and number)
variable "vms" {
  description = "Virtual machines Relationship"
  type = list(string)
  default = ["master","worker-a"]
  
}
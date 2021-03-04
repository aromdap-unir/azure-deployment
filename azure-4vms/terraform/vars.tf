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
  default = "Standard_D1_v2" # 3.5 GB, 1 CPU 
}
# Definition of VM's names (and number)
variable "vms" {
  description = "Virtual machines Relationship"
  type = list(string)
  default = ["master","nfs","worker-a","worker-b"]
  
}
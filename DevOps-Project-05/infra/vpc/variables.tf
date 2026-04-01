variable "common_tags" {
  type = map 
  default = {
    Owner = "Andrii Romanchuk"
    Project = "SuperPower"
    CostCenter = "99999999999"
    Environment = "Production"
  }
}
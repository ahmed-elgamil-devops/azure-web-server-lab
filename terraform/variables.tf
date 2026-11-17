variable "project" {
  description = "Short name used as a prefix for every resource. Lowercase letters and digits only."
  type        = string
  default     = "weblab"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.project))
    error_message = "project must be 3-12 lowercase letters or digits (it becomes part of a storage account name)."
  }
}

variable "location" {
  description = "Azure region. UAE North is the closest region to Dubai."
  type        = string
  default     = "uaenorth"
}

variable "vm_size" {
  description = "VM size. Standard_B1s is the smallest burstable size and is free-tier eligible."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Login name for the VM."
  type        = string
  default     = "azureadmin"
}

variable "ssh_public_key_path" {
  description = "Path to the public half of your SSH key pair."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "admin_source_ip" {
  description = "The only IP address allowed to reach port 22. Find yours with: curl ifconfig.me"
  type        = string

  validation {
    condition     = var.admin_source_ip != "0.0.0.0/0" && var.admin_source_ip != "*"
    error_message = "Refusing to open SSH to the whole internet. Set this to your own IP address."
  }
}

variable "alert_email" {
  description = "Address that Azure Monitor alerts are sent to."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource, so lab resources are easy to find and delete."
  type        = map(string)

  default = {
    project     = "azure-web-server-lab"
    environment = "lab"
    managed_by  = "terraform"
  }
}

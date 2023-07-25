variable "name" {
  type        = string
  description = "Name of the REST API"
}

variable "description" {
  type        = string
  default     = ""
  description = "Description for the REST API."
}

variable "body" {
  type        = any
  description = "An OpenAPI specification that defines the set of routes and integrations to create as part of the REST API."
}

variable "api_key_source" {
  type        = string
  default     = "HEADER"
  description = "Source of the API key for requests."
}

variable "disable_execute_api_endpoint" {
  type        = bool
  default     = false
  description = "Whether clients can invoke your API by using the default execute-api endpoint"
}

variable "endpoint_configuration" {
  type        = any
  description = "Configuration block defining API endpoint configuration including endpoint type"
}

variable "fail_on_warnings" {
  type        = bool
  default     = false
  description = "Whether warnings while API Gateway is creating or updating the resource should return an error or not"
}

variable "api_resource_policy" {
  type        = any
  description = "JSON formatted policy document that controls access to the API Gateway"
  default     = "" 
}

variable "attach_resource_policy" {
  type        = bool
  description = "Flag which controls whether to attach a resource policy to the API or not"
  default     = false
}

variable "put_rest_api_mode" {
  type        = string
  default     = "overwrite"
  description = "Mode of the PutRestApi operation when importing an OpenAPI specification via the body argument (create or update operation)"
}

variable "api_tags" {
  type        = map(string)
  description = "A map of tags to be added to the API"
  default     = {}
}

variable "stage" {
  default     = []
  type        = any
  description = "A map of configuration for stage"
}

variable "method" {
  default     = []
  type        = any
  description = "A map of configuration for method"
}

variable "method_settings" {
  default     = []
  type        = any
  description = "A map of configuration for stage method settings"
}

variable "integration" {
  default     = []
  type        = any
  description = "A map of configuration for method integration"
}

variable "resource" {
  default     = []
  type        = any
  description = "A map of configuration for resource"
}

variable "vpc_link" {
  default     = []
  type        = any
  description = "A map of configuration for VPC link"
}
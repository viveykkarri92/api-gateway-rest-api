output "api_arn" {
  value = aws_api_gateway_rest_api.default_rest_api.execution_arn
}

output "vpc_link_id" {
  value = aws_api_gateway_vpc_link.default_vpc_link[*].id
}

output "root_resource_id" {
  value = aws_api_gateway_rest_api.default_rest_api.root_resource_id
}

output "resource_id" {
  value = aws_api_gateway_resource.default_resource[*].id
}

output "api_method" {
  value = aws_api_gateway_method.default_api_method[*].http_method
  }

output "stage_invoke_url" {
  value = aws_api_gateway_stage.default_stage[*].invoke_url
}

output "cw_loggroup_arn" {
  value = aws_cloudwatch_log_group.default_stage_cloudwatch_loggroup[*].arn
}
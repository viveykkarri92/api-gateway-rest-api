resource "aws_api_gateway_rest_api" "default_rest_api" {
  name                          = var.name
  description                   = var.description
  body                          = jsonencode(var.body)
  api_key_source                = var.api_key_source
  disable_execute_api_endpoint  = var.disable_execute_api_endpoint
  put_rest_api_mode             = var.put_rest_api_mode
  fail_on_warnings              = var.fail_on_warnings
  tags                          = var.api_tags

  dynamic "endpoint_configuration" {
    for_each = length(var.endpoint_configuration) > 0 ? [var.endpoint_configuration] : []

    content {
      types = try(endpoint_configuration.value.types, null)
      vpc_endpoint_ids = try(endpoint_configuration.value.vpc_endpoint_ids, null)
    }
  }
}

resource "aws_api_gateway_rest_api_policy" "default_api_resource_policy" {
  count       = var.attach_resource_policy ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.default_rest_api.id
  policy      = var.api_resource_policy
}

resource "aws_api_gateway_deployment" "default_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.default_rest_api.id

   triggers = {
     redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.default_rest_api.body,
      aws_api_gateway_method.default_api_method,
      aws_api_gateway_integration.default_api_method_integration,
      aws_api_gateway_resource.default_resource
      ]))
   }

   lifecycle {
    create_before_destroy = true
  }

   depends_on = [ aws_api_gateway_method.default_api_method,
                 aws_api_gateway_integration.default_api_method_integration,
                 aws_api_gateway_resource.default_resource
               ]
}

resource "aws_api_gateway_stage" "default_stage" {
  count                 = length(var.stage)
  rest_api_id           = aws_api_gateway_rest_api.default_rest_api.id
  stage_name            = lookup(var.stage[count.index], "stage_name", null)
  deployment_id         = aws_api_gateway_deployment.default_api_deployment.id
  
  dynamic "access_log_settings" {
    for_each = try([var.stage[count.index].access_log_settings], [])

    content {
      destination_arn   = aws_cloudwatch_log_group.default_stage_cloudwatch_loggroup[count.index].arn
      format            = "$context.extendedRequestId $context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"
    }
  }

  cache_cluster_enabled = lookup(var.stage[count.index], "cache_cluster_enabled", false)
  cache_cluster_size    = lookup(var.stage[count.index], "cache_cluster_size", null)
  
  dynamic canary_settings {
    for_each = try([var.stage[count.index].canary_settings], [])

    content {
      percent_traffic           = try(canary_settings.value.percent_traffic, null)
      stage_variable_overrides  = try(canary_settings.value.stage_variable_overrides, null)
      use_stage_cache           = try(canary_settings.value.use_stage_cache, null)
    }

  }
  client_certificate_id = lookup(var.stage[count.index], "client_certificate_id", null)
  description           = lookup(var.stage[count.index], "description", null)
  documentation_version = lookup(var.stage[count.index], "documentation_version", null)
  variables             = lookup(var.stage[count.index], "variables", {})
  tags                  = lookup(var.stage[count.index], "tags", {})
  xray_tracing_enabled  = lookup(var.stage[count.index], "xray_tracing_enabled", null)

  depends_on = [ aws_cloudwatch_log_group.default_stage_cloudwatch_loggroup,
  aws_api_gateway_resource.default_resource,
  aws_api_gateway_method.default_api_method,
  aws_api_gateway_integration.default_api_method_integration ]
}




resource "aws_api_gateway_vpc_link" "default_vpc_link" {
  count                 = length(var.vpc_link)
  name                  = lookup(var.vpc_link[count.index], "name", null)
  description           = lookup(var.vpc_link[count.index], "description", null)
  target_arns           = [lookup(var.vpc_link[count.index], "nlb_arn", null)]
  tags                  = lookup(var.vpc_link[count.index], "tags", {})
}

resource "aws_api_gateway_resource" "default_resource" {
  count                 = length(var.resource)
  rest_api_id           = aws_api_gateway_rest_api.default_rest_api.id
  parent_id             = lookup(var.resource[count.index], "parent_id", null)
  path_part             = lookup(var.resource[count.index], "path", null)
}

resource "aws_api_gateway_method" "default_api_method" {
  count                 = length(var.method)
  rest_api_id           = aws_api_gateway_rest_api.default_rest_api.id
  resource_id           = lookup(var.method[count.index], "resource_id", null)
  http_method           = lookup(var.method[count.index], "http_method", null)
  authorization         = lookup(var.method[count.index], "authorization", null)
  authorizer_id         = lookup(var.method[count.index], "authorizer_id", null)
  authorization_scopes  = lookup(var.method[count.index], "authorization_scopes", null)
  api_key_required      = lookup(var.method[count.index], "api_key_required", null)
  operation_name        = lookup(var.method[count.index], "operation_name", null)
  request_models        = lookup(var.method[count.index], "request_models", {})
  request_validator_id  = lookup(var.method[count.index], "request_validator_id", null)
  request_parameters    = lookup(var.method[count.index], "request_parameters", {})
}

resource "aws_api_gateway_method_response" "default_api_method_response" {
  count                   = length(var.method)
  rest_api_id             = aws_api_gateway_rest_api.default_rest_api.id
  resource_id             = lookup(var.method[count.index], "resource_id", null)
  http_method             = lookup(var.method[count.index], "http_method", null)
  status_code             = lookup(var.method[count.index], "status_code", null)
  response_models         = lookup(var.method[count.index], "response_models", {})
  response_parameters     = lookup(var.method[count.index], "response_parameters", {})
  depends_on = [ aws_api_gateway_method.default_api_method ]
}

resource "aws_api_gateway_integration" "default_api_method_integration" {
  count                   = length(var.integration)
  rest_api_id             = aws_api_gateway_rest_api.default_rest_api.id
  resource_id             = lookup(var.integration[count.index], "resource_id", null)
  http_method             = lookup(var.integration[count.index], "http_method", null)
  type                    = lookup(var.integration[count.index], "integration_type", null)
  timeout_milliseconds    = lookup(var.integration[count.index], "timeout_milliseconds", null)
  integration_http_method = lookup(var.integration[count.index], "integration_http_method", null)
  connection_type         = lookup(var.integration[count.index], "connection_type", null)
  connection_id           = lookup(var.integration[count.index], "connection_id", null)
  uri                     = lookup(var.integration[count.index], "uri", null)
  request_parameters      = lookup(var.integration[count.index], "request_parameters", {})
  request_templates       = lookup(var.integration[count.index], "request_templates", {})
  cache_key_parameters    = lookup(var.integration[count.index], "cache_key_parameters", [])
  cache_namespace         = lookup(var.integration[count.index], "cache_namespace", null)
}

resource "aws_api_gateway_integration_response" "default_api_method_integration_response" {
  count                   = length(var.integration)
  rest_api_id             = aws_api_gateway_rest_api.default_rest_api.id
  resource_id             = lookup(var.integration[count.index], "resource_id", null)
  http_method             = lookup(var.integration[count.index], "http_method", null)
  status_code             = lookup(var.integration[count.index], "status_code", null)
  response_parameters     = lookup(var.integration[count.index], "response_parameter", {})
  response_templates      = lookup(var.integration[count.index], "response_template", {})
  selection_pattern       = lookup(var.integration[count.index], "selection_pattern", null)
  depends_on = [ aws_api_gateway_integration.default_api_method_integration ]
}

resource "aws_api_gateway_method_settings" "api_method_setting" {
  count       = length(var.method_settings)
  rest_api_id = aws_api_gateway_rest_api.default_rest_api.id
  stage_name  = lookup(var.method_settings[count.index], "stage_name", null)
  method_path = lookup(var.method_settings[count.index], "method_path", null)
  
  settings {
    metrics_enabled                             = lookup(var.method_settings[count.index], "metrics_enabled", false)
    logging_level                               = lookup(var.method_settings[count.index], "logging_level", "OFF")
    data_trace_enabled                          = lookup(var.method_settings[count.index], "data_trace_enabled", false)
    throttling_burst_limit                      = lookup(var.method_settings[count.index], "throttling_burst_limit", "-1")
    throttling_rate_limit                       = lookup(var.method_settings[count.index], "throttling_rate_limit", "-1")
    caching_enabled                             = lookup(var.method_settings[count.index], "caching_enabled", null)
    cache_ttl_in_seconds                        = lookup(var.method_settings[count.index], "cache_ttl_in_seconds", null)
    cache_data_encrypted                        = lookup(var.method_settings[count.index], "cache_data_encrypted", null)
    require_authorization_for_cache_control     = lookup(var.method_settings[count.index], "require_authorization_for_cache_control", null)
    unauthorized_cache_control_header_strategy  = lookup(var.method_settings[count.index], "unauthorized_cache_control_header_strategy", null)
  }
}

resource "aws_cloudwatch_log_group" "default_stage_cloudwatch_loggroup" {
  count               = length(var.stage)
  name                = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.default_rest_api.id}/${lookup(var.stage[count.index], "stage_name", null)}"
  retention_in_days   = 30
}

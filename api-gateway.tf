data "aws_lb" "nlb" {
  name = "fxcm-nlb-ecs-service"
}


module "api-gw" {
  source    = "./modules/aws-api-gateway"

  name                      = "fxcm-poc_rest-api"
  description               = "POC for API Gateway"
  attach_resource_policy    = false
  api_resource_policy       = templatefile("api_resource_policy.json", {api_execution_arn = module.api-gw.api_arn})
  body      = {
        openapi = "3.0.1"
        paths = {
        "/" = {
            get = {
            x-amazon-apigateway-integration = {
                httpMethod           = "GET"
                payloadFormatVersion = "1.1"
                type                 = "HTTP"
                connection_type      = "VPC_LINK"
                connection_id        = "${module.api-gw.vpc_link_id}"
                uri                  = "https://viveykkarri.com"
            }
            }
        }
        }
    }

  endpoint_configuration = {
    types = ["REGIONAL"]
  }

  resource = [
    {
        parent_id = module.api-gw.root_resource_id
        path = "prod"
    }
  ]

  method = [
    {
        resource_id = module.api-gw.resource_id[0]
        http_method = "GET"
        authorization = "NONE"
        api_key_required = false
        status_code = 200
    }
  ]

  integration = [ 
    {
        resource_id = module.api-gw.resource_id[0]
        http_method = module.api-gw.api_method[0]
        integration_type = "HTTP"
        connection_type = "VPC_LINK"
        integration_http_method = "GET"
        connection_id = module.api-gw.vpc_link_id[0]
      #  uri = "https://${data.aws_lb.nlb.dns_name}"
        uri = "https://viveykkarri.com"
        status_code = 200
        timeout_milliseconds = 29000
    }
    
   ]

  stage = [
    {
        stage_name = "prod"

    }
  ]

  vpc_link = [
    {
        name        = "fxcm-vpc-link-poc"
        description = "POC for API Gateway VPC Link"
        nlb_arn     = data.aws_lb.nlb.arn
    }
  ]
}
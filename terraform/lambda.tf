resource "aws_iam_role" "get_fortune_package" {
  name = "get-fortune"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "AttachAWSLambdaBasicExecutionRole" {
  role       = aws_iam_role.get_fortune_package.name
  policy_arn = data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}

data "aws_iam_policy" "AWSLambdaVPCAccessExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "AttachAWSLambdaVPCAccessExecutionRole" {
  role       = aws_iam_role.get_fortune_package.name
  policy_arn = data.aws_iam_policy.AWSLambdaVPCAccessExecutionRole.arn
}

# Role is allowed to assume itself. Yep.
# Workaround for IAM auth to RDS. In order to get the connection password token,
# you have to call RDS client but you have to use temporary assumed credentials. Yep.
resource "aws_iam_role_policy" "assume_itsel" {
  name = "RoleCanAssumeItselWorkaroundYolo"
  role = aws_iam_role.get_fortune_package.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "sts:AssumeRole"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:iam::909130508899:role/get-fortune"
      }
    ]
  }
  EOF
}

resource "aws_lambda_layer_version" "lambda_dependencies" {
  filename   = "${path.module}/../get_fortune_lambda/get_fortune_lambda_libs.zip"
  layer_name = "get_fortune_lambda_libs"

  compatible_runtimes = ["python3.8"]
}

data "archive_file" "get_fortune_package" {
  type        = "zip"
  output_path = "${path.module}/../get_fortune_lambda/lambda_function.zip"
  
  source {
    content  = file("${path.module}/../get_fortune_lambda/lambda_function.py")
    filename = "lambda_function.py"
  }

  source {
    content  = file("${path.module}/../get_fortune_lambda/rds-combined-ca-bundle.pem")
    filename = "rds-combined-ca-bundle.pem"
  }
}

resource "aws_lambda_function" "get_fortune" {
  function_name    = "get-fortune"
  filename         = "${path.module}/../get_fortune_lambda/lambda_function.zip"
  role             = aws_iam_role.get_fortune_package.arn
  handler          = "lambda_function.handler"
  source_code_hash = data.archive_file.get_fortune_package.output_base64sha256

  runtime = "python3.8"
  timeout = 5

  # private subnets because it needs access to internet / sts assume-role and that's not possible with VPC Lambda & public subnets
  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [module.vpc.default_security_group_id]
  }

  layers = [
      aws_lambda_layer_version.lambda_dependencies.arn
  ]

  environment {
    variables = {
      DB_HOST = module.rds.this_db_instance_address
    }
  }
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowApiGwInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_fortune.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.fortunes.execution_arn}/*"
}

resource "aws_iam_user" "lambda_gh_deploy" {
  name = "get-fortune-lambda-gh-deploy"
  path = "/service/deploy/"
}

resource "aws_iam_user_policy" "lambda_gh_deploy" {
  name = "get-fortune-lambda-gh-deploy"
  user = aws_iam_user.lambda_gh_deploy.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:UpdateFunctionCode"
      ],
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.get_fortune.arn}"
    }
  ]
}
EOF
}

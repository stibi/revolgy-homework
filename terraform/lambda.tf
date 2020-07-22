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

data "archive_file" "get_fortune_package" {
  type        = "zip"
  source_file = "${path.module}/../get_fortune_lambda/lambda_function.py"
  output_path = "${path.module}/../get_fortune_lambda/lambda_function.zip"
}

resource "aws_lambda_function" "get_fortune" {
  function_name    = "get-fortune"
  filename         = "${path.module}/../get_fortune_lambda/lambda_function.zip"
  role             = aws_iam_role.get_fortune_package.arn
  handler          = "lambda_function.handler"
  source_code_hash = data.archive_file.get_fortune_package.output_base64sha256

  runtime = "python3.8"

  environment {
    variables = {
      foo = "bar"
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

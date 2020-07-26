resource "aws_cognito_user_pool" "revolgy_homework" {
  name = "revolgy-homework"

  mfa_configuration = "OFF"

  lambda_config {
    pre_sign_up = "arn:aws:lambda:eu-west-1:909130508899:function:autoConfirmUserFunction"
  }
}

resource "aws_cognito_user_pool_client" "revolgy_homework" {
  name = "revolgy-homework"

  user_pool_id = aws_cognito_user_pool.revolgy_homework.id

  # generate_secret     = false
  explicit_auth_flows = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

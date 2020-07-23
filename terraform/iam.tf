resource "aws_iam_user" "terraform_deploy" {
  name = "terraform-deploy"
  path = "/service/deploy/"
}

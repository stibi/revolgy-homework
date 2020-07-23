terraform {
  backend "s3" {
    bucket = "terraform-state-stibi-personal"
    key    = "revolgy-homework"
    region = "eu-west-1"
  }
}

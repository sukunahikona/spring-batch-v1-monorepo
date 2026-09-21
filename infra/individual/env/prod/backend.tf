terraform {
  backend "s3" {
    bucket  = "spring-batch-v1-terraform-state"
    key     = "individual/env/prod/terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}

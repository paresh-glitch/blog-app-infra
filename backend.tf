terraform {
  backend "s3" {
    bucket         = "paresh-tf-state-bucket" # The exact bucket from step 1
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-locks" # The exact table from step 1
    encrypt        = true
  }
}

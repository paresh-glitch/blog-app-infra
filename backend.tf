terraform {
  backend "s3" {
    bucket         = "paresh-tf-state-bucket" # The exact bucket from step 1
    region         = "ap-south-1"
    use_lockfile = true
    encrypt        = true
  }
}

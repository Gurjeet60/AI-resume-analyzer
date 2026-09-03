terraform {
  backend "s3" {
    bucket       = "ai-resume-analyzer-tfstate-716228812170"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
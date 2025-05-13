resource "aws_s3_bucket" "terraform_state" {
  bucket        = "terraform-state-bucketxyz123"
  force_destroy = true

  tags = {
    Name        = "TerraformStateBucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

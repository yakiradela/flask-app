

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-bucketxyz123"

  tags = {
    Name = "TerraformState"
  }
}

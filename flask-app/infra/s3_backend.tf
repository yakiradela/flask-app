terraform {
  backend "s3" {
    bucket = "terraform-state-bucketxyz123"    # שם הבקט שיצרת
    key    = "terraform/terraform.tfstate"      # המיקום של ה-state בתוך ה-bucket
    region = "us-east-2"                        # האזור שבו נמצא ה-S3 bucket
    encrypt = true                              # אם אתה רוצה להצפין את הקובץ ב-S3
  }
}


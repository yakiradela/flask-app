resource "aws_ecr_repository" "app" {
  name = "flask-app-repo"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "FlaskAppRepository"
    Environment = "Dev"
  }
}

# Single shared repository for both images, differentiated by tag
# (taro:api, taro:pipeline) - matches the old Azure Container Registry setup
# rather than one repo per image.
resource "aws_ecr_repository" "taro" {
  name = "taro"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "taro"
  }
}

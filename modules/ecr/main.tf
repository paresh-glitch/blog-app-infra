resource "aws_ecr_repository" "this" {
  count                = length(var.repo_names)
  name                 = "${var.env}-${var.repo_names[count.index]}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    prevent_destroy = false
  }
}


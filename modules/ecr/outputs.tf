output "repo_urls" {
  value = { for i, repo in aws_ecr_repository.this : "${var.env}-${var.repo_names[i]}" => repo.repository_url }
}


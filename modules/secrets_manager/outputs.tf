output "secret_arn" {
  value = data.aws_secretsmanager_secret.this.arn
}

output "secret_string" {
  value = data.aws_secretsmanager_secret_version.this.secret_string
  sensitive = true
}

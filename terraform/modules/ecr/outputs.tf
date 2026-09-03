output "frontend_repository_url" {
  description = "ECR repository URL for the frontend"
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_repository_url" {
  description = "ECR repository URL for the backend"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_repository_arn" {
  description = "ECR repository ARN for the frontend"
  value       = aws_ecr_repository.frontend.arn
}

output "backend_repository_arn" {
  description = "ECR repository ARN for the backend"
  value       = aws_ecr_repository.backend.arn
}
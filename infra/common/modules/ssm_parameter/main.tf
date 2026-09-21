###############################################################################
# SSM Parameters
###############################################################################
resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name        = "/${var.project}/${var.environment}/${each.key}"
  description = each.value.description
  type        = each.value.type
  value       = each.value.value

  tags = {
    Name = "${var.project}-${var.environment}-${each.key}"
  }

  # 値の変更を無視（初回作成後、AWS ConsoleやCLIで直接更新可能）
  lifecycle {
    ignore_changes = [value]
  }
}

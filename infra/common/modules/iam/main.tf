###############################################################################
# GitHub Actions OIDC Provider
# AWSアカウントに1つだけ存在するため common で管理する
###############################################################################
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # thumbprint_list はAPIの必須フィールドのため記述が必要だが、
  # AWSはGitHub ActionsのOIDCトークン検証にサムプリントを使用しない
  # （AWS管理の証明書ストアで検証するため値は実質無効）
  thumbprint_list = [
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  ]

  tags = {
    Name = "github-actions-oidc-provider"
  }
}

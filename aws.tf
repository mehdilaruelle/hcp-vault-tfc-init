data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "hcp_vault_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "auth_engine" {
  name = "${var.project_name}_vault_assume_role_policy"

  assume_role_policy = data.aws_iam_policy_document.hcp_vault_assume_role_policy.json
}

resource "aws_iam_role_policy" "auth_engine" {
  name = "${var.project_name}_vault_auth_engine"
  role = aws_iam_role.auth_engine.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "iam:GetInstanceProfile",
          "iam:GetUser",
          "iam:GetRole"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "application" {
  name = "${var.project_name}_vault_pipeline_role_policy"

  assume_role_policy = data.aws_iam_policy_document.hcp_vault_assume_role_policy.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
  ]
}

# HCP Vault do NOT have the permission to assume role so
# we need to create a user with static credentials
# to provide the permission to assume the role
resource "aws_iam_user" "vault" {
  name = "${var.project_name}-vault"
}

resource "aws_iam_access_key" "aws_engine" {
  user = aws_iam_user.vault.name
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      aws_iam_role.application.arn,
      aws_iam_role.auth_engine.arn
    ]
  }
}

resource "aws_iam_user_policy" "assume_role_policy" {
  name   = "${var.project_name}-vault"
  user   = aws_iam_user.vault.name
  policy = data.aws_iam_policy_document.assume_role_policy.json
}

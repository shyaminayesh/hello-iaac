resource "aws_iam_role" "iam_role" {
	name = "tf-iam-role"

	assume_role_policy = jsonencode({
		Version = "2012-10-17"
		Statement = [
			{
				Action = "sts:AssumeRole"
				Effect = "Allow"
				Principal = {
					Service = [ "codebuild.amazonaws.com" ]
				}
			},
		]
	})

	inline_policy {
		name = "tf-inline-policy"
		policy = jsonencode({
			Version = "2012-10-17",
			Statement = [
				{
					Action = [ "cloudwatch:*" ],
					Effect = "Allow",
					Resource = "*"
				}
			]
		})
	}
}

resource "aws_iam_user" "ecr_iam_user" {
	name = "tf-ecr"
}

resource "aws_iam_user_policy" "ecr_iam_user_policy" {
	name = "tf-ecr-user-policy"
	user = aws_iam_user.ecr_iam_user.name

	policy = jsonencode({
		Version = "2012-10-17",
		Statement = [
			{
				Action = [ "ecr:*" ],
				Effect = "Allow",
				Resource = "*"
			}
		]
	})
}

resource "aws_iam_access_key" "ecr_iam_user" {
	user = aws_iam_user.ecr_iam_user.name
}
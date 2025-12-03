# Developer IAM Credential Setup

This Terraform module provisions an IAM user with programmatic access, attaches the necessary permissions (Secrets Manager, S3, KMS), and stores the generated access keys in AWS Secrets Manager in the Dev Account under the name `developer-iam-credentials`.

## Prerequisites

- AWS CLI v2 configured with **SSO**
- Logged in to AWS SSO:
  
  ```bash
  export AWS_PROFILE=<your-profile>
  aws sso login
  ```

## How to Retrieve AWS Credentials

The access key and secret key are stored as a JSON blob in the `developer-iam-credentials` secret. To retrieve them:

```bash
aws secretsmanager get-secret-value \
  --secret-id developer-iam-credentials \
  --query 'SecretString' \
  --output text
```

You will get output like:

```json
{
  "aws_access_key_id": "AKIAxxxxxxxxxxxx",
  "aws_secret_access_key": "xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
```

## Use the Credentials

You can export them to your shell session (your sso credentials will not work anymore):

```bash
export AWS_REGION=us-gov-west-1
export AWS_ACCESS_KEY_ID=AKIAxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxx
unset AWS_SESSION_TOKEN
```

Then test access:

```bash
aws s3 ls
```

These credentials can now be used in tooling (e.g., Helm, External Secrets Operator, MinIO, Vault, etc.) that doesn't support SSO or STS-based authentication.


## Notes

* These credentials are static. Rotate them periodically if required.
* Use this only in dev/test environments where IRSA is not an option (e.g., `k3d` clusters).

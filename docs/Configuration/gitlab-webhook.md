
# Setting Up a Webhook for GitLab
            note: "Maintainer" access required to configure settings for Gitlab webhook.
## Step 1: Access Repository Settings

1. Navigate to your GitLab repository in your web browser.
2. Click on the "Settings" tab located on the right-hand side of the repository navigation.

## Step 2: Configure Visibility, project features, permissions
1. Select project visibility and set to public

## Step 3: Create Access Token for your webhook
1. Select "Access Tokens" from the left-hand side of the repository navigation.

2. Copy the generated access token and save it securely. You will need this token to authenticate your webhook requests. If you lose the token, you will need to generate a new one.

## Step 4: Configure Webhook
1. Scroll down to the "Webhooks" section.
2. Click on the "Expand" button to reveal the webhook configuration options.
3. Provide the URL where you want to receive the webhook events. This URL should be able to handle incoming HTTPS requests. (This will be the public URL of your Ec2 instance. e.g. https://ec2-3-85-141-188.compute-1.amazonaws.com/repo-sync) 
4. Choose the events that should trigger the webhook. You can select specific events like push, tag, or pipeline events. Select ("comments")
5. Set a secret token for added security. This token will be included in the webhook payload and can be used to verify the authenticity of the request. This secret will be added to your .env file as `GITLAB_WEBHOOK_SECRET=`

            note: only enable ssl verification once you have a valid ssl certificate from a trusted Certificate Authority. Otherwise, you will not be able to connect to webhook.

## Step 5: Save and Test Webhook

1. Click on the "Add webhook" button to save the webhook configuration.
2. GitLab will send a test payload to the provided URL.
3. Verify that the webhook is successfully received and processed by your endpoint.
4. If the test is successful, the webhook setup is complete. Otherwise, review the error message or logs to troubleshoot the issue.


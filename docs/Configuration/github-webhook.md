# Setting Up a Webhook for GitHub
This gitlab webhook will send payloads to your app when a comment is made on an issue or pull request is created/closed.

The following steps will guide you though:
  * the creation of a github app and installation to each desired repository. 
  * the generation and configuration of a client secret
  * the generation and configuration of a private key

### Important Notes
  * "Owner" access required to Create and configure settings for GitHub Apps.
  * Recommend creating the github App in the same organization as the repositories you wish to sync.

## Create a GitHub App
### Personal Account
Click on your profile picture > Settings > Developer Settings > GitHub Apps > New GitHub App
### Organization Account
Click on your profile picture > Your Organizations > Desired Organization > Settings > Developer Settings > GitHub Apps > New GitHub App

### Configure GitHub App Settings
   * **GitHub App name:** `repo-sync` (or whatever you want to call it)
     > note: this will be the name of your app you will see in the comments.

   * **Homepage URL:** `https://reposync.com`
     > note: does not need to be a real URL, but must be a valid URL format.

   * **Webhook URL:** `https://ec2-3-85-141-188.compute-1.amazonaws.com/repo-sync` 
     > note: this is the public DNS for your ec2 instance of repo-sync configured in [aws-ec2](./aws-ec2.md)
   
   * **Permissions**: Select the permissions that your GitHub App will need to access the repository. Choose "Read & write" access for "Issues" and "Pull requests".

   * **Subscribe to events:** select "issue comment" and "pull request" events.
   
   * **Where can this GitHub App be installed?**: Select "Only on this account" to limit the GitHub App to your user account.

   Click on the "Create GitHub App" button to save the configuration.

### Generate a client secret
   1. Click on the "Generate a new client secret" button to generate a new client secret. Copy the ID the clipboard. You will need this to authenticate your webhook requests. If you lose the secret, you will need to generate a new one.
   2. Paste the client secret in the ***Webhook secret (optional):*** field and click "Save Changes"
   3. Update the application per the instructions in [environment variables](./environment-variables.md) to include the client secret in the `.env` file.

#### Install GitHub App to your account
1. Click on Install Button on the left side of the page and select your account.

### Generate a private key
1. Navigate to "settings" then "developer settings" on the bottom left then select "edit" next to your app.

2. Scroll down and Click on the "Generate a private key" button to generate a private key. Save this key securely. You will need this key to authenticate your webhook requests. If you lose the key, you will need to generate a new one. 

> note: this privatekey should be renamed to `privatekey.pem` and placed in the root directory of your repo-sync app.

### Generate a new client secret
1. Navigate to "settings" then "developer settings" on the bottom left then next to select "edit" next to your app.
2. Click on the "Generate a new client secret" button to generate a new client secret. Copy the ID the clipboard. You will need this to authenticate your webhook requests. If you lose the secret, you will need to generate a new one.

paste to ***Webhook Secret:*** and click "Save Changes"

3. also Paste into your .env file as `GITHUB_WEBHOOK_SECRET=` 

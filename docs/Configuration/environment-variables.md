#### Environment Variables Setup

In order to ensure proper functioning of the repo-sync application, please follow the steps below:

1. Create a `.env` file in the root folder of the application.
2. Obtain the necessary variables by referring to the following resources:
   - For GitHub webhook setup, refer to [github webhook](./github-webhook.md)
   - For GitLab webhook setup, refer to [gitlab webhook](./gitlab-webhook.md)

Ensure that you have the following variables defined in your `.env` file:

```conf
GITHUB_WEBHOOK_SECRET=8d2f255661823a5ca6xxxxxxxxxxxxxxxxxxxxxx
GITLAB_WEBHOOK_SECRET=04080ecc7ea3d43043xxxxxxxxxxxxxxxxxxxxxx
GITLAB_USERNAME=johnDoe53
GITLAB_PASSWORD=repo1-dso-xxxxxxxxxxxxxxxxxxxxxxx
```

By default the application will run on port 8080. If you wish to change this, you can add the following variable to your `.env` file:

```conf
PORT=8080
```
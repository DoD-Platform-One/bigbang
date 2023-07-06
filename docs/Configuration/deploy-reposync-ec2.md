# EC2 Deployment Instructions

## Step 1: Connect to your EC2 Instance
You may connect to your instance initially using the AWS console, 
navigate to the EC2 service, and click "Connect" on the instance you wish to connect to.
This will provide you with a command to connect to your instance via SSH client, but you may also connect using your own SSH client. You will have to use the private key you selected when launching the instance.

`ssh -i /path/to/your/key.pem ec2-user@your-instance-ip`

## Step 2: Update System Packages
to ensure that the system packages are up to date and secure, run the following command:

`sudo yum update -y`

## Step 3: Install git, nvm, npm, and then node using nvm 
The following commands will install git, nvm, npm, and node using nvm. The current node version is 18.0.0 for this application.
```bash
    sudo yum install -y git

    sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

    source ~/.bash_profile

    sudo yum install -y npm

    nvm install 18

    nvm use 18
```
    
## Step 4: Clone the "repo-sync" Repository
`git clone https://repo1.dso.mil/big-bang/team/tools/repo-sync.git`
            
> note: you will require a personal access token to clone the repo from repo1.dso.mil.

## Step 5: Navigate to the App Directory
`cd repo-sync`

## Step 6: Install Dependencies
`npm install`

## Step 7: Configure the App
Follow the app's documentation for configuration instructions including [aws-ec2](./aws-ec2.md), [environment variables](./environment-variables.md), [github webhook](./github-webhook.md), and [gitlab webhook](./gitlab-webhook.md)

## Step 8: Starting the App
`npm run start`


# Running the App as a Linux Service
## Step 1: Build the App
`npm run build`

## Step 2: Configure a Linux Service
1. Create a new file in `/etc/systemd/system` with a `.service` extension, for example `/etc/systemd/system/repo-sync.service`.
2. Add the following content to the file, replacing `<USER>` with the username of the user that will run the service, and `<APP_DIR>` with the path to the app directory:
    ```conf
        [Unit]
        Description=Repo Sync Service
        After=network.target

        [Service]
        User=<USER>
        WorkingDirectory=<APP_DIR>
        ExecStart=npm run prod-start
        Restart=always
        RestartSec=10
        Environment=NODE_ENV=production

        [Install]
        WantedBy=multi-user.target
    ```
3. Save the file and exit the editor.
4. Reload the systemd daemon to read the new service file:
`sudo systemctl daemon-reload`
## Step 3: Start the Service
1. Start the service:
`sudo systemctl start repo-sync`
2. Verify that the service is running:
`sudo systemctl status repo-sync`
If the service is running correctly, you should see output similar to the following:

```
● repo-sync.service - Repo Sync Service
Loaded: loaded (/etc/systemd/system/repo-sync.service; disabled; vendor preset: enabled)
Active: active (running) since Mon 2021-10-18 14:30:00 UTC; 5s ago
Main PID: 12345 (npm)
    Tasks: 10 (limit: 4915)
Memory: 100.0M
CGroup: /system.slice/repo-sync.service
        ├─12345 npm
        └─12346 node /path/to/app/lib/index.js

Oct 18 14:30:00 hostname systemd[1]: Started Repo Sync Service.
```
## Optional Enable the Service to Start Automatically on Boot

`sudo systemctl enable repo-sync`

That's it! The app should now be running as a Linux service and will start automatically on boot.


# Updating the App

1. Stop the service:
`sudo systemctl stop repo-sync`

2. Navigate to the app directory and pull the latest changes from Git:
```bash
cd /path/to/app
git pull
```

3. Start the service:
`sudo systemctl start repo-sync`

4. Verify that the service is running:
`sudo systemctl status repo-sync`

If the service is running correctly, you should see output similar to the following:
```console
● repo-sync.service - Repo Sync Service
   Loaded: loaded (/etc/systemd/system/repo-sync.service; disabled; vendor preset: enabled)
   Active: active (running) since Mon 2021-10-18 14:30:00 UTC; 5s ago
 Main PID: 12345 (npm)
    Tasks: 10 (limit: 4915)
   Memory: 100.0M
   CGroup: /system.slice/repo-sync.service
           ├─12345 npm
           └─12346 node /path/to/app/lib/index.js

Oct 18 14:30:00 hostname systemd[1]: Started Repo Sync Service.
```

That's it! Your service should now be updated with the latest code from Git.

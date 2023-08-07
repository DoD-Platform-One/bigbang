# This guide is to provide instruction on how to deploy "repo-sync" 

# Windows OS

## Install Chocolatey
It is recommended you use the package manager "choco" provided by Terraform.

### Open Command Prompt or PowerShell as Administrator and run:
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

## Install Terraform using Chocolatey
### In the same Command Prompt or PowerShell window, run:
`choco install terraform`

## Verify Installation
### Run the following command to verify Terraform installation:
`terraform -version`

# Mac OS

## Install Terraform using Homebrew
### Open Terminal and run:
`brew install terraform`

## Verify Installation
### Run the following command to verify Terraform installation:
`terraform -version`


# Terraform Setup

## Working Directory
cd into the automation directory `cd ./automation`

## Initialize Terraform
`terraform init`
    
> note: You may need to open a session with AWS to provide credentials.

# Verify Terraform IAC
`terraform plan`

> note: Always use 'terraform plan' before using 'terraform apply' to verify components

#  Deploy Application Service
`terraform apply`

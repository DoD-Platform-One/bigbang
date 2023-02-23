# Deployment steps


### Prerequisites
- [aws cli](https://aws.amazon.com/cli/)
- aws account

### Process
1. Create a .zip file of project
   - zip must be named the same as the function name
     2. for a directory
        - `zip -r -j <AWS_LAMBDA_FUNC_NAME>.zip <PROJECT_DIR>`

2. Deploy via aws cli lambda command
   - `aws lambda update-function-code --function-name <AWS_LAMBDA_FUNC_NAME> --zip-file fileb://<AWS_LAMBDA_FUNC_NAME>.zip`


### NPM Script

`npm run deploy` Runs the predeployment step of building the app then creates a zip of the build directory.  Then runs the deploy step using the aws lambda update-function-code command which pushes the zip file to aws.

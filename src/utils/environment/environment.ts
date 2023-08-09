import fs from 'fs'
import {warn, error, info, success} from '../console.js'
import { checkAWSConnection, getProjectMapFile, saveProjectMapFile } from './aws.js'

// example .env file
// GITHUB_WEBHOOK_SECRET=number
// GITLAB_WEBHOOK_SECRET=number
// GITLAB_USERNAME=string
// GITLAB_PASSWORD=string
// SMEE=string
// PORT=number
// ENVIRONMENT=development
// NODE_ENV=development

const checkBaseEnv = () => {
    if (!process.env.GITHUB_WEBHOOK_SECRET) {
        const message = "process.env.GITHUB_WEBHOOK_SECRET is not defined, app will fail during runtime"
        error(message)
    }
    if (!process.env.GITLAB_WEBHOOK_SECRET) {
        const message = "process.env.GITLAB_WEBHOOK_SECRET is not defined, app will fail during runtime"
        error(message)
    }
    if (!process.env.GITLAB_PASSWORD) {
        const message = "process.env.GITLAB_PASSWORD is not defined, app will fail during runtime"
        error(message)
    }
}

const checkAWSVariables = () => {
//     region: process.env.AWS_REGION,
//     accessKeyId: process.env.AWS_ACCESS_KEY_ID,
//     secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    if (!process.env.AWS_REGION) {
        const message = "process.env.AWS_REGION is not defined, app will fail during runtime"
        error(message)
    }
    if(!process.env.AWS_ACCESS_KEY_ID) {
        const message = "process.env.AWS_ACCESS_KEY_ID is not defined, app will fail during runtime"
        error(message)
    }
    if(!process.env.AWS_SECRET_ACCESS_KEY) {
        const message = "process.env.AWS_SECRET_ACCESS_KEY is not defined, app will fail during runtime"
        error(message)
    }

    // check for project_map.json in s3
    if (!process.env.AWS_BUCKET) {
        const message = "process.env.AWS_BUCKET is not defined Persistent storage will not be available"
        error(message)
    }
}

const checkDevEnv = () => {
    if (!process.env.SMEE) {
        const message = "process.env.SMEE is not defined, app will fail to communicate with gitlab and github during development"
        warn(message)
    }
}

const checkFiles = async () => {
    let init = false
    if (process.env.ENVIRONMENT == "development") {
        // check for assets/project_map_dev.json
        if (!fs.existsSync("./src/assets/project_map_dev.json")) {
            // create assets/project_map_dev.json
            info("creating assets/project_map_dev.json")
            fs.writeFileSync("./src/assets/project_map_dev.json", JSON.stringify({}))
            init = true
        }
    }else 
        if (!fs.existsSync("./src/assets/project_map.json")) {
            info("File does not exist locally checking AWS S3")
            try{
                await getProjectMapFile()
                success("project mapping file found in S3")
            }catch(err){
                warn(err.message)
                await saveProjectMapFile(JSON.stringify({}))
                success("Project mapping file created in S3 bucket")
                init = true
            }

            // if(!fs.existsSync("./src/assets/project_map.json")){
            //     // create assets/project_map.json
            //     info("creating assets/project_map.json")
            //     fs.writeFileSync("./src/assets/project_map.json", JSON.stringify({}))
            //     init = true
            // }
        }
    return init
    }


export const checkEnv = async () => {
    checkBaseEnv()
    if (!process.env.ENVIRONMENT) {
        info("process.env.ENVIRONMENT is not defined, unexpected behavior may occur")
    }
    
    if (process.env.NODE_ENV === "development" || process.env.ENVIRONMENT === "development") {
        checkDevEnv()
    }

    if (!process.env.NODE_ENV || process.env.NODE_ENV == "development") {
        info("process.env.NODE_ENV is not defined, this build includes development assets")
    }

    if(process.env.ENVIRONMENT === "production"){
        checkAWSVariables()
        await checkAWSConnection()
    }
    await checkFiles()
}
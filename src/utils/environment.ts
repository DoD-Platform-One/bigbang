import fs from 'fs'
import {warn, error, info} from './console.js'

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

const checkDevEnv = () => {
    if (!process.env.SMEE) {
        const message = "process.env.SMEE is not defined, app will fail to communicate with gitlab and github during development"
        warn(message)
    }
}

const checkFiles = () => {
    if (process.env.ENVIRONMENT == "development") {
        // check for assets/project_map_dev.json
        if (!fs.existsSync("./src/assets/project_map_dev.json")) {
            // create assets/project_map_dev.json
            info("creating assets/project_map_dev.json")
            fs.writeFileSync("./src/assets/project_map_dev.json", JSON.stringify({}))
        }
    }else 
        if (!fs.existsSync("./src/assets/project_map.json")) {
            // create assets/project_map.json
            info("creating assets/project_map.json")
            fs.writeFileSync("./src/assets/project_map.json", JSON.stringify({}))
        }
    }


export const checkEnv = () => {
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
    checkFiles()
}
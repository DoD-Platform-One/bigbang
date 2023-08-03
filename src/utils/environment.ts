import fs from 'fs'

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
        throw new Error("GITHUB_WEBHOOK_SECRET is not defined")
    }
    if (!process.env.GITLAB_WEBHOOK_SECRET) {
        throw new Error("GITLAB_WEBHOOK_SECRET is not defined")
    }
    if (!process.env.GITLAB_USERNAME) {
        throw new Error("GITLAB_USERNAME is not defined")
    }
    if (!process.env.GITLAB_PASSWORD) {
        throw new Error("GITLAB_PASSWORD is not defined")
    }
}

const checkDevEnv = () => {
    if (!process.env.SMEE) {
        throw new Error("SMEE is not defined")
    }
}

const checkFiles = () => {
    if (process.env.NODE_ENV == "development" || process.env.ENVIRONMENT == "development") {
        // check for assets/project_map_dev.json
        if (!fs.existsSync("./src/assets/project_map_dev.json")) {
            // create assets/project_map_dev.json
            fs.writeFileSync("./src/assets/project_map_dev.json", JSON.stringify({}))
        }
    }else if (process.env.NODE_ENV == "production" || process.env.ENVIRONMENT == "production") {
        // check for assets/project_map.json
        if (!fs.existsSync("./src/assets/project_map.json")) {
            // create assets/project_map.json
            fs.writeFileSync("./src/assets/project_map.json", JSON.stringify({}))
        }
    }
}

export const checkEnv = () => {
    checkBaseEnv()
    if (process.env.NODE_ENV == "development" || process.env.ENVIRONMENT == "development") {
        checkDevEnv()
    }
    checkFiles()
}
import Path from 'path'
import fs from 'fs'
import {ExecSyncOptions, execSync} from 'child_process'
import dotenv from "dotenv"

dotenv.config()

const GITLAB_USERNAME = process.env.GITLAB_USERNAME
const GITLAB_PASSWORD = process.env.GITLAB_PASSWORD

export const setUpLogin = (opt: ExecSyncOptions) => {
    execSync(`git config credential.username ${GITLAB_USERNAME}`, opt)
    execSync(`git config core.askPass ${GITLAB_PASSWORD}`, opt)
    execSync('git config credential.helper cache', opt)
}

export const getPath = (projectName: string) => {
    
    return Path.join("tmp", projectName)
}

export const cloneUrl =  async (url: string, projectName: string) => {
    const path = getPath(projectName)
    if(fs.existsSync(path)){
        execSync(`rm -rf ${path}`)
    }
    await execSync(`git clone ${url} ${path}`)
}
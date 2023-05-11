import Path from 'path'
import fs from 'fs'
import {execSync, exec} from 'child_process'
import dotenv from "dotenv"

dotenv.config()

const GITLAB_USERNAME = process.env.GITLAB_USERNAME
const GITLAB_PASSWORD = process.env.GITLAB_PASSWORD

const setUpLogin = () => {
    execSync(`git config --global credential.username ${GITLAB_USERNAME}`)
    execSync(`git config --global core.askPass ${GITLAB_PASSWORD}`)
    execSync('git config --global credential.helper cache')
}

const getPath = (projectName: string) => Path.join("temp", projectName)

const gitClean = (projectName: string) => {
    const path = getPath(projectName)
    fs.rmdirSync(path)
}

const cloneUrl =  async (url: string, projectName: string) => {
    // https://repo1.dso.mil/snekcode/bounty-board.git
    const path = getPath(projectName)
    if(!fs.existsSync(path)){
        fs.mkdirSync(path, { recursive: true })
    }
    await exec(`git clone ${url} ${path}`, {cwd: "../"})
}

console.log(GITLAB_USERNAME);

setUpLogin()
cloneUrl("https://repo1.dso.mil/snekcode/test.git", "test")
gitClean('test')
console.log(gitClean);


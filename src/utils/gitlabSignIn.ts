import Path from 'path'
import fs from 'fs'
import {execSync} from 'child_process'

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
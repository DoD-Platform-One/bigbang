import fs from 'fs'
import { getProjectMapFile, saveProjectMapFile } from '../utils/environment/aws.js'
import { info } from '../utils/console.js'

//verify project_map.json matches the interface
export interface IProject {
    gitlab: {
        defaultBranch: string,
        projectId: number,
        url: string,
        requests: {
            [key: number]: IRequestMap
        }
    },
    github: {
        defaultBranch: string,
        projectId: number,
        appId: number,
        installationId: number,
        cloneUrl: string,
        apiUrl: string,
        requests: {
            [key: number]: IRequestMap
        }
    },
}

export interface IRequestMap {
    reciprocalNumber: number,
    reciprocalBranch: string,
}


export interface IMapping {
    [key: string]: IProject
}


const writeProjectMapFile = (filePathBase: string, fileName: string, file: string) =>{
    if(!fs.existsSync(`${filePathBase}${fileName}`)){
        fs.writeFileSync(`${filePathBase}${fileName}`, file, "utf8")
    }
}


// if in the future we need more than just "Projects" in the mapping we can update the definition of the ^ Mapping
//if .env ENVIRONMENT variable is set to "development" then use the development mapping file called project_map_dev.json else use project_map.json
// mappingFilePath if Environment is production
export let mappingFileName = 'project_map_dev.json'
export const mappingFilePath = './src/assets/'
// mappingFilePath if Environment is testing
if (process.env.ENVIRONMENT === "test") {
    mappingFileName = 'project_map_test.json'
}
if (process.env.ENVIRONMENT === "production") {
    mappingFileName = 'project_map_prod.json'
}

const mappingFile =  () => fs.readFileSync(mappingFilePath+mappingFileName, 'utf8')
let mapping: IMapping;
const useS3: boolean = process.env.USE_S3 === 'true' ? true : false;
info("USE_S3: " + useS3);

if (useS3 && process.env.ENVIRONMENT !== 'test'){
    getProjectMapFile(mappingFilePath,mappingFileName).then(() => {
        mapping = JSON.parse(mappingFile())
    })
}
// fail case to create a new mapping file
if (!mapping) {
    writeProjectMapFile(mappingFilePath, mappingFileName, JSON.stringify({}))
    mapping = JSON.parse(mappingFile())
}


//parse the mapping file into a JSON object 

interface IMappingContext {
    projectName: string,
    gitHubIssueNumber: number,
    gitLabMergeRequestNumber: number,
    gitLabProjectId: number,
    gitLabProjectUrl: string,
    gitLabDefaultBranch: string,
    gitLabSourceBranch: string,
    gitHubProjectId: number,
    gitHubApiUrl: string,
    gitHubCloneUrl: string,
    gitHubDefaultBranch: string,
    gitHubSourceBranch: string,
    installationID: number,
    appID: number
}

// clean up time

export const UpdateConfigMapping = async (context: IMappingContext) => {
    // Object destructure the context
    const {projectName, gitHubDefaultBranch, gitHubSourceBranch, gitHubIssueNumber, gitHubProjectId, gitHubApiUrl, gitHubCloneUrl: gitHubGitUrl, gitLabDefaultBranch, gitLabSourceBranch, gitLabMergeRequestNumber, gitLabProjectId, gitLabProjectUrl} = context
    
    // if the project already exists in the mapping, add the new merge request and issue number to the mapping
    if (mapping[projectName]) {
        mapping[projectName].github.requests[gitHubIssueNumber] = {reciprocalNumber: gitLabMergeRequestNumber, reciprocalBranch: gitLabSourceBranch}
        mapping[projectName].gitlab.requests[gitLabMergeRequestNumber] = {reciprocalNumber: gitHubIssueNumber, reciprocalBranch: gitHubSourceBranch}
    } 
    // if the project does not exist in the mapping, create a new project in the mapping
    else {
        mapping[projectName] = {
            gitlab: {
                defaultBranch: gitLabDefaultBranch,
                projectId:gitLabProjectId, 
                url: gitLabProjectUrl, 
                requests: {
                    [gitLabMergeRequestNumber]: {reciprocalNumber: gitHubIssueNumber, reciprocalBranch: gitHubSourceBranch} 
                },
            },
            github: {
                defaultBranch: gitHubDefaultBranch, 
                projectId: gitHubProjectId, 
                appId: context.appID,
                installationId: context.installationID,
                cloneUrl: gitHubGitUrl,
                apiUrl: gitHubApiUrl,
                requests: {
                    [gitHubIssueNumber]: {reciprocalNumber: gitLabMergeRequestNumber, reciprocalBranch: gitLabSourceBranch}
                },
            }
        }
    }
    fs.writeFileSync(mappingFilePath+mappingFileName, JSON.stringify(mapping, null, 2)) // idk what 2 does lol
    if(process.env.ENVIRONMENT === "production" || process.env.USE_S3){
        await saveProjectMapFile(JSON.stringify(mapping, null, 2), mappingFilePath, mappingFileName)
    }
    return true
}


// NOTE: Add a function that gets the respective merge request or issue number from the mapping
export const GetUpstreamRequestFor = (projectName: string, issueNumber: number) => {
    return mapping[projectName].github.requests[issueNumber]
}

export const GetDownstreamRequestFor = (projectName: string, mergeRequestNumber: number) => {
    return mapping[projectName].gitlab.requests[mergeRequestNumber]
}

export const GetMapping = () => {
    mapping = JSON.parse(mappingFile())
    return mapping
}
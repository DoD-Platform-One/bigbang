import fs from 'fs'
//verify project_map.json matches the interface
export interface IProject {
    gitlab: {
        defaultBranch: string,
        projectID: number,
        url: string,
        requests: {
            [key: number]: IRequestMap
        }
    },
    github: {
        defaultBranch: string,
        projectID: number,
        appID: number,
        installationID: number,
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

// if in the future we need more than just "Projects" in the mapping we can update the definition of the ^ Mapping
//if .env ENVIRONMENT variable is set to "development" then use the development mapping file called project_map_dev.json else use project_map.json
// mappingFilePath if Environment is production
let mappingFilePath = './src/assets/project_map.json'
if (process.env.ENVIRONMENT === "development") {
    mappingFilePath = './src/assets/project_map_dev.json'
}
// mappingFilePath if Environment is testing
if (process.env.ENVIRONMENT === "test") {
    mappingFilePath = './test/fixtures/project_map_test.json'
}
const mappingFile = () => fs.readFileSync(mappingFilePath, 'utf8')


//parse the mapping file into a JSON object 
let mapping: IMapping = JSON.parse(mappingFile())







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

export const UpdateConfigMapping = (context: IMappingContext) => {
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
                projectID:gitLabProjectId, 
                url: gitLabProjectUrl, 
                requests: {
                    [gitLabMergeRequestNumber]: {reciprocalNumber: gitHubIssueNumber, reciprocalBranch: gitHubSourceBranch} 
                },
            },
            github: {
                defaultBranch: gitHubDefaultBranch, 
                projectID: gitHubProjectId, 
                appID: context.appID,
                installationID: context.installationID,
                cloneUrl: gitHubGitUrl,
                apiUrl: gitHubApiUrl,
                requests: {
                    [gitHubIssueNumber]: {reciprocalNumber: gitLabMergeRequestNumber, reciprocalBranch: gitLabSourceBranch}
                },
            }
        }
    }

    // lets write it back to the disk
    fs.writeFileSync(mappingFilePath, JSON.stringify(mapping, null, 2)) // idk what 2 does lol
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
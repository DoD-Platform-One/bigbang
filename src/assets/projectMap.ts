import fs from 'fs'

interface IProject {
    gitlab: {
        default_branch: string,
        id: number,
        url: string,
        requests: {
            [key: number]: number
        }
    },
    github: {
        default_branch: string,
        id: number,
        url: string,
        requests: {
            [key: number]: number
        }
    },
}

interface IMapping {
    [key: string]: IProject
}

// if in the future we need more than just "Projects" in the mapping we can update the definition of the ^ Mapping

const mappingFile = fs.readFileSync('./src/assets/project_map.json', 'utf8')
const mapping: IMapping = JSON.parse(mappingFile)


interface IMappingContext {
    projectName: string,
    gitHubIssueNumber: number,
    gitLabMergeRequestNumber: number,
    gitLabProjectId: number,
    gitLabProjectUrl: string,
    gitLabDefaultBranch: string,
    gitHubProjectId: number,
    gitHubProjectUrl: string,
    gitHubDefaultBranch: string,
}

// clean up time

export const UpdateConfigMapping = (context: IMappingContext) => {
    // Object destructure the context
    const {projectName, gitHubDefaultBranch, gitHubIssueNumber, gitHubProjectId, gitHubProjectUrl, gitLabDefaultBranch, gitLabMergeRequestNumber, gitLabProjectId, gitLabProjectUrl} = context
    
    // if the project already exists in the mapping, add the new merge request and issue number to the mapping
    if (mapping[projectName]) {
        mapping[projectName].github.requests[gitHubIssueNumber] = gitLabMergeRequestNumber
        mapping[projectName].gitlab.requests[gitLabMergeRequestNumber] = gitHubIssueNumber
    } 
    // if the project does not exist in the mapping, create a new project in the mapping
    else {
        mapping[projectName] = {
            gitlab: {
                default_branch: gitLabDefaultBranch, 
                id:gitLabProjectId, 
                url: gitLabProjectUrl, 
                requests: {
                    [gitLabMergeRequestNumber]: gitHubIssueNumber
                },
            },
            github: {
                default_branch: gitHubDefaultBranch, 
                id: gitHubProjectId, 
                url: gitHubProjectUrl, 
                requests: {
                    [gitHubIssueNumber]: gitLabMergeRequestNumber
                },
            }
        }
    }

    // lets write it back to the disk
    fs.writeFileSync('./src/assets/project_map.json', JSON.stringify(mapping, null, 2)) // idk what 2 does lol
}


// NOTE: Add a function that gets the respective merge request or issue number from the mapping
export const GetUpstreamRequestNumber = (projectName: string, issueNumber: number) => {
    return mapping[projectName].github.requests[issueNumber]
}

export const GetDownstreamRequestNumber = (projectName: string, mergeRequestNumber: number) => {
    return mapping[projectName].gitlab.requests[mergeRequestNumber]
}

export const GetMapping = () => {
    return mapping
}
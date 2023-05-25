import { execSync } from 'child_process'
import {onGitHubEvent} from './eventManager'
import axios from 'axios'
import {signPayloadJWT} from '../appcrypto'

import dotenv from 'dotenv'
import { UpdateConfigMapping } from '../assets/projectMap'
dotenv.config();
  
onGitHubEvent('pull_request.opened', async ({payload, appID}) => {
        const PRNumber = payload.pull_request.number
        
        // repo one bot steps
        const github_url = payload.repository.clone_url
        
        // TODO Figure out how to get repo 1 git url
        const repo_1_url = payload.repository.homepage
        
        const currentWorkingDirectory = `../tmp/${payload.repository.name}`
        const execOptions = {cwd: currentWorkingDirectory}

        // clone github repo
        execSync(`git clone ${github_url} ${currentWorkingDirectory}`)
        
        // create remote mirror
        // TODO: what if theres no .git?

        execSync(`git remote add mirror ${repo_1_url}`, execOptions)
  
        // get PR number
        // make a new branch off the PR ref
        console.log(`fetching ref for PR-${PRNumber}`)      
        execSync(`git fetch origin pull/${PRNumber}/head:PR-${PRNumber}`,execOptions)
  
        //check out branch
        console.log("checking out branch")
        execSync(`git checkout PR-${PRNumber}`, execOptions)
  
        // git push mirror {DESIRED_BRANCH_NAME}
        console.log("pushing to mirror")
       
        //create active session downstream
        execSync(`git config --global credential.username ${process.env.GITLAB_USERNAME}`) 
        execSync(`git config --global core.askPass ${process.env.GITLAB_PASSWORD}`)
        execSync(`git config --global credential.helper cache`) 

        execSync(`git push mirror PR-${PRNumber}`, execOptions)
        
        // clean up tmp/repo name folder
        execSync(`rm -rf ${currentWorkingDirectory}`)

        // get Repo1 project id number
  
        // 1. Webscrape using the repo1 url using regex to find ProjectID: \d*
        // const ProjectID = execSync(`curl ${repo_1_url} | grep "Project ID: \d*" | awk "{print $3}"`)

        const webpage = await axios.get(repo_1_url)
        const ProjectID = webpage.data.match(/Project ID: \d*/)[0].split(" ")[2]

        //print Project ID
        console.log(`"project ID" ${ProjectID}`);

        // get Repo1 default branch name


        const repo1Project = await axios.get(`https://repo1.dso.mil/api/v4/projects/${ProjectID}`)

        //console log out repo1 project data name
        console.log(repo1Project.data.default_branch);
        const defaultBranchName = repo1Project.data.default_branch

        // create Merge Request in gitlab
        // execSync(`\
        // curl --request POST --header \
        // "PRIVATE-TOKEN: ${process.env.GITLAB_PASSWORD}" \
        // "https://repo1.dso.mil/api/v4/projects/${ProjectID}/merge_requests?source_branch=PR-${PRNumber}&target_branch=${defaultBranchName}&title=PR-${PRNumber}&remove_source_branch=true&squash=true" \
        // `)
        const createMergeRequestURL = `https://repo1.dso.mil/api/v4/projects/${ProjectID}/merge_requests?source_branch=PR-${PRNumber}&target_branch=${defaultBranchName}&title=PR-${PRNumber}&remove_source_branch=true&squash=true`
           
        //verify merge request created upstream
        const response = await axios.post(createMergeRequestURL, undefined, {headers : {"PRIVATE-TOKEN" :process.env.GITLAB_PASSWORD}});
        

        console.log(response.data.web_url)

        // i need an app installation access token for creating a comment on a pull request
        // body that defines the scope of the access token
        // TODO make the access token process a function
        const access_token_request_body = JSON.stringify({
            repository: payload.repository.name,
            permissions:{issues:"write", pull_requests: "write"}})

        const installationId = payload.installation.id
        const jwt = await signPayloadJWT(appID)
        // --header "Accept: application/vnd.github+json"
        const access_token_request = await axios.post(
            `https://api.github.com/app/installations/${installationId}/access_tokens`, 
            access_token_request_body, 
            {
                headers : {Authorization : `Bearer ${jwt}`,
                            Accept : "application/vnd.github+json"
                        }
            })
        
        const comment = "Merge Request Created: " + response.data.web_url
        const body = {
            "body": comment
        }
        // generate jwt token for comment
        // send comment to github pr request
        
        await axios.post(payload.pull_request.comments_url, body, {headers : {"Authorization" : `Bearer ${access_token_request.data.token}`}});

        console.log(`comment posted to github PR ${payload.pull_request.comments_url}`);
        
        // update config mapping for new MR and PR relationship 
        UpdateConfigMapping({
            projectName: payload.repository.name,
            gitHubDefaultBranch: payload.repository.default_branch,
            gitHubIssueNumber: payload.number,
            gitHubProjectId: payload.repository.id,
            gitHubProjectUrl: payload.repository.url,
            // gitlab v
            gitLabMergeRequestNumber: response.data.iid,
            gitLabProjectId: ProjectID,
            gitLabProjectUrl: repo1Project.data.web_url,
            gitLabDefaultBranch: defaultBranchName
        })
    })
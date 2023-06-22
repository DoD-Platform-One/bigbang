import { ExecSyncOptions, execSync } from 'child_process'
import {onGitHubEvent} from './eventManager'
import axios from 'axios'
import {cloneUrl} from '../utils/gitlabSignIn'

import dotenv from 'dotenv'
import { UpdateConfigMapping } from '../assets/projectMap'
dotenv.config();

onGitHubEvent('pull_request.opened', async (context) => {
        const {payload, appID, installationID, projectName} = context
        const PRNumber = payload.pull_request.number
        // repo one bot steps
        const github_url = payload.repository.clone_url
        
        const currentWorkingDirectory = `./tmp/${projectName}`
        const execOptions: ExecSyncOptions = {cwd: currentWorkingDirectory}

        // clone github repo
        cloneUrl(github_url, projectName)
        // create remote mirror
        // repo1 url set up with username and access token embedded
        const repo_1_url = payload.repository.homepage.replace('https://', `https://${process.env.GITLAB_USERNAME}:${process.env.GITLAB_PASSWORD}@`)
        execSync(`git remote add mirror ${repo_1_url}`, execOptions)
        
        // get PR number
        // make a new branch off the PR ref
        
        execSync(`git fetch origin pull/${PRNumber}/head:PR-${PRNumber}`,execOptions)
        
        //check out branch
        execSync(`git checkout PR-${PRNumber}`, execOptions)
        
        execSync(`git push mirror PR-${PRNumber}`, execOptions)
        
        // clean up tmp/repo name folder
        execSync(`rm -rf ${currentWorkingDirectory}`)

        // get Repo1 project id number
  
        // TODO check mapping for project id before webscrapping
        // 1. Webscrape using the repo1 url using regex to find ProjectID: \d*
        const webpage = await axios.get(repo_1_url)
        const ProjectID = webpage.data.match(/Project ID: \d*/)[0].split(" ")[2]

        // webscrapping takes a long time.  Check project mapping first for project name

        // get Repo1 default branch name

        const repo1Project = await axios.get(`https://repo1.dso.mil/api/v4/projects/${ProjectID}`)
        const defaultBranchName = repo1Project.data.default_branch

        // create Merge Request in gitlab
        const createMergeRequestURL = `https://repo1.dso.mil/api/v4/projects/${ProjectID}/merge_requests?source_branch=PR-${PRNumber}&target_branch=${defaultBranchName}&title=PR-${PRNumber}&remove_source_branch=true&squash=true`
        const response = await axios.post(createMergeRequestURL, undefined, {headers : {"PRIVATE-TOKEN" :process.env.GITLAB_PASSWORD}});
   
        const comment = "Merge Request Created: " + response.data.web_url
        const body = {
            "body": comment
        }
        
        await axios.post(payload.pull_request.comments_url, body, {headers : {"Authorization" : `Bearer ${context.gitHubAccessToken}`}});

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
            gitLabDefaultBranch: defaultBranchName,
            appID: appID,
            installationID: installationID
        })
    })
import { execSync } from 'child_process'
import {onGitHubEvent} from './eventManager'
import axios from 'axios'

import dotenv from 'dotenv'
dotenv.config();
  
onGitHubEvent('pull_request.opened', async (payload) => {
        const PRNumber = payload.pull_request.number
        // if(context.isBot){
        //   return
        // }
        
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
        execSync(`git push mirror PR-${PRNumber}`, execOptions)
        
        // clean up tmp/repo name folder
        execSync(`rm -rf ${currentWorkingDirectory}`)

        // get Repo1 project id number
  
        // 1. Webscrape using the repo1 url using regex to find ProjectID: \d*
        // const ProjectID = execSync(`curl ${repo_1_url} | grep "Project ID: \d*" | awk "{print $3}"`)

        const webpage = await axios.get(repo_1_url)
        const ProjectID = webpage.data.match(/Project ID: \d*/)[0].split(" ")[2]

        // get Repo1 default branch name
        const repo1Project = await axios.get(`https://repo1.dso.mil/api/v4/projects/${ProjectID}`)
        const defaultBranchName = repo1Project.data.default_branch

        // create Merge Request in gitlab
        execSync(`\
        curl --request POST --header \
        "PRIVATE-TOKEN: ${process.env.GITLAB_PASSWORD}" \
        "https://repo1.dso.mil/api/v4/projects/${ProjectID}/merge_requests?source_branch=PR-${PRNumber}&target_branch=${defaultBranchName}&title=PR-${PRNumber}&remove_source_branch=true&squash=true" \
        `)

        // get Repo 1 pipeline URL
        console.log(`fetching pipeline for Project ${ProjectID}`)
        const response = await axios.get(`https://repo1.dso.mil/api/v4/projects/${ProjectID}/repository/commits/PR-${PRNumber}`)
        
        console.log(response.data.last_pipeline.web_url);
        
        // // console.log(response)
        // let issueComment = undefined
        // if(response.data.last_pipeline){
        //   issueComment = context.issue({ body: response.data.last_pipeline.web_url })
        // }else{
        //   issueComment = context.issue({ body: "There was an error retrieving the pipeline" })
        // }
        
        // context.octokit.issues.createComment(issueComment)
    })
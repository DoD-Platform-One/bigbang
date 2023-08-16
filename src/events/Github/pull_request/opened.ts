import axios from "axios"
import { ExecSyncOptions, execSync } from "child_process"
import { onGitHubEvent } from "../../../EventManager/eventManagerTypes.js"
import { UpdateConfigMapping } from "../../../assets/projectMap.js"
import GitError from "../../../errors/GitError.js"
import RequestError from "../../../errors/RequestError.js"
import { cloneUrl } from "../../../utils/gitlabSignIn.js"

onGitHubEvent('pull_request.opened', async (context) => {
    const {payload, appId: appID, installationId: installationID, projectName, next} = context
    const PRNumber = payload.pull_request.number
    // repo one bot steps
    const github_url = payload.repository.clone_url
    
    const currentWorkingDirectory = `./tmp/${projectName}`
    const execOptions: ExecSyncOptions = {cwd: currentWorkingDirectory}
    const repo_1_url = payload.repository.homepage.replace('https://', `https://${process.env.GITLAB_USERNAME}:${process.env.GITLAB_PASSWORD}@`)
    try {
        // clone github repo
        cloneUrl(github_url, projectName)
        // create remote mirror
        // repo1 url set up with username and access token embedded
        execSync(`git remote add mirror ${repo_1_url}`, execOptions)
        
        // get PR number
        // make a new branch off the PR ref
        
        execSync(`git fetch origin pull/${PRNumber}/head:PR-${PRNumber}`,execOptions)
        
        //check out branch
        execSync(`git checkout PR-${PRNumber}`, execOptions)
        
        execSync(`git push mirror PR-${PRNumber}`, execOptions)
        
        // clean up tmp/repo name folder
        execSync(`rm -rf ${currentWorkingDirectory}`)
    }catch(error){
        return next(new GitError(error.message))
    }

    // get Repo1 project id number
    
    // TODO check mapping for project id before webscrapping
    // 1. Webscrape using the repo1 url using regex to find ProjectID: \d*
    const webpage = await axios.get(repo_1_url)
    const ProjectID = webpage.data.match(/Project ID: \d*/)[0].split(" ")[2]
    
    // webscrapping takes a long time.  Check project mapping first for project name

    // get Repo1 default branch name

    const repo1Project = await axios.get(`https://repo1.dso.mil/api/v4/projects/${ProjectID}`)
    const defaultBranchName = repo1Project.data.default_branch

    const cautionMessage = `# This Merge Request is associated with A [GitHub PR](${payload.pull_request.html_url}) \n\n ### Please Use caution before running the pipeline.` 
    if (payload.pull_request.body){
        // double up on \n for markdown
        payload.pull_request.body = cautionMessage + '\n\n<hr/>\n' + payload.pull_request.body.replace('\n', '\n\n')
    }else{
        payload.pull_request.body = cautionMessage
    }

    // create Merge Request in gitlab
    const createMergeRequestURL = `https://repo1.dso.mil/api/v4/projects/${ProjectID}/merge_requests`
    let response;
    try{
        response = await axios.post(createMergeRequestURL, 
            {
                "source_branch": `PR-${PRNumber}`,
                "target_branch": defaultBranchName,
                "title": `PR-${PRNumber}`,
                "remove_source_branch": true,
                "squash": true,
                "description": payload.pull_request.body
            }, 
            {headers : {"PRIVATE-TOKEN" :process.env.GITLAB_PASSWORD}});
            
    } catch (error) {
        return next(new RequestError(error.response.data.message, error.response.status))
    }
    
    // update config mapping for new MR and PR relationship
    await UpdateConfigMapping({
        projectName: payload.repository.name,
        gitHubDefaultBranch: payload.repository.default_branch,
        gitHubSourceBranch: payload.pull_request.head.ref,
        gitHubIssueNumber: payload.number,
        gitHubProjectId: payload.repository.id,
        gitHubApiUrl: payload.repository.url,
        gitHubCloneUrl: payload.repository.clone_url,
        githubPullRequestCloneUrl: payload.pull_request.head.repo.clone_url,
        // gitlab v
        gitLabMergeRequestNumber: response.data.iid,
        gitLabProjectId: ProjectID,
        gitLabProjectUrl: repo1Project.data.web_url,
        gitLabDefaultBranch: defaultBranchName,
        gitLabSourceBranch: `PR-${PRNumber}`,
        appID: appID,
        installationID: installationID
    })

    // comment back to github
    const disclaimerMessage = `# Thank You! \n\n Your contribution to the DSO Repo1 has been mirrored to ${response.data.web_url} \n\n ### Current features  \n\n 1. Comments will be mirrored to the associated GitLab Merge Request.  \n 1. Quote Replies will mirror to Gitlab as a Thread \n 1. Updates to code will be pushed to the associated GitLab Merge Request.  \n 1. Closing the PR will close the associated GitLab Merge Request. \n\n ### Features not available yet \n\n 1. Comments on code will not be mirrored`

    // const comment = "Merge Request Created: " + response.data.web_url
    const body = {
        "body": disclaimerMessage
    }
    try {
        await axios.post(payload.pull_request.comments_url, body, {headers : {"Authorization" : `Bearer ${context.gitHubAccessToken}`}});
    } catch (error) {
        return next(new RequestError(error.response.data.message, error.response.status))
    }


})
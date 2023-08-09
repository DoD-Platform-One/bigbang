import axios from "axios";
import { ExecSyncOptions, execSync } from "child_process";
import { onGitHubEvent } from "../../../EventManager/eventManagerTypes.js";
import { cloneUrl } from "../../../utils/gitlabSignIn.js";

////create on github when Pull request is synchronized
onGitHubEvent('pull_request.synchronize', async (context) => {
    const {payload, projectName, isBot} = context

    if (isBot) {
        context.response.status(403);
        return context.response.send("Bot comment detected, ignoring");
      }
    
    const PRNumber = payload.pull_request.number
    // repo one bot steps
    const github_url = payload.repository.clone_url
    
    const currentWorkingDirectory = `./tmp/${projectName}`
    const execOptions: ExecSyncOptions = {cwd: currentWorkingDirectory}

    // clone github repo
    cloneUrl(github_url, projectName)
    // create remote mirror
    // repo1 url set up with username and access token embedded
    const repo_1_url = context.mapping.gitlab.url.replace('https://', `https://${process.env.GITLAB_USERNAME}:${process.env.GITLAB_PASSWORD}@`)
    execSync(`git remote add mirror ${repo_1_url}`, execOptions)
    
    // get PR number
    // make a new branch off the PR ref
    
    execSync(`git fetch origin pull/${PRNumber}/head:PR-${PRNumber}`,execOptions)
    
    //check out branch
    execSync(`git checkout PR-${PRNumber}`, execOptions)
    
    execSync(`git push mirror PR-${PRNumber} --force`, execOptions)
    
    // clean up tmp/repo name folder
    execSync(`rm -rf ${currentWorkingDirectory}`)

    const comment = `Merge Request synchronized with commit ${payload.pull_request.html_url}/commits/${payload.pull_request.head.sha}` 
    const body = {
        "body": comment
    }
    
    await axios.post(payload.pull_request.comments_url, body, {headers : {"Authorization" : `Bearer ${context.gitHubAccessToken}`}});

    return context.response.send("OK");

})
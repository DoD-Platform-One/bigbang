import axios from "axios";
import { GetDownstreamRequestFor } from "../assets/projectMap.js";
import { onGitLabEvent } from "../EventManager/eventManagerTypes.js";
import MappingError from "../errors/MappingError.js";
import { ExecSyncOptions, execSync } from "child_process";
import { cloneUrl } from "../utils/gitlabSignIn.js";

// PR close in Github when MR is closed in Gitlab
onGitLabEvent('merge_request.close', async (context) => {
    const {projectName, payload, isBot, next} = context
    const MRNumber = payload.object_attributes.iid
    let requestMap;
    try{
        requestMap = GetDownstreamRequestFor(projectName, MRNumber)
    }catch {    
        return next(
            new MappingError(`Project ${projectName} does not exist in the mapping`)
          );
    }
  
    if (isBot) {
      context.response.status(403);
      return context.response.send("Bot comment detected, ignoring");
    }
  
    // PR closed to github
    await axios.patch(
        `${context.mapping.github.apiUrl}/issues/${requestMap.reciprocalNumber}`,
        {state: "closed"},
        {headers : {"Authorization" : `Bearer ${context.gitHubAccessToken}`}}
        );
    return context.response.send("OK");
  })


  onGitLabEvent('merge_request.update', ({mapping, gitHubAccessToken, payload, projectName, isBot, response}) => {

    if (isBot) {
      response.status(403);
      return response.send("Bot comment detected, ignoring");
    }

    const currentWorkingDirectory = `./tmp/${projectName}`
    const execOptions: ExecSyncOptions = {cwd: currentWorkingDirectory}
    // push code update to github

    // cloning the repo from repo 1
    cloneUrl(mapping.gitlab.url, projectName)
    // add remote to github
    // create url with embedded token
    const githubCloneUrl = mapping.github.cloneUrl.replace('https://', `https://username:${gitHubAccessToken}@`)
    const reciprocalBranch = mapping.gitlab.requests[payload.object_attributes.iid].reciprocalBranch
    execSync(`git remote add github ${githubCloneUrl}`, execOptions)

    execSync(`git checkout ${payload.object_attributes.source_branch}`, execOptions)
    
    if(mapping.github.defaultBranch === reciprocalBranch){
      execSync(`git checkout ${reciprocalBranch}`, execOptions)
    }else{
      execSync(`git checkout -b ${reciprocalBranch}`, execOptions)
    }

    // push with force to github
    execSync(`git push github --force`, execOptions)

    // delete the repo
    execSync(`rm -rf ${currentWorkingDirectory}`, execOptions)

    // post comment back to gitlab
    axios.post(
        `https://repo1.dso.mil/api/v4/projects/${mapping.gitlab.projectId}/merge_requests/${payload.object_attributes.iid}/notes`,
        {body: `Pushed to ${reciprocalBranch} branch in Github`},
        { headers: { "PRIVATE-TOKEN": process.env.GITLAB_PASSWORD } }
    )

    return response.send("OK");
  })
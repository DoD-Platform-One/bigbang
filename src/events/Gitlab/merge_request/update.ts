
import axios from "axios";
import { ExecSyncOptions, execSync } from "child_process";
import { onGitLabEvent } from "../../../EventManager/eventManagerTypes.js";
import { cloneUrl } from "../../../utils/gitlabSignIn.js";

onGitLabEvent('merge_request.update', ({mapping, gitHubAccessToken, payload, projectName, isBot, response, requestNumber}) => {

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
    const githubCloneUrl = mapping.gitlab.requests[requestNumber].reciprocalCloneUrl.replace('https://', `https://username:${gitHubAccessToken}@`)
    const reciprocalBranch = mapping.gitlab.requests[payload.object_attributes.iid].reciprocalBranch
    const githubBranch = mapping.gitlab.requests[payload.object_attributes.iid].reciprocalBranch
    execSync(`git remote add github ${githubCloneUrl}`, execOptions)

    execSync(`git checkout ${payload.object_attributes.source_branch}`, execOptions)
    // push with force to github
    execSync(`git push github HEAD:${githubBranch} --force`, execOptions)

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

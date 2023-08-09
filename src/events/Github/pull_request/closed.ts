import axios from "axios";
import { onGitHubEvent } from "../../../EventManager/eventManagerTypes.js";
import { GetUpstreamRequestFor } from "../../../assets/projectMap.js";
import MappingError from "../../../errors/MappingError.js";

onGitHubEvent('pull_request.closed', async (context) => {
    const {projectName, payload, isBot, next} = context

    if (isBot) {
      context.response.status(403);
      return context.response.send("Bot comment detected, ignoring");
    }

    const PRNumber = payload.pull_request.number;
    let requestMap;
    try {
        requestMap = GetUpstreamRequestFor(projectName, PRNumber)
    }catch {
        return next(
            new MappingError(`Project ${projectName} does not exist in the mapping`)
          );
    }
    //MR closed to gitlab
    await axios.put(
        `https://repo1.dso.mil/api/v4/projects/${context.mapping.gitlab.projectId}/merge_requests/${requestMap.reciprocalNumber}`,
         {state_event: "close"}, 
        {headers : {"PRIVATE-TOKEN" :process.env.GITLAB_PASSWORD}}
        );

    return context.response.send("OK");
})
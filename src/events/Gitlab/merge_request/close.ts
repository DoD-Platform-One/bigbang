import axios from "axios";
import { GetDownstreamRequestFor } from "../../../assets/projectMap.js";
import { onGitLabEvent } from "../../../EventManager/eventManagerTypes.js";
import MappingError from "../../../errors/MappingError.js";

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
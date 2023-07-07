import axios from "axios";
import { GetDownstreamRequestNumber } from "../assets/projectMap.js";
import { onGitLabEvent } from "./eventManagerTypes.js";
import MappingError from "../errors/MappingError.js";

// PR close in Github when MR is closed in Gitlab
onGitLabEvent('merge_request.closed', async (context) => {
    const {projectName, payload, isBot, next} = context
    const MRNumber = payload.object_attributes.iid
    let downstreamRequestNumber;
    try{
        downstreamRequestNumber = GetDownstreamRequestNumber(projectName, MRNumber)
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
        `${context.mapping.github.url}/issues/${downstreamRequestNumber}`,
        {state: "closed"},
        {headers : {"Authorization" : `Bearer ${context.gitHubAccessToken}`}}
        );
    return context.response.send("OK");
  })
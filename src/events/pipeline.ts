import axios from "axios";
import dotenv from "dotenv";
import {
  GetDownstreamRequestFor,
  } from "../assets/projectMap.js";
import {onGitLabEvent} from "./eventManagerTypes.js";
dotenv.config();

// Create function gitlab pipeline comment 
async function createGitlabPipelineComment(
  PRNumber: number,
  pipelineId: number,
  gitlabUrl: string,
  gitHubUrl: string,
  gitHubAccessToken: string
) {
  const pipelineUrl = `${gitlabUrl}/-/pipelines/${pipelineId}`;
  const GithubPipelineComment = `Pipeline is running at ${pipelineUrl}`;
  await axios.post(`${gitHubUrl}/issues/${PRNumber}/comments`,
    { body: GithubPipelineComment },
    { headers: { Authorization: `Bearer ${gitHubAccessToken}` } }
  );
}
  // Create comments with pipeline url link on github when pipeline is created on gitlab
onGitLabEvent("pipeline.running", async (context) => { 
  const payload = context.payload;
  const mapping = context.mapping;
  const pipelineId = payload.object_attributes.id;
  const gitlabUrl = mapping.gitlab.url;
  const gitHubUrl = mapping.github.apiUrl;
  const requestMap = GetDownstreamRequestFor(
    context.projectName,
    payload.merge_request.iid
  );
  
  await createGitlabPipelineComment(
    requestMap.reciprocalNumber,
    pipelineId,
    gitlabUrl,
    gitHubUrl,
    context.gitHubAccessToken
  );

  context.response.status(200);
  return context.response.send("Reply posted to github");
});
 


 
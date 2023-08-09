import { onGitLabEvent } from "../../../EventManager/eventManagerTypes.js";
import { GetDownstreamRequestFor } from "../../../assets/projectMap.js";
import MappingError from "../../../errors/MappingError.js";
import { gitlabNoteReaction, createGithubComment, updateGitLabNoteWithMirrorLink } from "../../utils/comment.js";

onGitLabEvent("note.created", async (context) => {
  const { projectName, payload, isBot, userName, next } = context;

  if (isBot) {
    context.response.status(403);
    return context.response.send("Bot comment detected, ignoring");
  }

  const noteId = payload.object_attributes.id;

  // //create variable for payload merge_request number
  const MRNumber = payload.merge_request.iid;

  //get downstream request number
  let requestMap;
  try{
    requestMap = GetDownstreamRequestFor(
      projectName,
      MRNumber
    );
  } catch {
    gitlabNoteReaction(
      400,
      noteId,
      payload.project.id,
      MRNumber
    )
    return next(
      new MappingError(`Project ${projectName} does not exist in the mapping`)
    );
  }

  //create variable for projectID
  const projectID = payload.project.id;

  // create variable for comment bod to be posted to github
  const comment = `#### ${userName} [commented](${payload.object_attributes.url}): <hr> \n\n  ${payload.object_attributes.note}`;

  const response = await createGithubComment(
    context.mapping.github.apiUrl,
    requestMap.reciprocalNumber,
    comment,
    context.gitHubAccessToken
  );

  //verify response is ok and post emoji to gitlab comment
  gitlabNoteReaction(response.status, noteId, projectID, MRNumber);

  // edit the gitlab comment to include a link to the github comment
  // https://github.com/SnekCode/podinfo/pull/24#issuecomment-1613471346
  await updateGitLabNoteWithMirrorLink(
    response.data.html_url,
    payload.object_attributes.note,
    projectID,
    MRNumber,
    noteId
  );
  context.response.status(200);
  return context.response.send("OK");
});
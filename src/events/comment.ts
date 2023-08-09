import axios from "axios";
import dotenv from "dotenv";
import {
  GetDownstreamRequestFor,
  GetUpstreamRequestFor,
  IRequestMap,
} from "../assets/projectMap.js";
import MappingError from "../errors/MappingError.js";
import { getDiscussionId } from "../queries/discussion.js";
import githubReplyParser from "../utils/githubReply.js";
import gitlabReplyParser from "../utils/gitlabReply.js";
import { onGitHubEvent, onGitLabEvent } from "./eventManagerTypes.js";
import GithubCommentError from "../errors/GithubCommentError.js";
dotenv.config();

///////////////////////////////
// GITHUB
///////////////////////////////

onGitHubEvent("issue_comment.created", async (context) => {
  const { payload, mapping, projectName, next, isBot, userName, requestNumber: PRNumber } = context;
  //create variable for issue number

  //verify comment is not from a bot and end process if it is
  if (isBot) {
    context.response.status(403);
    return context.response.send("Bot comment detected, ignoring");
  }

  let requestMap: IRequestMap;
  
  try{
     requestMap = GetUpstreamRequestFor(projectName, PRNumber);
  }catch{
    return next(new GithubCommentError(``, payload.comment.url, context.gitHubAccessToken))
  }

  const [isReply, noteId, strippedComment] = githubReplyParser(
    payload.comment.body
  );

  const githubCommentUrl = payload.comment.html_url;
  let response;

  // this structure set up the comment to look like
  // GitHub Comment Mirrored Here(<link>)<hr/>
  // #### <username> commented: <hr/>
  //<comment>
  const githubComment = `[Github Comment Mirrored Here](${githubCommentUrl})`;
  const commentBy = `#### ${userName} [commented](${githubCommentUrl}): <hr/>\n\n`;
  const editedGitlabComment = `${githubComment}\r\n${commentBy}`;

  // get reciprocal number
  const MRNumber = requestMap?.reciprocalNumber;
  if (!MRNumber) {
    return next(
      new MappingError(`Project ${projectName} does not exist in the mapping`)
    );
  }

  if (isReply && noteId) {
    // the top link is used to back reference replies to the original comment
    response = await createGitlabReply(
      noteId,
      editedGitlabComment + strippedComment,
      mapping.gitlab.projectId,
      MRNumber
    );
  } else {
    // axios post to gitlab api to create a comment on the merge request, using auth header with gitlab token
    response = await createGitlabComment(
      editedGitlabComment + payload.comment.body,
      mapping.gitlab.projectId,
      MRNumber
    );
  }

  // axios post to github api to add an emoji to the comment sent to this event handler.
  githubCommentReaction(
    response.status,
    payload.comment.url,
    context.gitHubAccessToken
  );

  // edit the github comment to include a link to the gitlab comment if the comment is not a reply to another comment

  if (isReply) {
    context.response.status(200);
    return context.response.send("Reply detected, ignoring");
  }

  // e.g https://repo1.dso.mil/snekcode/podinfo/-/merge_requests/24#note_1374700
  // This is needed to enable the reply to comment feature
  //comment: string, noteId: string, MRNumber: string, gitlabUrl: string, gitHubUrl: string, gitHubAccessToken: string

  updateGitHubCommentWithMirrorLink(
    payload.comment.body,
    response.data.id,
    requestMap.reciprocalNumber,
    mapping.gitlab.url,
    payload.comment.url,
    context.gitHubAccessToken
  );
  context.response.status(200);
  return context.response.send("Comment created");
});

//
//
//
//
//
//
//

//
//
//
//
//
//
//

///////////////////////////////
// GITLAB / REPO1
///////////////////////////////

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

//
//
//
//
//
//
//
//

//
//
//
//
//
//
//

//
//
//
//
//
//
//

onGitLabEvent("note.reply", async (context) => {
  const { mapping, payload, isBot, userName } = context;

  if (isBot) {
    context.response.status(403);
    return context.response.send("Bot comment detected, ignoring");
  }
  const originalComment = payload.object_attributes.note;
  // get the discussion id from the object attributes
  const discussionId = payload.object_attributes.discussion_id;
  // get the MR number from payload
  const MRNumber = payload.merge_request.iid;
  // get top level note from the discussion
  const discussion = await getGitlabDiscussion(
    mapping.gitlab.projectId,
    MRNumber,
    discussionId
  );

  // get number of notes in the discussion
  const numberOfNotes = discussion.data.notes.length;
  // get the previous note in the discussion
  const previousNote = discussion.data.notes[numberOfNotes - 2].body;
  
  // get the issuecomment id from the top level note's embedded link
  const [isReply, githubIssueCommentId] = gitlabReplyParser(previousNote);

  // if the top level note is not a reply, return
  if (!isReply && !githubIssueCommentId) {
    gitlabNoteReaction(
      500,
      payload.object_attributes.id,
      mapping.gitlab.projectId,
      MRNumber
    );
    context.response.status(400);
    context.response.send("Top level note is not a reply, ignoring");
    return context.next();
  }

  // get the issuecomment value from the github api
  // add > to the beginning of each line to make it a quote
  const issueCommentResponse = await axios.get(
    `${context.mapping.github.apiUrl}/issues/comments/${githubIssueCommentId}`,
    { headers: { Authorization: `Bearer ${context.gitHubAccessToken}` } }
  );
  const issueComment = issueCommentResponse.data;

  const quote = issueComment.body
    .split("\n")
    .map((line: string) => `> ${line}`)
    .join("\n");

  // create the comment to be posted to gitlab
  const githubComment = `${quote}\n\n#### ${userName} [replied](${payload.object_attributes.url}) <hr> \n\n ${originalComment}`;

  // post the comment to github
  const githubResponse = await axios.post(
    `${issueComment.issue_url}/comments`,
    { body: githubComment },
    { headers: { Authorization: `Bearer ${context.gitHubAccessToken}` } }
  );

  updateGitLabNoteWithMirrorLink(
    githubResponse.data.html_url,
    originalComment,
    mapping.gitlab.projectId,
    MRNumber,
    payload.object_attributes.id
  );

  context.response.status(200);
  return context.response.send("Reply posted to github");
});

//
//
//
//
//
//
//

//
//
//
//
//
//
//

///////////////////////////////
// HELPER FUNCTIONS
///////////////////////////////

async function getGitlabDiscussion(
  projectId: number,
  MRNumber: number | string,
  discussionId: number | string
) {
  return await axios.get(
    `https://repo1.dso.mil/api/v4/projects/${projectId}/merge_requests/${MRNumber}/discussions/${discussionId}`,
    { headers: { "PRIVATE-TOKEN": process.env.GITLAB_PASSWORD } }
  );
}

async function updateGitLabNoteWithMirrorLink(
  gitHubUrl: string,
  comment: string,
  projectID: number,
  MRNumber: number,
  noteId: number | string
) {
  const githubComment = `[Github Comment Mirrored Here](${gitHubUrl})`;
  const editedGitlabComment = `${githubComment}<hr/>${comment}`;
  await axios.put(
    `https://repo1.dso.mil/api/v4/projects/${projectID}/merge_requests/${MRNumber}/notes/${noteId}`,
    { body: editedGitlabComment },
    { headers: { "PRIVATE-TOKEN": process.env.GITLAB_PASSWORD } }
  );
}

async function createGithubComment(
  githubUrl: string,
  downstreamRequestNumber: number,
  comment: string,
  gitHubAccessToken: string
) {
  return await axios.post(
    `${githubUrl}/issues/${downstreamRequestNumber}/comments`,
    { body: comment },
    { headers: { Authorization: `Bearer ${gitHubAccessToken}` } }
  );
}

export async function gitlabNoteReaction(
  status: number,
  noteId: number,
  projectID: number,
  MRNumber: number
) {
  const emoji = status === 201 ? "thumbsup" : "thumbsdown";

  ///projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
  await axios.post(
    `https://repo1.dso.mil/api/v4/projects/${projectID}/merge_requests/${MRNumber}/notes/${noteId}/award_emoji`,
    { name: emoji },
    { headers: { "PRIVATE-TOKEN": process.env.GITLAB_PASSWORD } }
  );
}

export async function githubCommentReaction(
  status: number,
  url: string,
  gitHubAccessToken: string
) {
  const emoji = status === 201 ? "+1" : "-1";
  const body = {
    content: emoji,
  };
  await axios.post(url + "/reactions", body, {
    headers: { Authorization: `Bearer ${gitHubAccessToken}` },
  });
}

async function createGitlabReply(
  noteId: string,
  comment: string,
  projectId: number,
  MRNumber: number
) {
  const discussionId = await getDiscussionId(noteId);
  return axios.post(
    `https://repo1.dso.mil/api/v4/projects/${projectId}/merge_requests/${MRNumber}/discussions/${discussionId}/notes`,
    { body: comment },
    { headers: { "PRIVATE-TOKEN": process.env.GITLAB_PASSWORD } }
  );
}

async function createGitlabComment(
  comment: string,
  projectId: number,
  MRNumber: number,
) {
  return await axios.post(
    `https://repo1.dso.mil/api/v4/projects/${projectId}/merge_requests/${MRNumber}/notes`,
    { body: comment },
    { headers: { "PRIVATE-TOKEN": process.env.GITLAB_PASSWORD } }
  );
}
async function updateGitHubCommentWithMirrorLink(
  comment: string,
  noteId: string,
  MRNumber: number,
  gitlabUrl: string,
  gitHubUrl: string,
  gitHubAccessToken: string
) {
  const gitlabLink = `[Gitlab Comment Mirrored Here](${gitlabUrl}/-/merge_requests/${MRNumber}#note_${noteId})`;
  const editedGithubComment = `${gitlabLink}<hr/>\r\n${comment}`;
  return axios.patch(
    gitHubUrl,
    { body: editedGithubComment },
    { headers: { Authorization: `Bearer ${gitHubAccessToken}` } }
  );
  }
 

 
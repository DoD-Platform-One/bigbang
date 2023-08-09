import axios from "axios";
import { onGitLabEvent } from "../../../EventManager/eventManagerTypes.js";
import gitlabReplyParser from "../../utils/gitlabReply.js";
import { getGitlabDiscussion, gitlabNoteReaction, updateGitLabNoteWithMirrorLink } from "../../utils/comment.js";

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
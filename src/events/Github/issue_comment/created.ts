import { onGitHubEvent } from "../../../EventManager/eventManagerTypes.js";
import { IRequestMap, GetUpstreamRequestFor } from "../../../assets/projectMap.js";
import GithubCommentError from "../../../errors/GithubCommentError.js";
import MappingError from "../../../errors/MappingError.js";
import githubReplyParser from "../../utils/githubReply.js";
import { createGitlabReply, createGitlabComment, updateGitHubCommentWithMirrorLink, githubCommentReaction } from "../../utils/comment.js";


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
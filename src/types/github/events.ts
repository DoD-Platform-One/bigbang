import { IssueCommentPayload, PullRequestPayload,PullRequestSyncPayload } from "./objects.js";

export type IssueCommentCreated = IssueCommentPayload & {
  type: "issue_comment.created";
};
export type IssueCommentDeleted = IssueCommentPayload & {
  type: "issue_comment.deleted";
};
export type PullRequestOpen = PullRequestPayload & {
  type: "pull_request.opened";
};
// pull_request.closed
export type PullRequestClosed = PullRequestPayload & {
  type: "pull_request.closed";
};

//create esport type for github push
export type PullRequestSync = PullRequestSyncPayload & {
  type: "pull_request.synchronize";
};


export type GitHubEventTypes =
  | IssueCommentCreated
  | IssueCommentDeleted
  | PullRequestOpen
  | PullRequestClosed
  | PullRequestSync;

export type GitHubEventMap = {
  [E in GitHubEventTypes["type"]]: Extract<GitHubEventTypes, { type: E }>;
};
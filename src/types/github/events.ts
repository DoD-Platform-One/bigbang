import { IssueCommentPayload, PullRequestPayload } from "./objects.js";

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

export type GitHubEventTypes =
  | IssueCommentCreated
  | IssueCommentDeleted
  | PullRequestOpen
  | PullRequestClosed

export type GitHubEventMap = {
  [E in GitHubEventTypes["type"]]: Extract<GitHubEventTypes, { type: E }>;
};
import { MergeRequest, NoteMergeRequest, Push, Pipeline } from "./objects.js";

export type NoteReply = NoteMergeRequest & { type: "note.reply" };
export type NoteCreated = NoteMergeRequest & { type: "note.created" };
export type MergeRequestOpened = MergeRequest & {
  type: "merge_request.opened";
};
export type MergeRequestClosed = MergeRequest & {
  type: "merge_request.closed";
};
export type MergeRequestUpdate = MergeRequest & {
  type: "merge_request.update";
};
export type PushEvent = Push & { type: "push" };
export type PipelineEvent = Pipeline & { type: "pipeline.running" };

export type GitlabEventTypes =
  | NoteReply
  | NoteCreated
  | MergeRequestOpened
  | MergeRequestClosed
  | PushEvent
  | PipelineEvent;

export type GithLabEventMap = {
  [E in GitlabEventTypes["type"]]: Extract<GitlabEventTypes, { type: E }>;
};

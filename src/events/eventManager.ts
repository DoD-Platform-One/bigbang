import { IncomingHttpHeaders } from "http";
import { GetMapping } from "../assets/projectMap.js";
import { getGitHubAppAccessToken } from "../appcrypto.js";
import { NextFunction, Request, Response } from "express";
import {
  IEventContextObject,
  emitter,
  PayloadType,
  EventMap,
  onGitHubEvent,
  onGitLabEvent
} from "./eventManagerTypes.js";
import { MergeRequest, Push } from "../types/gitlab/objects.js";
import { PullRequestPayload } from "../types/github/objects.js";
import { gitlabNoteReaction } from "./comment.js";
import { GitHubEventTypes, PullRequestOpen } from "../types/github/events.js";
import { NoteCreated, NoteReply, GitlabEventTypes, PushEvent } from "../types/gitlab/events.js";

export {onGitHubEvent, onGitLabEvent}

export async function createContext(
  headers: IncomingHttpHeaders,
  payload: PayloadType,
  response: Response,
  next: NextFunction
): Promise<IEventContextObject> {
  const state = {} as IEventContextObject;
  state["payload"] = payload as never;
  state["response"] = response;
  state["next"] = next;

  for (const key in headers) {
    if (key.toLowerCase() === "x-github-event") {
      state["instance"] = "github";
      const event = headers[key];
      const action = (payload as PullRequestPayload).action;
      const appID = headers["x-github-hook-installation-target-id"] as string;
      isGitHubBot(payload as GitHubEventTypes, state);

      state["installationID"] = (payload as PullRequestOpen).installation.id;
      state["appID"] = +appID;
      state["event"] = `${event}.${action}` as keyof EventMap;
      state["projectName"] = payload.repository.name.toLowerCase();

      state["mapping"] = GetMapping()[state.projectName];

      console.log("This is a Github event", state.event);
      break;
    }

    //
    //
    //
    // Gitlab Events
    //
    //

    if (key.toLowerCase() === "x-gitlab-event") {
      state["instance"] = "gitlab";
      const event = (payload as NoteCreated).object_kind;
      let action =
        (payload as Push).action ??
        (payload as MergeRequest)?.object_attributes?.state ??
        (payload as NoteReply)?.object_attributes?.type ??
        undefined;
      isGitlabBot(payload as GitlabEventTypes, state);

      // rules for notes
      if (event === "note" && !action) {
        action = "created";
      }
      if (
        event === "note" &&
        (payload as NoteCreated)?.object_attributes?.type === "Note"
      ) {
        action = "created";
      }

      if (
        event === "note" &&
        (payload as NoteReply)?.object_attributes?.type === "DiscussionNote"
      ) {
        action = "reply";
      }

      if (action) {
        state["event"] = `${event}.${action}` as keyof EventMap;
      } else {
        state["event"] = event as keyof EventMap;
      }

      // check for project attribute on payload
      if ((payload as MergeRequest).project) {
        state["projectName"] = (
          payload as MergeRequest
        ).project.name.toLowerCase();
      } else if (payload.repository) {
        state["projectName"] = payload.repository.name.toLowerCase();
      }

      state["mapping"] = GetMapping()[state.projectName];

      try {
        state["appID"] = state.mapping.github.appID;
        state["installationID"] = state.mapping.github.installationID;
      } catch {
        console.log("Gitlab Project Name Not in Config Map");
        state["isFailed"] = true;
        return state;
      }
      // don't care about bots
      if (state.isBot) {
        break;
      }
      console.log("This is a GitLab event", state.event);
      break;
    }
  }

  state["gitHubAccessToken"] = await getGitHubAppAccessToken(
    state.appID,
    state.projectName,
    state.installationID
  );

  return state;
}

export const emitEvent = async (
  req: Request,
  res: Response,
  next: NextFunction
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
): Promise<any> => {
  const context = await createContext(req.headers, req.body, res, next);

  if (context.isFailed) {
    if (context.event === "note.created" || context.event === "note.reply") {
      const note = context.payload as NoteCreated;
      gitlabNoteReaction(
        400,
        note.object_attributes.id,
        note.project_id,
        note.merge_request.iid
      );
    }
    res.status(400);
    return res.send("Invalid Event");
  }

  const event = context.event;
  emitter.emit(event, context);
};



// helper functions

function isGitlabBot(payload: GitlabEventTypes, state: IEventContextObject) {
  const userName =
    (payload as MergeRequest)?.user?.username ??
    (payload as PushEvent)?.user_username;

  state["isBot"] = userName.includes("_bot");
  state["userName"] = userName;
}

function isGitHubBot(payload: GitHubEventTypes, state: IEventContextObject) {
  const userType = payload.sender.type;
  const userName = payload.sender.login;
  state["isBot"] = userType === "Bot";
  state["userName"] = userName;
}

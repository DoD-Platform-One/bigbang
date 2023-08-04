/* eslint-disable @typescript-eslint/no-unused-vars */

import { IncomingHttpHeaders } from "http";
import { success } from "../utils/console.js";
import { getGitHubAppAccessToken } from "../crypto/appcrypto.js";
import { NextFunction, Request, Response } from "express";
import {
  IEventContextObject,
  InstanceConfig,
  emitter,
  PayloadType,
  EventMap,
  onGitHubEvent,
  onGitLabEvent,
  eventNames,
} from "./eventManagerTypes.js";
import { NoteCreated } from "../types/gitlab/events.js";
import yaml from "js-yaml";
import fs from "fs";
import { GetMapping } from "../assets/projectMap.js";
import GitlabNoteError from "../errors/GitlabNoteError.js";
import MappingError from "../errors/MappingError.js";
import NotImplementedError from "../errors/NotImplementedError.js";
import RepoSyncError from "../errors/RepoSyncError.js";
export { onGitHubEvent, onGitLabEvent };

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

  const config: InstanceConfig = yaml.load(
    fs.readFileSync("./src/events/event_config.yml", "utf8")
  ) as InstanceConfig;
  // is event gitlab or github
  // this also serves as a entry boundary
  let instance: "github" | "gitlab" = undefined;
  if (headers["x-gitlab-event"]) {
    instance = "gitlab";
  } else if (headers["x-github-event"]) {
    instance = "github";
  } else {
    state.error = new NotImplementedError("Service Not Implemented");
    return state;
  }

  state["instance"] = instance;
  const event = (headers["x-gitlab-event"] ??
    headers["x-github-event"]) as string;
  state["event"] = event as keyof EventMap;
  const instanceConfig = config[instance][event];
  // check if event incoming is in config
  if (!instanceConfig) {
    state.error = new NotImplementedError(`Event Not Configured: ${instance} : ${event}`);
    return state
  }

  for (const property in instanceConfig.payload_property_mapping) {
    // @ts-expect-error difficult to define a type here since it is generic.
    const thing = instanceConfig.payload_property_mapping[property].split(".").reduce((acc, key) => acc[key], payload) as string;
    // @ts-expect-error we can do this because we know the type of thing
    state[property] = thing;
  }

  if (instanceConfig.action_mapping) {
    state["action"] = instanceConfig["action_mapping"][state["action"]];
  }

  if (instance === "github") {
    state["appId"] = +headers["x-github-hook-installation-target-id"];
  }

  // set state name to lowercase
  state["projectName"] = state["projectName"].toLowerCase();
  state["mapping"] = GetMapping()[state.projectName];

  if (instance === "gitlab") {
    try {
      state["appId"] = state.mapping.github.appId;
      state["installationId"] = state.mapping.github.installationId;
    } catch {
      if(state.event === "note"){
        state.error =new GitlabNoteError("Project Not in Config Map", (state.payload)as NoteCreated)
        return state
      }
      state.error = new MappingError("Project Not in Config Map");
    }
  }

  // bot check
  if(!instanceConfig.allow_bot){
    isUserNameBot(state);
  } else {
    state["isBot"] = false;
  }

  if (!state.installationId) {
    state.error = new RepoSyncError("MalFormed Data Error")
    return state;
  }

  state["gitHubAccessToken"] = await getGitHubAppAccessToken(
    state.appId,
    state.projectName,
    state.installationId
  );

  state.eventName = `${state.event}.${state.action}` as keyof EventMap;
  // add .bot to the end of event name if isBot is true
  if (state.isBot) {
    state.eventName = `${state.eventName}.bot` as keyof EventMap;
  }

  return state;
}

export const emitEvent = async (
  req: Request,
  res: Response,
  next: NextFunction
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
): Promise<any> => {
  const context = await createContext(req.headers, req.body, res, next);
  
  if (context.error){
    return next(context.error)
  }

  if(projectMapCheck(context)){
    return next(context.error)
  }


  if (eventNames.includes(context.eventName)) {
    success(`${context.instance} : ${context.eventName}`);
  } else {
    return next(new NotImplementedError(`Event Not Registered: ${context.instance} : ${context.eventName}`))
  }

  emitter.emit(context.eventName, context);
};

function projectMapCheck(context: IEventContextObject) {
  //only github pull_request.open can skip this config map check
  if (context.event === "pull_request.opened") {
    return false
  }

  // requestMap.reciprocalNumber undefined check
  // step one check if event name is of a request type
  if (!context.mapping[context.instance].requests[context.requestNumber]) {
    context.error = new MappingError("Request Number Not in Config Map");
    return true
  }

  return false
}

// helper functions

function isUserNameBot(state: IEventContextObject) {
  const isGitHubBot = state.userName.includes("[bot]");
  const isGitLabBot = state.userName.includes("_bot");
  state["isBot"] = isGitHubBot || isGitLabBot;
}
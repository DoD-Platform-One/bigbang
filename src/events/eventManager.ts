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
  eventNames,
} from "./eventManagerTypes.js";
import yaml from "js-yaml";
import fs from "fs";
import { GetMapping } from "../assets/projectMap.js";
import NotImplementedError from "../errors/NotImplementedError.js";
import RepoSyncError from "../errors/RepoSyncError.js";
import ContextCreationError from "../errors/ContextCreationError.js";

//////////////////////
// Context Creation //
//////////////////////

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

  for (const header in headers) {
    if(header.toLowerCase() === "x-github-event"){
      state["event"] = (headers[header] as string)
      state["instance"] = "github"
    }
    
    if(header.toLowerCase() === "x-gitlab-event") {
      state["event"] = (headers[header] as string)
      state["instance"] = "gitlab"
    }
  }

  const instance = state["instance"];
  const event = state["event"];

  if(!state['instance']){
    state.error = new NotImplementedError("Service Not Implemented");
    return state;
  }

  const eventConfig = config[instance][event];
  // check if event incoming is in config
  if (!eventConfig) {
    state.error = new NotImplementedError(
      `Event Not Configured: ${instance} : ${event}`
    );
    return state;
  }

  // map over all the defined property routes in the instanceConfig
  for (const property in eventConfig.payload_property_mapping) {
    // @ts-expect-error difficult to define a type here since it is generic.
    const value = eventConfig.payload_property_mapping[property].split(".").reduce((acc, key) => acc[key], payload) as string;
    // @ts-expect-error we can do this because we know the type of thing
    state[property] = value;
  }

  // some events have a action mapping which is an object keyed by some value mapped to an action name that makes more sense
  // e.g note.DiscussionNote => note.reply
  if (eventConfig.action_mapping) {
    state["action"] = eventConfig["action_mapping"][state["action"]];
  }

  state.eventName = `${state.event}.${state.action}` as keyof EventMap;

  if (instance === "github") {
    state["appId"] = +headers["x-github-hook-installation-target-id"];
  }

  // set state name to lowercase
  state["projectName"] = state["projectName"].toLowerCase();

  state["mapping"] = GetMapping()[state.projectName];

  // can init is an array of strings e.g ['opened'] set a boolean if the event's action is in the array
  if (eventConfig.canInit) {
    state["canInit"] = eventConfig.canInit.includes(state.action);
  }else{
    state["canInit"] = false;
  }

  if (!state.mapping && !state.canInit) {
    state.error = new ContextCreationError(
      `Project Not in Config Map: ${state.instance}/${state.projectName}`,
      state.instance,
      state.event,
      state.payload,
      state.appId,
      state.installationId
    );
    return state;
  }

  if (instance === "gitlab") {
    try {
      state["appId"] = state.mapping.github.appId;
      state["installationId"] = state.mapping.github.installationId;
    } catch {
      state.error = new ContextCreationError(
        `Project Not in Config Map: ${state.instance}/${state.projectName}`,
        state.instance,
        state.event,
        state.payload
      );
    }
  }

  // bot check
  if (!eventConfig.allow_bot) {
    isUserNameBot(state);
  } else {
    state["isBot"] = false;
  }

  if (!state.installationId) {
    state.error = new RepoSyncError(
      `Malformed Data Error: ${state.instance}/${state.projectName} : ${state.eventName}`
    );
    return state;
  }

  try {
    state["gitHubAccessToken"] = await getGitHubAppAccessToken(
      state.appId,
      state.projectName,
      state.installationId
    );
  } catch {
    state.error = new RepoSyncError(
      `Gitlab Token Request Error: ${state.instance}/${state.projectName} : ${state.eventName}`
    );
    return state;
  }

  // add .bot to the end of event name if isBot is true
  if (state.isBot) {
    state.eventName = `${state.eventName}.bot` as keyof EventMap;
  }

  return state;
}

//////////////////////
// Event Management //
//////////////////////

export const emitEvent = async (
  req: Request,
  res: Response,
  next: NextFunction
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
): Promise<any> => {
  let context: IEventContextObject;
  try {
    context = await createContext(req.headers, req.body, res, next);
  }catch(err){
    return next(err)
  }

  if (context.error) {
    return next(context.error);
  }

  if (eventNames.includes(context.eventName)) {
    success(`${context.instance} : ${context.eventName}`);
  } else {
    return next(
      new NotImplementedError(
        `Event Not Registered: ${context.instance} : ${context.eventName}`
      )
    );
  }

  emitter.emit(context.eventName, context);
  return true
};

// helper functions

function isUserNameBot(state: IEventContextObject) {
  const isGitHubBot = state.userName.includes("[bot]");
  const isGitLabBot = state.userName.includes("_bot");
  state["isBot"] = isGitHubBot || isGitLabBot;
}

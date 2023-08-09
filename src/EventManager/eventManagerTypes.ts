import EventEmitter from "events";
import { IProject } from "../assets/projectMap.js";
import { NextFunction, Response } from "express";
import { GitHubEventMap, GitHubEventTypes } from "../types/github/events.js";
import { GitLabEventMap, GitlabEventTypes } from "../types/gitlab/events.js";
import RepoSyncError from "../errors/RepoSyncError.js";

type AllEventTypes = GitlabEventTypes | GitHubEventTypes;

export type EventMap = {
  [E in AllEventTypes["type"]]: Extract<AllEventTypes, { type: E }>;
};

export type PayloadType = EventMap[AllEventTypes["type"]];

export interface IEventContextObject<T extends AllEventTypes = AllEventTypes> {
  instance: "github" | "gitlab";
  event: string
  action: string
  eventName: T["type"]
  payload: EventMap[T["type"]];
  appId?: number;
  requestNumber: number;
  installationId?: number;
  mapping: IProject;
  projectName: string;
  gitHubAccessToken: string;
  response: Response;
  next: NextFunction;
  userName: string;
  isBot: boolean;
  canInit: boolean;
  error: Error
}

interface CustomEventEmitter<
  T extends AllEventTypes,
  E extends EventMap & Record<string, AllEventTypes> = EventMap
> {
  on<K extends keyof E>(
    eventName: K,
    callback: (context: IEventContextObject<E[K]>) => void
  ): void;
  emit(eventName: T["type"], value: IEventContextObject<T>): void;
}

export interface InstanceConfig {
  "github": IEventConfig,
  "gitlab": IEventConfig
}

export interface IEventConfig {
  [key: string]: {
    payload_property_mapping: IPayloadPropertyMapping
    action_mapping?: {
      [key: string]: string
    }
    actions: string[]
    allow_bot?: boolean
    canInit: string[]
  }
}

export interface IPayloadPropertyMapping {
  action: string
  projectName: string
  installationID: string
  requestNumber: string
}

// Example usage:
export const emitter: CustomEventEmitter<AllEventTypes, EventMap> =
  new EventEmitter();

export const eventNames: string[] = []

export const onGitHubEvent = <K extends keyof GitHubEventMap>(
  eventName: K,
  callback: (context: IEventContextObject<GitHubEventMap[K]>) => void
): void => {
  eventNames.push(eventName)

  const errorWrapper = async (context: IEventContextObject<GitHubEventMap[K]>) => {
    try{
      await callback(context)
    }
    catch(err){
      if(err instanceof RepoSyncError){
        return context.next(err)
      }else{
        return context.next(new RepoSyncError(err.message))
      }
    }
  }

  emitter.on(eventName, errorWrapper);
};

export const onGitLabEvent = <K extends keyof GitLabEventMap>(
  eventName: K,
  callback: (context: IEventContextObject<GitLabEventMap[K]>) => void
): void => {
  eventNames.push(eventName)

  const errorWrapper = async (context: IEventContextObject<GitLabEventMap[K]>) => {
    try{
      await callback(context)
    }
    catch(err){
      if(err instanceof RepoSyncError){
        return context.next(err)
      }else{
        return context.next(new RepoSyncError(err.message))
      }
    }
  }

  emitter.on(eventName, errorWrapper);
};

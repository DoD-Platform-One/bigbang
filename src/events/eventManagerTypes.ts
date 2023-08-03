import EventEmitter from "events";
import { IProject } from "../assets/projectMap.js";
import { NextFunction, Response } from "express";
import { GitHubEventMap, GitHubEventTypes } from "../types/github/events.js";
import { GithLabEventMap, GitlabEventTypes } from "../types/gitlab/events.js";

type AllEventTypes = GitlabEventTypes | GitHubEventTypes;

export type EventMap = {
  [E in AllEventTypes["type"]]: Extract<AllEventTypes, { type: E }>;
};

export type PayloadType = EventMap[AllEventTypes["type"]];

export interface IEventContextObject<T extends AllEventTypes = AllEventTypes> {
  instance: "github" | "gitlab";
  event: T["type"];
  payload: EventMap[T["type"]];
  appID?: number;
  requestNumber: number;
  installationID?: number;
  mapping: IProject;
  projectName: string;
  gitHubAccessToken: string;
  response: Response;
  next: NextFunction;
  userName: string;
  isBot: boolean;
  isFailed: boolean;
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

// Example usage:
export const emitter: CustomEventEmitter<AllEventTypes, EventMap> =
  new EventEmitter();


export const eventNames: string[] = []
export const onGitHubEvent = <K extends keyof GitHubEventMap>(
  eventName: K,
  callback: (context: IEventContextObject<GitHubEventMap[K]>) => void
): void => {
  eventNames.push(eventName)
  emitter.on(eventName, callback);
};

export const onGitLabEvent = <K extends keyof GithLabEventMap>(
  eventName: K,
  callback: (context: IEventContextObject<GithLabEventMap[K]>) => void
): void => {
  eventNames.push(eventName)
  emitter.on(eventName, callback);
};

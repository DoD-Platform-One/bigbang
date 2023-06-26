import EventEmitter from "events";
import { IncomingHttpHeaders } from "http";
import { GetMapping, IProject } from "../assets/projectMap.js";
import { getGitHubAppAccessToken } from "../appcrypto.js";

// using node events create a function takes in an expected event and a callback function

export const emitter = new EventEmitter();

// TODO validate these are correct via API docs
type GitHubEvents = "pull_request.opened" | "pull_request.closed" | "issue_comment.created" | "issue_comment.edited" | "issue_comment.deleted";
type GitLabEvents = "note.MergeRequest" | "merge_request.approved" | "merge_request.update" | "merge_request.opened" | "merge_request.closed" | "push" | 'build' | 'pipeline';

export interface IEventContextObject {
    instance: "github" | "gitlab",
    event: GitHubEvents | GitLabEvents,
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    payload: any,
    appID?: number,
    installationID?: number,
    mapping: IProject,
    projectName: string,
    gitHubAccessToken: string
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const createContext = async (headers: IncomingHttpHeaders, payload: any) => {

    const state = {} as IEventContextObject
    state['payload'] = payload

    for (const key in headers) {
        if (key.toLowerCase() === "x-github-event") {
            state["instance"] = "github"
            const event = headers[key]
            const action = payload.action
            const appID = headers['x-github-hook-installation-target-id'] as string;

            state['installationID'] = payload.installation.id
            state['appID'] = +appID
            state['event'] = `${event}.${action}` as GitHubEvents
            state['projectName'] = payload.repository.name.toLowerCase()

            state['mapping'] = GetMapping()[state.projectName]

            console.log("This is a Github event", state.event)
            break
        }

        if (key.toLowerCase() === "x-gitlab-event") {
            state["instance"] = "gitlab"
            const event = payload.object_kind
            const action = payload?.object_attributes?.action ?? payload?.object_attributes?.noteable_type ?? undefined


            if (action){
                state['event'] = `${event}.${action}` as GitLabEvents
            } else {
                state['event'] = event as GitLabEvents
            }

            // check for project attribute on payload
            if (payload.project) {
                state['projectName'] = payload.project.name.toLowerCase()
            } else if (payload.repository) {
                state['projectName'] = payload.repository.name.toLowerCase()
            }

            state['mapping'] = GetMapping()[state.projectName]

            try {
                state['appID'] = state.mapping.github.appID
                state['installationID'] = state.mapping.github.installationID
            } catch {
                console.log("Gitlab Project Name Not in Config Map");
                return undefined
            }

            console.log("This is a GitLab event", state.event)
            break
        }
    }

    state['gitHubAccessToken'] = await getGitHubAppAccessToken(state.appID, state.projectName, state.installationID )

    return state;
}

export const onGitHubEvent = (event: GitHubEvents, callback: (context: IEventContextObject) => void) => {
    emitter.on(event, callback);
}

export const onGitlabEvent = (event: GitLabEvents, callback: (context: IEventContextObject) => void) => {
    emitter.on(event, callback);
}
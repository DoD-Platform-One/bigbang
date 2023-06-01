import EventEmitter from "events";

// using node events create a function takes in an expected event and a callback function

export const emitter = new EventEmitter();

export const parseGitHubEventName = (headers: Record<string, string>, action: string) => {
    for (const key in headers) {
        if (key.toLowerCase() === "x-github-event") {
            const event = headers[key];
            return `${event}.${action}`;
        }
    }
    return "";
}

type GitHubEvents = "pull_request.opened" | "pull_request.closed" | "issue_comment.created" | "issue_comment.edited" | "issue_comment.deleted";
type GitLabEvents = "merge_request.opened" | "merge_request.closed" | "issue_comment.created";
export interface IContext{
    appID:string,
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    payload: any
}


export const onGitHubEvent = (event: GitHubEvents, callback: (context: IContext) => void) => {
    emitter.on(event, callback);
}

export const OnGitlabEvent = (event: GitLabEvents, callback: (context: IContext) => void) => {
    emitter.on(event, callback);
}

export const emitGitHubEvent = (event: string, context: IContext) => {
    emitter.emit(event, context);
}
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

export const onGitHubEvent = (event: GitHubEvents, callback: (context: any) => void) => {
    emitter.on(event, callback);
}

export const OnGitlabEvent = (event: GitLabEvents, callback: (context: any) => void) => {
    emitter.on(event, callback);
}

export const emitGitHubEvent = (event: string, context: any) => {
    emitter.emit(event, context);
}
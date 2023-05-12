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

export const emitGitHubEvent = (event: string, context: any) => {
    emitter.emit(event, context);
}

// NOTES: Possible uses include cross checking the comment author is not a bot and 
// is on the team dictionary list
// and checking the comment body for a command like "/pipes"
export const onIssueCommentCreated = (callback: (context: any) => void) => {
    emitter.on("issue_comment.created", callback);
}

// NOTES: Possible uses include creating a mapping between this PR number and the gitlab MR number
export const onPullRequestOpened = (callback: (context: any) => void) => {
    emitter.on("pull_request.opened", callback);
}

// NOTES: Possible uses include removing the mapping between this PR number and the gitlab MR number
export const onPullRequestClosed = (callback: (context: any) => void) => {
    emitter.on("pull_request.closed", callback);
}

export const on = (event: string, callback: (context: any) => void) => {
    emitter.on(event, callback);
}

## GitHub and Gitlab Event Types

The `github/events.ts` and `gitlab/events.ts` modules defines several types for GitHub and GitLab events such as `IssueCommentCreated` and `NoteCreated`. These types are used to represent a mapping of eventName to payload type.

### Definitions
For the purposes of this documentation, the term `EventTypes` refers to either `GitHubEventTypes` or `GitLabEventTypes`, depending on the context. These types represent a union of all possible event types for their respective platforms.

The term `EventMap` refers to either `GitHubEventMap` or `GitLabEventMap`, depending on the context.


### Type Definitions

Each Type Definition represents the payload of the associated event name e.g: `pull_request.opened`

```typescript
export type PullRequestOpen = PullRequestPayload & {
  type: "pull_request.opened";
};
```

#### EventTypes

Represents a union of all possible GitHub or GitLab event types.

```typescript
export type GitHubEventTypes =
  | IssueCommentCreated
  | IssueCommentDeleted
  | PullRequestOpen;
```
```typescript
export type GitlabEventTypes =
  | NoteReply
  | NoteCreated
  | MergeRequestOpened
  | PushEvent;
```

#### EventMap

Represents a mapping of `GitHubEventTypes` or `GitLabEventTypes` to their corresponding payload types.  This returns the Payload type.

```typescript
export type GitHubEventMap = {
  [E in GitHubEventTypes["type"]]: Extract<GitHubEventTypes, { type: E }>;
};
```

```typescript
export type GithLabEventMap = {
  [E in GitlabEventTypes["type"]]: Extract<GitlabEventTypes, { type: E }>;
};
```

### Adding or Removing a Type

#### Adding
To add or remove an eventName for a specific `eventType`, you can create a new type that extends the existing type with the additional `type` property. For example, to add a new eventName for `new_event`, you can create a new type that extends the appropriate type as follows:

```typescript
export type NewEvent = NewActionType & {
  type: "new_event";
};
```
#### Update EventMapping
If you add a new `eventName`, you should also update the `EventTypes` so the `EventMap` types include the new event type. e.g for `GithubEventTypes`:

```typescript
export type GitHubEventTypes =
  | IssueCommentCreated
  | IssueCommentDeleted
  | PullRequestOpen
  | NewEvent;
```
#### Remove
To remove an event from a `EventMap` simply delete the Type and remove the type from it's respective `EventTypes`
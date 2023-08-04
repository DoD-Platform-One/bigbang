import { githubCommentReaction } from "../events/comment.js";
import RepoSyncError from "./RepoSyncError.js";

class GithubCommentError extends RepoSyncError {

    readonly url
    readonly accessToken
    constructor(message: string, url: string, accessToken: string) {
        super(message);
        this.status = 400
        this.name = "GitError"
        this.url = url
        this.accessToken = accessToken
    }

    public effectFunction() {
        githubCommentReaction(
            400,
            this.url,
            this.accessToken
        )
    }
}

export default GithubCommentError
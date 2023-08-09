
import { gitlabNoteReaction } from "../events/utils/comment.js";
import { NoteCreated } from "../types/gitlab/events.js";
import RepoSyncError from "./RepoSyncError.js";

class GitlabNoteError extends RepoSyncError {

    readonly note
    constructor(message: string, note: NoteCreated) {
        super(message);
        this.status = 400
        this.name = "GitError"
        this.note = note
    }

    public effectFunction() {
        gitlabNoteReaction(
            400,
            this.note.object_attributes.id,
            this.note.project_id,
            this.note.merge_request.iid
          )
    }
}

export default GitlabNoteError
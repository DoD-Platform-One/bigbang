import { PayloadType } from "../events/eventManagerTypes.js";
import RepoSyncError from "./RepoSyncError.js";

class ContextCreationError extends RepoSyncError {
  readonly instance;
  readonly event;
  readonly payload;
  readonly appId;
  readonly installationId;
  constructor(
    message: string,
    instance: string,
    event: string,
    payload: PayloadType,
    appId?: number,
    installationId?: number,
  ) {
    super(message);
    this.status = 400;
    this.name = "ContextCreationError";
    this.instance = instance;
    this.event = event;
    this.payload = payload;
    this.appId = appId;
    this.installationId = installationId;
  }

//   public async effectFunction() {
//     if (this.instance === "gitlab") {
//       if (this.event === "Note Hook" || this.event === "note") {
//         gitlabNoteReaction(
//           400,
//           (this.payload as NoteCreated).object_attributes.id,
//           (this.payload as NoteCreated).project.id,
//           (this.payload as NoteCreated).merge_request.iid
//         );
//       }
//     }

//     if (this.instance === "github") {
//       if (this.event === "issue_comment" && this.appId && this.installationId) {
//         try{

//             const accessToken = await getGitHubAppAccessToken(
//                 this.appId,
//                 (this.payload as IssueCommentCreated).repository.name,
//                 this.installationId
//                 );
                
//                 return githubCommentReaction(
//                     400,
//                     (this.payload as IssueCommentCreated).comment.url,
//                     accessToken
//                     );
//         }catch(err){
//             console.log(err)
//         }
//       }
//     }
//   }
}

export default ContextCreationError;

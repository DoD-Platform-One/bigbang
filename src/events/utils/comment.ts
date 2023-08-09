import axios from "axios";
import { getDiscussionId } from "../../queries/discussion.js";

export async function getGitlabDiscussion(
  projectId: number,
  MRNumber: number | string,
  discussionId: number | string
) {
  return await axios.get(
    `https://repo1.dso.mil/api/v4/projects/${projectId}/merge_requests/${MRNumber}/discussions/${discussionId}`,
    { headers: { "PRIVATE-TOKEN": process.env.GITLAB_PASSWORD } }
  );
}

export async function updateGitLabNoteWithMirrorLink(
  gitHubUrl: string,
  comment: string,
  projectID: number,
  MRNumber: number,
  noteId: number | string
) {
  const githubComment = `[Github Comment Mirrored Here](${gitHubUrl})`;
  const editedGitlabComment = `${githubComment}<hr/>${comment}`;
  await axios.put(
    `https://repo1.dso.mil/api/v4/projects/${projectID}/merge_requests/${MRNumber}/notes/${noteId}`,
    { body: editedGitlabComment },
    { headers: { "PRIVATE-TOKEN": process.env.GITLAB_PASSWORD } }
  );
}

export async function createGithubComment(
  githubUrl: string,
  downstreamRequestNumber: number,
  comment: string,
  gitHubAccessToken: string
) {
  return await axios.post(
    `${githubUrl}/issues/${downstreamRequestNumber}/comments`,
    { body: comment },
    { headers: { Authorization: `Bearer ${gitHubAccessToken}` } }
  );
}

export async function gitlabNoteReaction(
  status: number,
  noteId: number,
  projectID: number,
  MRNumber: number
) {
  const emoji = status === 201 ? "thumbsup" : "thumbsdown";

  ///projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
  await axios.post(
    `https://repo1.dso.mil/api/v4/projects/${projectID}/merge_requests/${MRNumber}/notes/${noteId}/award_emoji`,
    { name: emoji },
    { headers: { "PRIVATE-TOKEN": process.env.GITLAB_PASSWORD } }
  );
}

export async function githubCommentReaction(
  status: number,
  url: string,
  gitHubAccessToken: string
) {
  const emoji = status === 201 ? "+1" : "-1";
  const body = {
    content: emoji,
  };
  await axios.post(url + "/reactions", body, {
    headers: { Authorization: `Bearer ${gitHubAccessToken}` },
  });
}

export async function createGitlabReply(
  noteId: string,
  comment: string,
  projectId: number,
  MRNumber: number
) {
  const discussionId = await getDiscussionId(noteId);
  return axios.post(
    `https://repo1.dso.mil/api/v4/projects/${projectId}/merge_requests/${MRNumber}/discussions/${discussionId}/notes`,
    { body: comment },
    { headers: { "PRIVATE-TOKEN": process.env.GITLAB_PASSWORD } }
  );
}

export async function createGitlabComment(
  comment: string,
  projectId: number,
  MRNumber: number,
) {
  return await axios.post(
    `https://repo1.dso.mil/api/v4/projects/${projectId}/merge_requests/${MRNumber}/notes`,
    { body: comment },
    { headers: { "PRIVATE-TOKEN": process.env.GITLAB_PASSWORD } }
  );
}
export async function updateGitHubCommentWithMirrorLink(
  comment: string,
  noteId: string,
  MRNumber: number,
  gitlabUrl: string,
  gitHubUrl: string,
  gitHubAccessToken: string
) {
  const gitlabLink = `[Gitlab Comment Mirrored Here](${gitlabUrl}/-/merge_requests/${MRNumber}#note_${noteId})`;
  const editedGithubComment = `${gitlabLink}<hr/>\r\n${comment}`;
  return axios.patch(
    gitHubUrl,
    { body: editedGithubComment },
    { headers: { Authorization: `Bearer ${gitHubAccessToken}` } }
  );
  }
 
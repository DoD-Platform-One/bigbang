import {onGitHubEvent, OnGitlabEvent} from './eventManager'

///////////////////////////////
// GITHUB
///////////////////////////////

onGitHubEvent('issue_comment.created', async (payload) => {
})

onGitHubEvent('issue_comment.deleted', async (payload) => {
})



///////////////////////////////
// GITLAB / REPO1
///////////////////////////////

OnGitlabEvent('issue_comment.created', async (payload) => {
})
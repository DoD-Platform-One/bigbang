import {onGitHubEvent, OnGitlabEvent} from './eventManager'
import { GetMapping, GetUpstreamRequestNumber } from '../assets/projectMap';
import axios from 'axios';
import dotenv from 'dotenv';
import { getGitHubAppAccessToken } from '../appcrypto';

dotenv.config();

///////////////////////////////
// GITHUB
///////////////////////////////

onGitHubEvent('issue_comment.created', async ({appID,payload}) => {

//create variable for issue number
const PRNumber = payload.issue.number;

//create variable for user type
const userType = payload.comment.user.type;

//verify comment is not from a bot and end process if it is
if(userType === "Bot"){
    console.log("Comment is from a bot");
    return
}

const upstreamRequestNumber = GetUpstreamRequestNumber(payload.repository.name, PRNumber)
const mapping = GetMapping();
const upstreamProjectId = mapping[payload.repository.name].gitlab.id
const userName = payload.comment.user.login;

//format comment to be posted to gitlab
const comment = `#### ${userName} [commented](${payload.comment.html_url}): <hr> \n\n  ${payload.comment.body}`


// axios post to gitlab api to create a comment on the merge request, using auth header with gitlaboken
const response = await axios.post(
    `https://repo1.dso.mil/api/v4/projects/${upstreamProjectId}/merge_requests/${upstreamRequestNumber}/notes`, 
    {body: comment}, 
    {headers : {"PRIVATE-TOKEN" :process.env.GITLAB_PASSWORD}}
);

const access_token = await getGitHubAppAccessToken(appID, payload.repository.name, payload.installation.id)

// axios post to github api to add an emoji to the comment sent to this event handler.  Checkmark if response is ok and X if not
const emoji = response.status === 201 ? "+1" : "-1"
const body = {
    "content": emoji
}
await axios.post(payload.comment.url + "/reactions", body, {headers : {"Authorization" : `Bearer ${access_token}`}});
})

///////////////////////////////
// GITLAB / REPO1
///////////////////////////////

OnGitlabEvent('issue_comment.created', async (payload) => {
})
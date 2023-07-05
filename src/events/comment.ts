import {onGitHubEvent, onGitlabEvent} from './eventManager.js';
import {GetDownstreamRequestNumber, GetUpstreamRequestNumber } from '../assets/projectMap.js';
import axios from 'axios';
import dotenv from 'dotenv';
dotenv.config();

///////////////////////////////
// GITHUB
///////////////////////////////

onGitHubEvent('issue_comment.created', async (context) => {
const {payload, mapping, projectName} = context
//create variable for issue number
const PRNumber = payload.issue.number;

//create variable for user type
const userType = payload.comment.user.type;

//verify comment is not from a bot and end process if it is
if(userType === "Bot"){
    console.log("Bot Comment, Ignoring");
    return
}

const upstreamRequestNumber = GetUpstreamRequestNumber(projectName, PRNumber)
const userName = payload.comment.user.login;

//format comment to be posted to gitlab
const comment = `#### ${userName} [commented](${payload.comment.html_url}): <hr> \n\n  ${payload.comment.body}`


// axios post to gitlab api to create a comment on the merge request, using auth header with gitlaboken
const response = await axios.post(
    `https://repo1.dso.mil/api/v4/projects/${mapping.gitlab.projectID}/merge_requests/${upstreamRequestNumber}/notes`, 
    {body: comment}, 
    {headers : {"PRIVATE-TOKEN" :process.env.GITLAB_PASSWORD}}
);

// axios post to github api to add an emoji to the comment sent to this event handler.  Checkmark if response is ok and X if not
const emoji = response.status === 201 ? "+1" : "-1"
const body = {
    "content": emoji
}
await axios.post(payload.comment.url + "/reactions", body, {headers : {"Authorization" : `Bearer ${context.gitHubAccessToken}`}});
})

//post message to gitlab pull request when a comment is created on a github pull request

///////////////////////////////
// GITLAB / REPO1
///////////////////////////////

onGitlabEvent('note.MergeRequest', async (context) => {
    const {projectName, payload} = context
    
    //view payload in console
    
    // //create variable for payload merge_request number
    const MRNumber = payload.merge_request.iid
    
    //create variable for project name 
    const userName = payload.user.username as string;
    //create variable for username  
    if(userName.includes(`project_${payload.project.id}_bot`)){
        console.log("Bot Comment, Ignoring");
        return
    }
    

    //get downstream request number
    const downstreamRequestNumber = GetDownstreamRequestNumber(projectName, MRNumber)

    //create variable for projectID
    const projectID = payload.project.id;

   
        
    // create variable for comment bod to be posted to github
    const comment = `#### ${userName} [commented](${payload.object_attributes.url}): <hr> \n\n  ${payload.object_attributes.note}`
    //create variable for installationID

    
    const response = await axios.post(
        `${context.mapping.github.url}/issues/${downstreamRequestNumber}/comments`,
        {body: comment},
        {headers : {"Authorization" : `Bearer ${context.gitHubAccessToken}`}}
    );
    
    //verify response is ok and post emoji to gitlab comment
    const emoji = response.status === 201 ? "thumbsup" : "thumbsdown"
    
    //create variable for note id from response
    const note_id = payload.object_attributes.id;
    //

    ///projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
    
    axios.post(
        `https://repo1.dso.mil/api/v4/projects/${projectID}/merge_requests/${MRNumber}/notes/${note_id}/award_emoji`, 
        {name: emoji},
        {headers : {"PRIVATE-TOKEN" :process.env.GITLAB_PASSWORD}}
    );
 
})

// PR close in Github when MR is closed in Gitlab
onGitlabEvent('merge_request.closed', async (context) => {
    const {projectName, payload} = context
    const MRNumber = payload.object_attributes.iid
    const downstreamRequestNumber = GetDownstreamRequestNumber(projectName, MRNumber)
    // const userName = payload.user.username as string;

    // PR closed to github
    await axios.patch(
        `${context.mapping.github.url}/issues/${downstreamRequestNumber}`,
        {state: "closed"},
        {headers : {"Authorization" : `Bearer ${context.gitHubAccessToken}`}}
        );
})

    //MR close in gitlab when PR is closed in github
    onGitHubEvent('pull_request.closed', async (context) => {
        const {projectName, payload} = context
        const PRNumber = payload.pull_request.number;
        const upstreamRequestNumber = GetUpstreamRequestNumber(projectName, PRNumber)
        //MR closed to gitlab
        await axios.put(
            `https://repo1.dso.mil/api/v4/projects/${context.mapping.gitlab.projectID}/merge_requests/${upstreamRequestNumber}`,
             {state_event: "close"}, 
            {headers : {"PRIVATE-TOKEN" :process.env.GITLAB_PASSWORD}}
            );
            
        
    
})
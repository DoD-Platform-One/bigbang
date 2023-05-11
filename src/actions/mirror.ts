






// export = (app: Probot) => {
  
    // app.on('issue_comment.created', async (context) => {
      
    //     const PRNumber = context.payload.issue.number
    //     if(context.isBot){
    //       app.log(`bot commented on PR #${PRNumber}`)
    //       return
    //     }
        
    //     if(!context.payload.issue.pull_request || context.payload.comment.body !== "/pipes"){
    //       app.log(context.payload.issue.pull_request.url)
    //       app.log(context.payload.comment.body)
    //       return
    //     }
        
    //     // repo one bot steps
    //     const github_url = context.payload.repository.clone_url
        
    //     // TODO Figure out how to get repo 1 git url
    //     const repo_1_url = context.payload.repository.homepage
    //     app.log("cloning")
    //     // clone github repo
    //     execSync(`git clone ${github_url} ./tmp`, {cwd: "../"})
        
    //     app.log("setting up mirror")
    //     // create remote mirror
    //     execSync(`git remote add mirror ${repo_1_url}`, execOptions)
  
    //     // get PR number
    //     // make a new branch off the PR ref
    //     app.log(`fetching ref for PR-${PRNumber}`)      
    //     execSync(`git fetch origin pull/${PRNumber}/head:PR-${PRNumber}`,execOptions)
  
    //     //check out branch
    //     app.log("checking out branch")
    //     execSync(`git checkout PR-${PRNumber}`, execOptions)
  
    //     // git push mirror {DESIRED_BRANCH_NAME}
    //     app.log("pushing to mirror")
    //     execSync(`git push mirror PR-${PRNumber}`, execOptions)
        
    //     // clean up tmp folder
    //     execSync("rm -rf ./tmp", {cwd: "../"})
  
    //     // js wait of 10s
    //     // app.log("waiting...")
    //     // delay (10000)
    //     // app.log("I'm tired of waiting...")
  
    //     // get Repo1 Project Id from "topics"
    //     const Pid = context.payload.repository.topics[0]
  
    //     // get Repo 1 pipeline URL
    //     app.log(`fetching pipeline for Project ${Pid}`)
    //     const response = await axios.get(`https://repo1.dso.mil/api/v4/projects/${Pid}/repository/commits/PR-${PRNumber}`)
        
    //     // app.log(response)
    //     let issueComment = undefined
    //     if(response.data.last_pipeline){
    //       issueComment = context.issue({ body: response.data.last_pipeline.web_url })
    //     }else{
    //       issueComment = context.issue({ body: "There was an error retrieving the pipeline" })
    //     }
        
    //     context.octokit.issues.createComment(issueComment)
    // })
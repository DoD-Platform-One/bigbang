import {emitter, on, parseGitHubEventName, onIssueCommentCreated, onPullRequestClosed, onPullRequestOpened} from '../../src/Events/eventManager'


describe('Parse GitHub EventName', () => {
  it('Test Github Header + action parser works', () => {
    const headers = {
        "X-GitHub-Event": "issue_comment"
    }
    const action = "created"
    const eventName = parseGitHubEventName(headers, action)
    expect(eventName).toBe("issue_comment.created")
  })

  it('Test Github Header + action parser works but headers are lowercase', () => {
    const headers = {
        "x-gitHub-event": "issue_comment"
    }
    const action = "created"
    const eventName = parseGitHubEventName(headers, action)
    expect(eventName).toBe("issue_comment.created")
  })
})

describe('Event Emmiter Tests', () => {

  it('Test Event Emitter', () => {
    const arrayCheck: string[] = []
    const callback = () => {
        arrayCheck.push("testResult")
    }
    emitter.on("testEmit", callback)
    emitter.emit("testEmit")
    expect(arrayCheck).toStrictEqual(["testResult"])
  })

  it('Test onIssueCommentCreated', () => {
    const arrayCheck: string[] = []
    const callback = (context: string) => {
        arrayCheck.push(context)
    }
    onIssueCommentCreated(callback)
    emitter.emit("issue_comment.created", "testContext")
    expect(arrayCheck).toStrictEqual(["testContext"])
  })

  it('Test onPullRequestOpened', () => {
    const arrayCheck: string[] = []
    const callback = (context: string) => {
        arrayCheck.push(context)
    }
    onPullRequestOpened(callback)
    emitter.emit("pull_request.opened", "testContext")
    expect(arrayCheck).toStrictEqual(["testContext"])
  })

  it('Test onPullRequestClosed', () => {
    const arrayCheck: string[] = []
    const callback = (context: string) => {
        arrayCheck.push(context)
    }
    onPullRequestClosed(callback)
    emitter.emit("pull_request.closed", "testContext")
    expect(arrayCheck).toStrictEqual(["testContext"])
  })

  // test generic on function
  it('Test on', () => {
    const arrayCheck: string[] = []
    const callback = (context: string) => {
        arrayCheck.push(context)
    }
    on("testOnFunction", callback)
    emitter.emit("testOnFunction", "testContext")
    expect(arrayCheck).toStrictEqual(["testContext"])
  })

})
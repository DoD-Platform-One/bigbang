import {emitter, parseGitHubEventName, onGitHubEvent, IContext } from '../../src/Events/eventManager'



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
    // make a callback of type IContext
    const callback = (context: IContext) => {
        arrayCheck.push(context.payload)
    }

    // const callback = ({: string, }) => {
    //     arrayCheck.push(context)
    // }
    onGitHubEvent("issue_comment.created" ,callback)
    emitter.emit("issue_comment.created", {payload: "testContext"})
    expect(arrayCheck).toStrictEqual(["testContext"])
  })
})
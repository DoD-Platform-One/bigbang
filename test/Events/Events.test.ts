import {createContext, emitEvent } from '../../src/EventManager/eventManager.js'
import {payload as issueCommentPayload} from '../fixtures/issueComment.js'
import {payload as issueCommentPayloadBot} from '../fixtures/issueCommentBot.js'

import {payload as pullRequestPayload} from '../fixtures/pullRequest.js'
import {gitlabNoteMergeRequest} from '../fixtures/gitlab-note.MergeRequest.js'
import { mockApi } from '../mocks/mocks.js'
import { UpdateConfigMapping } from '../../src/assets/projectMap.js'
import {clearMapping} from '../teardown.js'
import { Response, Request } from 'express'
import { IEventContextObject, emitter, onGitHubEvent } from '../../src/EventManager/eventManagerTypes.js'
import NotImplementedError from '../../src/errors/NotImplementedError.js'
import ContextCreationError from '../../src/errors/ContextCreationError.js'

const setupConfig = () => UpdateConfigMapping({
  projectName: pullRequestPayload.repository.name,
  gitHubDefaultBranch: pullRequestPayload.repository.default_branch,
  gitHubIssueNumber: pullRequestPayload.number,
  gitHubProjectId: pullRequestPayload.repository.id,
  gitHubApiUrl: pullRequestPayload.repository.url,
  gitHubCloneUrl: pullRequestPayload.repository.clone_url,
  gitHubSourceBranch: pullRequestPayload.pull_request.head.ref,
  gitLabSourceBranch: pullRequestPayload.pull_request.head.ref,
  // gitlab v
  gitLabMergeRequestNumber: 12,
  gitLabProjectId: 1234,
  gitLabProjectUrl: "https://gitlab.com/owner/repo",
  gitLabDefaultBranch: "master",
  appID: 1234,
  installationID: 1,
})

describe('Create GitHub Context',  () => {
  // before each test, mock the api call to /app/installations/1/access_tokens
  // const uri = /\/app\/installations\/\d+\/access_tokens/

  beforeEach(() => {
    mockApi("github","post", "/app/installations/1/access_tokens", {token: "testToken"})
  })

  it("test create context with no headers", async () => {
    const headers = {}
    const context = await createContext(headers, {type: "issue_comment.created",...issueCommentPayload}, {} as Response, () => null)
    expect(context.error).toBeInstanceOf(NotImplementedError)
  })

  it('test create context with no mapping', async () => {
    const headers = {
        "x-github-event": "issue_comment",
        "x-github-hook-installation-target-id": "1234"
    }
    const context = await createContext(headers, {type: "issue_comment.created",...issueCommentPayload}, {} as Response, () => null)
    expect(context.error).toBeInstanceOf(ContextCreationError)
  })

  it('test create context with uppercase headers', async () => {
    const headers = {
        "X-GitHub-Event": "issue_comment",
        "X-Github-Hook-Installation-Target-Id": "1234"
    }

    // configure the mapping file
    setupConfig()

    const context = await createContext(headers, {type: "issue_comment.created",...issueCommentPayload}, {} as Response, () => null)
    expect(context.error).toBeUndefined()
    expect(context?.eventName).toBeTruthy()
  })

  it('test create context with lowercase headers', async () => {
    const headers = {
        "x-github-event": "issue_comment",
        "x-github-hook-installation-target-id": "1234"
    }

    // configure the mapping file
    setupConfig()

    const context = await createContext(headers, {type: "issue_comment.created",...issueCommentPayload}, {} as Response, () => null)
    expect(context.error).toBeUndefined()
    expect(context?.eventName).toBe("issue_comment.created")
  })

  it('test mapping file is populated', async () => {
    const headers = {
        "x-github-event": "issue_comment",
        "x-github-hook-installation-target-id": "1234"
    }

    // configure the mapping file
    setupConfig()

    // deep copy of payload
    const payloadCopy = JSON.parse(JSON.stringify(issueCommentPayload))

    const context = await createContext(headers, payloadCopy, {} as Response, () => null)
    expect(context.error).toBeUndefined()
    expect(context?.eventName).toBe("issue_comment.created")
    expect(context?.mapping.github.projectId).toBe(pullRequestPayload.repository.id)
  })

  it('test context has correct properties', async () => {
    const headers = {
        "x-github-event": "issue_comment",
        "x-github-hook-installation-target-id": "1234"
    }

    // configure the mapping file
    setupConfig()

    // deep copy of payload
    const payloadCopy = JSON.parse(JSON.stringify(issueCommentPayload))

    const context = await createContext(headers, payloadCopy, {} as Response, () => null)
    expect(context.error).toBeUndefined()
    expect(context?.eventName).toBe("issue_comment.created")
    expect(context.event).toBe("issue_comment")
    expect(context.canInit).toBe(false)
    expect(context.action).toBe("created")
    expect(context.gitHubAccessToken).toBe("testToken")
    expect(context.isBot).toBe(false)
    expect(context?.mapping.github.projectId).toBe(issueCommentPayload.repository.id)
    expect(context?.installationId).toBe(1)
    expect(context?.appId).toBe(1234)
    expect(context?.projectName).toBe(issueCommentPayload.repository.name)
    expect(context?.requestNumber).toBe(issueCommentPayload.issue.number)
    expect(context.userName).toBe(issueCommentPayload.sender.login)
    expect(context.payload).toStrictEqual(issueCommentPayload)
  })

  it('test has not config map', async () => {
    const headers = {
        "x-github-event": "this_event_does_not_exist",
        "x-github-hook-installation-target-id": "1234"
    }

    // configure the mapping file
    setupConfig()

    // deep copy of payload
    const payloadCopy = JSON.parse(JSON.stringify(issueCommentPayload))

    const context = await createContext(headers, payloadCopy, {} as Response, () => null)
    expect(context.error).toBeInstanceOf(NotImplementedError)
  })

  it('tests if a config has the canInit property', async () => {
    const headers = {
        "x-github-event": "pull_request",
        "x-github-hook-installation-target-id": "1234"
    }

    // configure the mapping file
    setupConfig()

    // deep copy of payload
    const payloadCopy = JSON.parse(JSON.stringify(pullRequestPayload))

    const context = await createContext(headers, payloadCopy, {} as Response, () => null)
    expect(context.error).toBeUndefined()
    expect(context?.eventName).toBe("pull_request.opened")
    expect(context.canInit).toBe(true)
  })
})

describe ('Create GitLab Context', () => {

  beforeEach(() => {
    // ensure config mapping is empty
    clearMapping()
    mockApi("github","post", "/app/installations/1/access_tokens", {token: "testToken"})
  })

  it('test create context with uppercase headers', async () => {
    const headers = {
        "X-Gitlab-Event": "Note Hook",
    }
    setupConfig()
    const context = await createContext(headers, {type: "note.created",...gitlabNoteMergeRequest}, {} as Response, () => null)
    expect(context.error).toBeUndefined()
    expect(context?.eventName).toBe("note.created")
    expect(context?.mapping.gitlab.projectId).toBe(1234)

  })

  
    // X-Gitlab-Event-UUID: 6e8d440d-ec8a-4744-887e-3c8929b92af6
    it('test that headers can not do a fuzzy match', async () => {
      const headers = {
          "X-Gitlab-Event": "Note Hook",
          "X-Gitlab-Event-UUID": "6e8d440d-ec8a-4744-887e-3c8929b92af6",
      }
      setupConfig()
      const context = await createContext(headers, {type: "note.created",...gitlabNoteMergeRequest}, {} as Response, () => null)
      expect(context.event).toBe("note")
    })
})

describe('tests for bots', () => {
  it('test context is bot', async () => {
    const headers = {
        "x-github-event": "issue_comment",
        "x-github-hook-installation-target-id": "1234"
    }

    // configure the mapping file
    setupConfig()

    // deep copy of payload
    const payloadCopy = JSON.parse(JSON.stringify(issueCommentPayloadBot))

    const context = await createContext(headers, payloadCopy, {} as Response, () => null)
    expect(context.error).toBeUndefined()
    expect(context?.eventName).toBe("issue_comment.created.bot")
    expect(context.isBot).toBe(true)
    expect(context.userName).toBe(issueCommentPayloadBot.sender.login)
    expect(context.payload).toStrictEqual(issueCommentPayloadBot)
  })
})

describe('Event Emiter Tests', () => {

  beforeEach(() => {
    // ensure config mapping is empty
    clearMapping()
    mockApi("github","post", "/app/installations/1/access_tokens", {token: "testToken"})
  })

  it('Test Event Emitter', () => {
    const arrayCheck: string[] = []
    const callback = () => {
        arrayCheck.push("testResult")
    }
    emitter.on("push", callback)
    emitter.emit("push", {} as IEventContextObject)
    expect(arrayCheck).toStrictEqual(["testResult"])
  })

  it('tests EmitEvent Function', async () => {
    const next = jest.fn()
    
    onGitHubEvent("issue_comment.created", (context) => {
      expect(context.next).not.toHaveBeenCalled()
      expect(context.eventName).toBe("issue_comment.created")
    })

    const headers = {
      "x-github-event": "issue_comment",
      "x-github-hook-installation-target-id": "1234"
    }
    const request = {} as Request
    const res = {} as Response

    // configure the mapping file
    setupConfig()

    // deep copy of payload
    const payloadCopy = JSON.parse(JSON.stringify(issueCommentPayload))

    request.body = payloadCopy
    request.headers = headers

    const ret = await emitEvent(request, res, next)
    expect(ret).toBeTruthy()
    expect(next).not.toHaveBeenCalled()
  })

  it('tests EmitEvent Function throws error', async () => {
    const next = jest.fn()
    emitter.on("issue_comment.created", () => {expect(next).not.toHaveBeenCalled()})

    const headers = {
      // "x-github-event": "pull_request",
      "x-github-hook-installation-target-id": "1234"
    }
    const request = {} as Request
    const res = {} as Response

    // configure the mapping file
    setupConfig()

    // deep copy of payload
    const payloadCopy = JSON.parse(JSON.stringify(issueCommentPayload))

    request.body = payloadCopy
    request.headers = headers

    const ret = await emitEvent(request, res, next)
    await expect(ret).toBeUndefined()
    expect(next).toHaveBeenCalledWith(new NotImplementedError("Service Not Implemented"))
  })

  it('tests EmitEvent event not registered', async () => {
    const next = jest.fn()
    const headers = {
      "x-github-event": "pull_request",
      "x-github-hook-installation-target-id": "1234"
    }
    const request = {} as Request
    const res = {} as Response

    // configure the mapping file
    setupConfig()

    // deep copy of payload
    const payloadCopy = JSON.parse(JSON.stringify(issueCommentPayload))

    request.body = payloadCopy
    request.headers = headers

    const ret = await emitEvent(request, res, next)
    await expect(ret).toBeUndefined()
    expect(next).toHaveBeenCalledWith(new NotImplementedError("Event Not Registered: github : pull_request.created"))
  })
})
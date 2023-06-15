import request from 'supertest'
import {githubSigHeaderName, gitlabTokenHeaderName} from '../src/appcrypto'
import app from '../src/app'
import crypto from 'crypto'


describe('auth failure', () => {
  it('NO TOKEN', done => {
    request(app)
      .post('/test').expect(401, done)
      .set('Content-type', 'application/json')
  })

  it('GITHUB: should return 401 auth rejects with an error for bad token', done => {
    request(app)
      .post(`/test`)
      .set('Content-type', 'application/json')
      .set(githubSigHeaderName, "blah blah")
      .expect(401, done)
  })
  it('GITLAB: should return 401 auth rejects with an error for bad token', done => {
    request(app)
    .post(`/test`)
    .set('Content-type', 'application/json')
    .set(gitlabTokenHeaderName, "blah blah").expect(401, done)
  })
})

describe('auth success', () => {

  const githubSecret = process.env.GITHUB_WEBHOOK_SECRET ?? "test";
  const gitlabToken = process.env.GITLAB_WEBHOOK_SECRET ?? "test";
  const jsonstring = {"action":"created"}
  const issuecreated = JSON.stringify(jsonstring)

  const hmac = crypto.createHmac('SHA256', githubSecret)
  const signatureComputed = Buffer.from("sha256=" + hmac.update(issuecreated).digest('hex'), 'utf8')
  // const hmac = crypto.createHmac('SHA256', github_secret)
  // const signatureComputed = Buffer.from("" + hmac.update(jsonbody).digest('hex'), 'utf8')

  it ('GITHUB: SHA256', () => {
    const github_computed_sha = "sha256=61c73ef7677a402b5942e66ed7985b03efc1fd2219767badb1d8aca47fb79857"
    expect(githubSecret).toBe('1234567890')
    expect(signatureComputed.toString()).toBe(github_computed_sha)
  })

  it('GITHUB: should return 200', done => {
    request(app)
      .post(`/test`)
      .set('Content-type', 'application/json')
      .set(githubSigHeaderName, signatureComputed.toString())
      .send(jsonstring)
      .expect(200, done)
  })
  it('GITLAB: should return 200', done => {
    request(app)
    .post(`/test`)
    .set('Content-type', 'application/json')
    .set(gitlabTokenHeaderName, gitlabToken)
    .expect(200, done)
  })
})
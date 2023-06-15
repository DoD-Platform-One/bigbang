import nock, {Scope} from 'nock';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function mockApi(instance: "github" | "gitlab", method: 'get' | 'post' = "get", uri: string | RegExp, returnPayload: any) {
    
    let scope: Scope;
    if (instance === "github") {
        // scope = nock('https://api.github.com')
        // use regex to match any github api url
        scope = nock(/https:\/\/api\.github\.com/)
    }else {
        // scope = nock('https://*/api/v4')
        // use regex to match any gitlab api url
        scope = nock(/https:\/\/.*\/api\/v4/)
    }
    
    scope[method](uri).reply(200, returnPayload);

    return scope;
}

// export the type of Scope from here
export type MockScope = Scope;

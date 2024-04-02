---
revision_date: Last edited April 2, 2024
tags:
  - blog
---

# Cypress Testing In-Depth
 
## Introduction
 
The intent of this post is to build off the existing Cypress Testing documentation [here](../docs/guides/using-bigbang/testing-deployments.md) and go a bit deeper into how it can be leveraged in a real-world environment.  We will also go a bit deeper into Cypress specific configuration settings, running/debugging tests, and cover some of the basics of Cypress.
 
## Environment Overview
 
Before we get started, let's go over the environment we'll be using.  This environment was setup using the umbrella strategy described in our [Customer Template](https://repo1.dso.mil/big-bang/customers/template) and has the following layout:

```
|-- bb-demo
|  |-- base
|  |  |-- cypress-tests
|  |  |  |-- sonarqube
|  |  |  |  -- 10-sonarqube-health.cy.js
|  |  |  |  -- 11-sonarqube-delay.cy.js
|  |  -- configmap.yaml
|  |  -- kustomization.yaml
|  |  -- secrets.enc.yaml
|  |-- demo
|  |  -- bigbang.yaml
|  |  -- configmap.yaml
|  |  -- kustomization.yaml
|  |  -- secrets.enc.yaml
```

As this is only a demo, there is only one environment named demo, but in a real-world situation you would likely have additional folders for staging and production.  The custom Cypress tests are located under the base folder as these would remain the same regardless of the environment to which they are being deployed.  The configuration of the environment itself is pretty straight forward and primarily contained in the configmap.yaml under the demo folder:

```
domain: dev.bigbang.mil
networkPolicies:
  enabled: true
neuvector:
  enabled: false
kyvernoPolicies:
  values:
    validationFailureAction: Audit
addons:
  sonarqube:
    enabled: true
    values:
      bbtests:
        enabled: true
        cypress:
          artifacts: false
          disableDefaultTests: true
          customTest: "sonarqube-tests"
          resources:
            requests:
              cpu: 2
              memory: "4Gi"
            limits:
              cpu: 4
              memory: "8Gi"
          envs:
            cypress_user: "admin"
            cypress_url: "https://sonarqube.dev.bigbang.mil"
            cypress_url_setup: "https://sonarqube.dev.bigbang.mil/setup"
          secretEnvs:
            - name: cypress_password
              valueFrom:
                secretKeyRef:
                  name: sonarqube-secrets
                  key: password
```

We'll go over the more specific configuration settings for Cypress later, but for now let's continue to the rest of the configuration.  The kustomization.yaml under the demo folder holds an additional reference to a kubernetes secret created to hold the password for the sonarqube user:

```
generatorOptions:
  disableNameSuffixHash: true
bases:
- ../base
configMapGenerator:
  - name: environment
    behavior: merge
    files:
      - values.yaml=configmap.yaml
secretGenerator:
  - name: sonarqube-secrets
    namespace: sonarqube
    files:
      - password=secrets.enc.yaml
```

The kustomization.yaml file under the base folder has also been modified to reference the Cypress test files we want to use:

```
generatorOptions:
  disableNameSuffixHash: true
bases:
- https://repo1.dso.mil/platform-one/big-bang/bigbang.git//base?ref=2.23.0
configMapGenerator:
  - name: common
    behavior: merge
    files:
      - values.yaml=configmap.yaml
  - name: sonarqube-tests
    namespace: sonarqube
    files:
      - cypress-tests/sonarqube/10-sonarqube-health.cy.js
      - cypress-tests/sonarqube/11-sonarqube-delay.cy.js
patchesStrategicMerge:
- secrets.enc.yaml
```

Both kustomization.yaml files have an additional option at the top to disable the name suffix hash to ensure we can reference it correctly.  The assumption of this environment is that Sonarqube has been enabled and configured.
 
## Cypress Specific Settings
 
Aside from enabling the tests themselves, there are a few settings that deserve more attention:

* artifacts - This setting is typically set to true when running tests from a pipeline.  However, since we are running this in a local dev environment we have set the value to false.  It's worth noting that when this value is true a host path mount called Cypress will need to be created and available within your Kubernetes cluster.  This allows the pod to upload any of the resulting screenshots and videos from the cypress tests before the pod completes.

* resources - Cypress recommends 2 CPU's and 4 GB of RAM at an absolute minimum with more given depending on the complexity and length of the tests themselves.  At the time of this writing, the default values for both requests and limits for CPU and Memory are 1 and 2 GB respectively as many of the default tests are very basic.  The settings used in the configmap.yaml previously shown are just there for demo purposes and are likely much more than what is needed for our tests.  However, if you ever find yourself running into odd issues that only seem to come up in your tests, it may be a good idea to tweak those values first to make sure its not the cause.  This is especially true if you find that the logs indicate the browser crashed during a test as that is the most common sign of not having enough resources.

* envs - This is where you would specify any environment variables that will be used by your Cypress tests.  You'll want to check each package where tests are enabled to see what variables are required if you're using the default provided tests.  You can also add in any additional variables you need for any custom tests you've written.  Any variable prefixed with "cypress_" will become a variable you can use in your tests.  For example, the existing variable of "cypress_user" shown above, can be used within your Cypress test by referencing the "user" variable which you'll see a bit later.

* secretEnvs - The same rules apply to this setting, but these values are pulled from Kubernetes secret files so they'd likely be used for any passwords or tokens you may need to use throughout any tests.

We won't go over the customTest and disableDefaultTests settings as this has already been explained in the documentation link referenced in the Introduction section.
 
## Cypress Tests
 
Now that we've covered the environment and settings, let's take a look at the Cypress tests themselves.  In this specific scenario, we've come to the realization that the default tests don't quite offer all we need to be satisfied.  As a result, we've decided to disable the default tests and create a very basic health check:

```
Cypress.on('uncaught:exception', (err, runnable) => {
  // returning false here prevents Cypress from failing the test
  return false
})

describe('Sonarqube Health Checks', () => {

  it('Perform Login', () => {
    //Login and wait for authentication call to complete before moving on
    cy.visit(`${Cypress.env('url')}/sessions/new?return_to=%2F`)
    cy.get('input[name="login"]').type(Cypress.env('user'))
    cy.get('input[name="password"]').type(Cypress.env('password'))
    cy.intercept('POST', '**/api/authentication/login').as('validSession')
    cy.get('button[type="submit"]').contains("Log in").click()
    cy.wait('@validSession').then((interception) => {
      expect(interception.response.statusCode).to.equal(200)
    })
  })

  it('Validate Health', () => {
    //Use API Response to validate system is up
    cy.intercept('GET', '**/info').as('apiCall')
    cy.visit(`${Cypress.env('url')}/admin/system`)
    cy.wait('@apiCall').then(({ response }) => {
        expect(response.statusCode).to.equal(200)
        expect(response.body).to.have.property('Health', 'GREEN')
    })
    //Use UI to validate system is up
    cy.get('.system-info-health-info').contains('Status is up')
  })
})
```

The first few lines of the test allow Cypress to continue to run in the event we encounter any errors while browsing to the site.  In this situation, we are seeing some 401's from a couple of API calls that occur when browsing to the system section of this application even after successfully authenticating.  Typically, you would want to dig a little deeper into the underlying issue for that, however, I wanted to illustrate how you can bypass those errors as there are some applications that may exhibit behaviors that you cannot control.  Additionally, Cypress will still fail if the actual tests themselves fail even with this setting.

The next snippet browses directly to the login URL, inputs the username/password, and clicks submit.  If we were to browse to the base URL, https://sonarqube.dev.bigbang.mil, we would be met with several 401 statuses causing Cypress to fail without that first snippet.  This is one way you can avoid the behavior previously mentioned as browsing directly to the login URL prevents those 401's from occurring.  You may also notice that we are using "(Cypress.env('user'))" as opposed to "(Cypress.env('cypress_user'))" when we are referencing a variable we have provided.  This is because the "cypress_" portion is removed when referenced from within the test so keep that in mind when creating custom tests.  Prior to clicking the "Log in" button on the test, we've created an intercept to listen for an underlying API call that will signal a successful authentication.  Without the intercept in place, it is entirely possible to go through the motions of logging in only to fail to authenticate which will cause our subsequent test to fail.

The final snippet performs a basic health check of the application by browsing to the sytem page within Sonarqube.  In a real world scenario, you would only use one of the two methods to validate health, but I wanted to provide another look at how intercepts can be used to validate information within API calls that occur throughout the process of browsing.  Since we don't own the applications, some things may be quite difficult to test using only the browser itself.  Furthermore, if you have several properties of the response you need to validate, you can typically do that more easily using intercepts and often with less code.

The additional test file used in this scenario, 11-sonarqube-delay.cy.js, isn't really doing anything as you can see below:

```
describe('Sonarqube Delay', () => {
    it('Do Nothing', () => {
        cy.wait(30000)
    })
})
```

It was added primarily to illustrate the fact that you can add as many custom tests as you need (although it does serve one other purpose which we'll see later 🙂).  Every test specified in our kustomization.yaml file will be consolidated into the same configmap which we have specified in our Cypress settings.
 
## Running and Debugging the Tests

Now that we've covered all the boring details of the tests and configuration settings, let's run our test by executing the following command:

```
helm test sonarqube -n bigbang
```

Open up your favorite Kubernetes IDE and you should see a new pod in the Sonarqube namespace.  Every Cypress test pod name takes the form of HelmReleaseName-cypress-test so in this case we should be seeing a pod called sonarqube-cypress-test.  The first time the test is run it may take a bit longer as it needs to pull the image down.  If everything ran as expected, you should see no failures output once the "helm test" command completes.

If you'd like to view the logs from the Cypress test pod as the test is executing you can issue the following command:

```
kubectl logs -f sonarqube-cypress-test -n sonarqube
```

> **Note:** You may notice the following errors/warnings occur during the initialization process, but they can be ignored as they have no impact on the test's behavior:

```
Fontconfig error: No writable cache directories
Failed to create /home/node/.cache for shader cache (Read-only file system)---disabling.
[353:0401/180059.881693:ERROR:zygote_host_impl_linux.cc(273)] Failed to adjust OOM score of renderer with pid 570: Permission denied (13)
```

It can also be very useful to view the resulting video from the test run which is where that additional Cypress test comes in.  That test will sit and wait for 30 seconds allowing enough time to download the video from the pod by using the following command:

```
kubectl cp -n sonarqube sonarqube-cypress-test:'/test/cypress/videos/10-sonarqube-health.cy.js.mp4' ~/Downloads/sonarqube.mp4
```

Of course, if you have access to the underlying Kubernetes cluster and you have an existing hostPath created for "/Cypress", you can simply download the video that way.  Just keep in mind, you'll need to set the artifacts value to true within the cypress section under bbtests, otherwise, the videos/screenshots won't be uploaded there.

Since the tests are coming from the configmap, you can easily modify the code within it using the Kubernetes IDE of your choice to quickly and easily test the changes.  Once the configmap has been updated, you can simply run the "helm test" command once more to verify the changes work.  You'll obviously want to make sure you make the same changes within your Cypress test files once you've found what works.

## Tips, Tricks, & Gotchya's

The easiest way to start on writing a Cypress test is to simply browse around with the developer tools open to get a feel of what a site looks like during normal operation.  Once that's been established the process of creating the test becomes fairly straight forward, but here are some additional tips to help get you started:

* Try to use css selectors designated for QA in your tests.  Since we don't have control over the underlying application this can be a bit difficult, but you'll notice several applications seem to have css selectors prefixed with data, qa, or test.  You can reasonably assume these selectors are used by that application's QA process and therefore they are least likely to change.

* Avoid Explicit waits at all costs and use Implicit waits instead.  You may be tempted to force your test to wait prior to taking an action by using something like this:

    ```
    cy.wait(25000)
    cy.get('button[type="submit"]').contains("Log in").click()
    ```

    However, a better way to handle this is to use a timeout value instead like this:

    ```
    cy.get('button[type="submit"]', { timeout: 25000 }).contains("Log in").click()
    ```

    In the first example, the test will **always** wait for 25 seconds before continuing while the second example will wait **up to** 25 seconds before failing or moving on. If it's able to take that action before the 25 second mark it will and the tests will complete sooner.  You will also want to remember that the amount of time it takes to run a test may also necessitate more resources to be given to that pod.  As a result, explicit waits (cy.wait()) should be avoided at all costs.  The only exception to this rule is when its used for waiting on an API call which behaves as an implicit wait.

* Try to avoid using Cypress tests to perform configuration of the application itself and make sure your tests clean up after themselves.  Your Cypress tests can quickly become over-complicated if you try to account for something already existing from a previous run of your test.  Additionally, the results of your tests may give other developers misleading information.  

    For example, let's say you have a test that creates a project within Sonarqube, but the test does not delete that project afterwards.  All subsequent tests may tell the user it was able to successfully create a project when in reality it just found one created from a previous test run.

* Finally, be aware that Cypress is asynchronous which means things may not execute exactly as you think they will.  This can result in tests seemingly failing intermittently even when they execute just fine locally.  To avoid this use chained commands within Cypress to ensure the order will remain intact every time.  This is a bit of a loaded topic so I won't go into further detail about here, but if you'd like more information [this article](https://learn.cypress.io/cypress-fundamentals/understanding-the-asynchronous-nature-of-cypress) is a great place to start. 

## Wrap Up
Cypress can be a powerful testing tool for your arsenal when used properly and now that users can now add in their own tests, it can easily be tailored to fit more specific situations.  Getting everything deployed in Big Bang is nice, but having confidence that it's all working as expected is even better! 🙂
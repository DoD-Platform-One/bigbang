Cypress.on('uncaught:exception', (err, runnable) => {
  return false
})

// keep cookies between blocks (stay logged in if using SSO)
beforeEach(function () {
  cy.getCookies().then(cookies => {
    const namesOfCookies = cookies.map(cm => cm.name)
    Cypress.Cookies.preserveOnce(...namesOfCookies)
  })
})

before(() => {
  if (Cypress.env('keycloak_test_enable')) {
        cy.visit(Cypress.env('url'))
        cy.get('button').click()
        cy.get('input[id="username"]').type(Cypress.env('keycloak_username'))
        cy.get('input[id="password"]').type(Cypress.env('keycloak_password'))
        cy.get('input[id="kc-login"]').click()
        cy.get('input[id="kc-accept"]').click()
        cy.intercept('GET', '**/*').as('landingpage')
        cy.get('input[id="kc-login"]').click()
        // after hitting "yes" on the consent page, there should be a redirect back to the app (302)
        cy.wait('@landingpage').its('response.statusCode').should('eq', 302)
        // then the app's page should load
        cy.wait('@landingpage').its('response.statusCode').should('eq', 200)
  }
})

function expandMenu() {
  cy.get('button[id="nav-toggle"]').invoke('attr', 'aria-expanded').then(($expanded) => {
    if ($expanded === 'false') {
      cy.get('button[id="nav-toggle"]').click()
    }
  })
}

function collapseMenu() {
  cy.get('button[id="nav-toggle"]').invoke('attr', 'aria-expanded').then(($expanded) => {
    if ($expanded === 'true') {
      cy.get('button[id="nav-toggle"]').click()
    }
  })
}

// Basic test that validates pages are accessible, basic error check
it('Check Kiali is accessible', function() {
  cy.visit(Cypress.env('url'))
  cy.title().should('contain', 'Kiali')
  expandMenu();
  cy.get('#Graph', { timeout: 15000 }).click();
  cy.get('#Applications', { timeout: 15000 }).click();
  // Check for generic errors (this is the red circle that appears if any connectivity with Promtheus/Grafana/Istio is not working)
  cy.get('svg[fill="var(--pf-global--danger-color--100)"]').should('not.exist');
})

// Allow these tests to be skipped with an env variable
// These tests should only run in BB CI since nothing is istio injected in Package CI
if (Cypress.env("check_data")) {
  it('Check Kiali Graph page loads data', function() {
    cy.visit(Cypress.env('url'))
    cy.title().should("eq", "Kiali");
    expandMenu();
    cy.get('#Graph', { timeout: 15000 }).click();
    collapseMenu();
    cy.get('button[id="namespace-selector"').click()
    cy.get('input[type="checkbox"][value="monitoring"]').click()
    cy.get('button[id="refresh_button"').click({force: true})
    // Check for graph side panel because the main graph is tricky to grab
    cy.get('div[id="graph-side-panel"]', { timeout: 15000 }).should("be.visible")
  })

  it('Check Kiali Applications page loads data', function() {
    cy.visit(Cypress.env('url'))
    cy.title().should("eq", "Kiali");
    expandMenu();
    cy.get('#Applications', { timeout: 15000 }).click();
    collapseMenu();
    cy.get('button[id="namespace-selector"]').click()
    cy.get('input[type="checkbox"][value="monitoring"]').click()
    cy.get('button[id="refresh_button"]').click({force: true})
    // This gets us to the prometheus application
    cy.get(':nth-child(2) > :nth-child(2) > .virtualitem_definition_link', { timeout: 15000 }).click()
    // Validate the graph is visible
    cy.get('#MiniGraphCard > .pf-c-card__body', { timeout: 15000 }).should("be.visible")
    // Load the outbound metrics tab
    // there's nothing easy to check on here since elements are dynamic but we can at least load the page for the video
    cy.get('#pf-tab-3-basic-tabs').click()
    // Load the tracing tab
    cy.get('#pf-tab-4-basic-tabs').click()
    // Validate that error is not displayed
    // NOTE: we don't check for actual traces because there can be delays in them displaying on the webpage
    cy.contains('Error fetching traces').should("not.exist")
  })
}

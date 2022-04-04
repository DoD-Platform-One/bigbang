describe('Kiali Test', function() {
  Cypress.on('uncaught:exception', (err, runnable) => {
    return false
  })

  // Basic test that validates pages are accessible, basic error check
  it('Check Kiali is accessible', function() {
    cy.visit(Cypress.env('url'))
    cy.title().should("eq", "Kiali");
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
      cy.get('#Graph', { timeout: 15000 }).click();
      cy.get('button[id="namespace-selector"').click()
      cy.get('input[type="checkbox"][value="monitoring"]').click()
      cy.get('button[id="refresh_button"').click()
      // Check for graph side panel because the main graph is tricky to grab
      cy.get('div[id="graph-side-panel"]', { timeout: 15000 }).should("be.visible")
    })

    it('Check Kiali Applications page loads data', function() {
      cy.visit(Cypress.env('url'))
      cy.title().should("eq", "Kiali");
      cy.get('#Applications', { timeout: 15000 }).click();
      cy.get('button[id="namespace-selector"]').click()
      cy.get('input[type="checkbox"][value="monitoring"]').click()
      cy.get('button[id="refresh_button"]').click()
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
})

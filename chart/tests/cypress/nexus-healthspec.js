describe('Basic Nexus', function() {
  it('Visit the Nexus sign in page', function() {
    cy.visit(Cypress.env('nexus_url'))
    cy.contains("Sign in").click()
    cy.get('input[name="username"]').type(Cypress.env('nexus_user'))
    cy.get('input[name="password"]').type(Cypress.env('nexus_pass'))
    cy.get('a[class="x-btn x-unselectable x-box-item x-toolbar-item x-btn-nx-primary-small"]').click()
    cy.contains("Next").click()
    cy.get('input[name="password"]').type(Cypress.env('nexus_pass'))
    cy.get('input[name*="nx-password"]').type(Cypress.env('nexus_pass'))
    cy.contains("Next").click({ force: true })
    cy.get('#radio-1205-inputEl').click() //selects "Disable anonymous access radio"
    cy.contains("Next").click({ force: true })
    cy.contains("Next").click({ force: true })
    cy.contains("Finish").click()
    cy.visit(`${Cypress.env('nexus_url')}/#admin/support/status`)
  })        
})

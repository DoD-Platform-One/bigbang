// needs to be fixed
describe('Basic Confluence', function() {
  it('Check Confluence is accessible', function() {
  cy.visit(Cypress.env('url'))
  cy.wait(5000)
  })
})


describe('Basic Podinfo', function() {
  it('Check Podinfo is accessible', function() {
      cy.visit(Cypress.env('url'))
  })
})

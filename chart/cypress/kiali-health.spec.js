describe('Basic Kiali', function() {
  it('Check Kiali UI is accessible', function() {
      cy.visit(Cypress.env('url'))
  })
})

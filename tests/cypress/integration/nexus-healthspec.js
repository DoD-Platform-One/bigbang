describe('Basic prometheus', function() {
    it('Visits the prometheus sign in page', function() {
      cy.visit(Cypress.env('nexus_url'))
    })        
})

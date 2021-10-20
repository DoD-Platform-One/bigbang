describe('Basic Kiali', function() {
  it('Check Kiali UI is accessible', function() {
      cy.visit(Cypress.env('url'))
      cy.title().should("eq", "Kiali");
      cy.get('#Graph', { timeout: 15000 }).click();
      cy.get('#Services').click();
      cy.get('.pf-c-table').should("be.visible");

  })
})

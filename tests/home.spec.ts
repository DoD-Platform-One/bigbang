import { test, expect } from "@playwright/test";

test("homepage has `Big Bang Docs` in title and get started link linking to the intro page", async ({ page }) => {
  await page.goto("/");

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/Big Bang Docs/);


  // Locate link to developer docs
  const devDocsLink = page.locator("text=Developer Contribution Documentation");

  // Click the get started link.
  await devDocsLink.click();

  // Expects the URL to contain intro.
  await expect(page).toHaveURL(/.*docs/);
});

test("all top nav links work", async ({ page }) => {
  await page.goto("/");

  const anchors = await page.locator("a.md-tabs__link");
  const count = await anchors.count();
  // await console.log(count);
  for (let i = 0; i < count; i++) {
    const href = await await anchors.nth(i).getAttribute("href");
    if (href !== ".") {
      const reg = new RegExp(`.*${href}`);
      await anchors.nth(i).click();
      await page.waitForLoadState("domcontentloaded");
      // await console.log(href);
      await expect(page).toHaveURL(reg);
      await page.goto("/");
    }
  }
});

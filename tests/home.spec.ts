import { test, expect, Locator } from "@playwright/test";

async function* iterateLocator(locator: Locator): AsyncGenerator<Locator> {
  for (let index = 0; index < (await locator.count()); index++) {
    yield locator.nth(index);
  }
}

test("homepage has `Big Bang Docs` in title and get started link linking to the intro page", async ({ page }) => {
  await page.goto("/");

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/Big Bang Docs/);

  // create a locator
  const getStarted = page.locator("text=Head on over to");

  // Expect an attribute "to be strictly equal" to the value.
  await expect(getStarted).toHaveAttribute("href", "bigbang/");

  // Click the get started link.
  await getStarted.click();

  // Expects the URL to contain intro.
  await expect(page).toHaveURL(/.*bigbang/);
});

test("all top nav links work", async ({ page }) => {
  await page.goto("/");

  // for await (const a of iterateLocator(page.locator("a .md-tabs__link"))) {
  //   await a.click();
  //   const href = new RegExp(`/.*${a.getAttribute("href")}/`);
  //   console.log(href);
  //   await expect(page).toHaveURL(href);
  //   await page.goBack();
  // }
  const anchors = await page.locator("a.md-tabs__link");
  const count = await anchors.count();
  // await console.log(count);
  for (let i = 0; i < count; i++) {
    const href = await await anchors.nth(i).getAttribute("href");
    if (href !== ".") {
      const reg = new RegExp(`.*${href}`);
      await anchors.nth(i).click();
      await page.waitForLoadState("networkidle");
      // await console.log(href);
      await expect(page).toHaveURL(reg);
      await page.goto("/");
    }
  }
});

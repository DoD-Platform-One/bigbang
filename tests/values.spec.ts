// make sure that last item on values.md is `addons.metricsServer.postRenderers`
import { test, expect } from "@playwright/test";

test("Big Bang's values.md is built + renders properly", async ({ page }) => {
  await page.goto("/values");

  await expect(page).toHaveTitle(/🪙 Values - Big Bang Docs/);

  const tags = page.locator("nav.md-tags .md-tag");
  await expect(await tags.count(), { message: "docs/values.md has more than 1 tag, it should only have `values`" }).toBe(1);
  await expect(await tags.nth(0).innerText()).toBe("values");

  const title = page.locator("h1")
  await expect(title).toHaveId("Big-Bang-valuesyaml");

  const firstEntry = page.locator("h2").first()
  await expect(await firstEntry.innerText()).toBe("domain💣");
  await expect(firstEntry).toHaveId("domain")
});

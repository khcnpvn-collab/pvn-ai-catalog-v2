import { test, expect } from "@playwright/test";

test("signed-out login is accessible and fits the viewport", async ({ page }, testInfo) => {
  const exceptions: string[] = [];
  page.on("pageerror", error => exceptions.push(error.message));
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Đăng nhập", exact: true })).toBeVisible();
  const account = page.getByRole("textbox", { name: /Email hoặc tên tài khoản/ });
  const password = page.getByLabel("Mật khẩu", { exact: true });
  await expect(account).toBeVisible();
  await expect(password).toHaveAttribute("type", "password");
  await expect(account).toHaveAttribute("autocomplete", "username");
  await expect(password).toHaveAttribute("autocomplete", "current-password");
  await account.focus();
  await page.keyboard.press("Tab");
  await expect(password).toBeFocused();
  await page.keyboard.press("Tab");
  await expect(page.getByRole("button", { name: "Đăng nhập", exact: true })).toBeFocused();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  expect(exceptions).toEqual([]);
  await page.screenshot({ path: testInfo.outputPath("login.png"), fullPage: true });
});

test("invalid account shows a real API error and re-enables submission", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("textbox", { name: /Email hoặc tên tài khoản/ }).fill("../invalid");
  await page.getByLabel("Mật khẩu", { exact: true }).fill("invalid-input-never-sent-to-auth");
  const responsePromise = page.waitForResponse(response => response.url().endsWith("/api/auth/login"));
  await page.getByRole("button", { name: "Đăng nhập", exact: true }).click();
  expect((await responsePromise).status()).toBe(400);
  await expect(page.getByRole("main").getByRole("alert")).toContainText("Tên tài khoản không hợp lệ");
  await expect(page.getByRole("button", { name: "Đăng nhập", exact: true })).toBeEnabled();
});

test("session network failure offers a working retry without fabricated data", async ({ page }) => {
  await page.route("**/api/session", route => route.abort("failed"));
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "Chưa thể kết nối ứng dụng" })).toBeVisible();
  await expect(page.getByRole("main").getByRole("alert")).toBeVisible();
  await page.unroute("**/api/session");
  await page.getByRole("button", { name: "Thử lại", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Đăng nhập", exact: true })).toBeVisible();
});

test("direct record and administrative hashes do not bypass the login screen", async ({ page }) => {
  for (const hash of ["sources", "new/unit", "record/f47ac10b-58cc-4372-a567-0e02b2c3d479"]) {
    await page.goto(`/#${hash}`);
    await expect(page.getByRole("heading", { name: "Đăng nhập", exact: true })).toBeVisible();
    await expect(page.getByRole("navigation", { name: "Điều hướng chính" })).toHaveCount(0);
  }
});

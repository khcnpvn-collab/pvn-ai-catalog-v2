import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./tests",
  fullyParallel: true,
  retries: 0,
  workers: 2,
  reporter: [["list"]],
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || "http://localhost:3100",
    channel: "chrome",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  projects: [
    { name: "validation", testMatch: /(?:catalog-validation|survey-display|dossier-presentation|dossier-summary|record-files|document-upload|dashboard-presentation|overview-aggregation|catalog-table)\.spec\.ts/ },
    { name: "api", testMatch: "signed-out-api.spec.ts" },
    { name: "desktop", testMatch: "signed-out-ui.spec.ts", use: { viewport: { width: 1440, height: 1000 } } },
    { name: "mobile", testMatch: "signed-out-ui.spec.ts", use: { viewport: { width: 375, height: 812 }, isMobile: true, hasTouch: true } },
  ],
});

import { readFileSync } from "node:fs";
import { join } from "node:path";
import { expect, test } from "@playwright/test";

const component = readFileSync(join(process.cwd(), "src/components/executive-dashboard.tsx"), "utf8");
const stylesheet = readFileSync(join(process.cwd(), "src/components/executive-dashboard.module.css"), "utf8");

test("dashboard keeps the approved KPI and chart series contracts", () => {
  const kpiSection = component.slice(component.indexOf("const kpis"), component.indexOf("const chartSeries"));
  const chartSection = component.slice(component.indexOf("const chartSeries"), component.indexOf("function LatestBlock"));

  expect([...kpiSection.matchAll(/kind: \"([^\"]+)\"/g)].map(match => match[1])).toEqual([
    "partner",
    "collaboration",
    "expert",
    "use_case",
  ]);
  expect([...chartSection.matchAll(/kind: \"([^\"]+)\"/g)].map(match => match[1])).toEqual([
    "unit",
    "partner",
    "expert",
    "use_case",
    "collaboration",
  ]);
  expect(component).toContain("Cơ cấu danh mục trọng tâm");
});

test("latest blocks use independent first-page requests and preserve API order", () => {
  expect(component).toContain("`/api/records?kind=${kind}&page=1`");
  expect(component).toContain("resource.data?.data.slice(0, 3)");
  expect(component).not.toMatch(/\.sort\s*\(/);
  expect(component).toContain("<ErrorBox error={resource.error} retry={resource.refresh}/>");
  expect(component).toContain("<Empty");
  expect(component).toContain("onOpenRecord(record.id)");
  expect(component).toContain("onOpenModule(kind)");
});

test("dashboard owns a narrow responsive layout without fixed page widths", () => {
  expect(stylesheet).toContain("max-width: 100%");
  expect(stylesheet).toContain("@media (max-width: 420px)");
  expect(stylesheet).toContain("grid-template-columns: minmax(0, 1fr)");
  expect(stylesheet).not.toMatch(/min-width:\s*(?:3[7-9][6-9]|[4-9]\d{2,})px/);
});

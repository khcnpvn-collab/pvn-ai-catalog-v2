import { assignNewRecordCode } from "../src/lib/record-code";
import { test, expect } from "@playwright/test";
import { modules, relations, validateRecord, type RecordInput } from "../src/lib/catalog";

import { dossierPath, dossierSections, readTrail } from "../src/lib/dossier";

const base = (kind = "unit"): RecordInput => ({ kind, title: "Kiểm tra dữ liệu đầu vào", status: modules.find(m => m.kind === kind)!.statuses[0], data: required[kind] || {} });
// Fields every record of a kind must carry.
const required: Record<string, Record<string, string>> = { unit: { unit_type: "Đơn vị thành viên" }, collaboration: { item_group: "Bài toán" }, work_item: { item_group: "Quản trị AI" } };
const reject = (input: unknown) => expect(validateRecord(input as RecordInput)).toEqual(expect.any(String));
const fieldExamples: Record<string, string | number> = { date: "2024-02-29", number: 0, email: "test@example.com", url: "https://example.com/resource" };

for (const entry of modules) {
  test(`${entry.kind}: supports declared fields and rejects fields from outside the module`, () => {
    const data = Object.fromEntries(entry.fields.map(field => [field.key,
      field.options?.[0] ?? fieldExamples[field.type || "text"] ?? "Thông tin có dấu"
    ]));
    expect(validateRecord({ ...base(entry.kind), data })).toBeNull();
    reject({ ...base(entry.kind), data: { ...data, unknown_field: "not allowed" } });
    reject({ ...base(entry.kind), status: "invented status" });
  });
}

test("title and common text fields enforce bounds and scalar types", () => {
  for (const title of ["", "   ", "a".repeat(251), 5, null, [], {}]) reject({ ...base(), title });
  expect(validateRecord({ ...base(), title: "a".repeat(250) })).toBeNull();
  for (const [key, limit] of [["code", 80], ["summary", 10000]] as const) {
    expect(validateRecord({ ...base(), [key]: "a".repeat(limit) })).toBeNull();
    reject({ ...base(), [key]: "a".repeat(limit + 1) });
    for (const value of [7, true, [], {}]) reject({ ...base(), [key]: value });
  }
});

test("unknown and inherited object keys cannot become module names", () => {
  for (const kind of ["missing", "constructor", "__proto__", "toString", "hasOwnProperty", [], {}]) reject({ ...base(), kind });
  reject({ ...base(), data: JSON.parse('{"__proto__":{"admin":true}}') });
  reject({ ...base(), data: JSON.parse('{"constructor":"admin"}') });
});

test("detail values reject objects, arrays and boolean coercion", () => {
  for (const data of [[], "string", 5, false]) reject({ ...base(), data });
  for (const value of [true, false, [], {}, [1], -1, Infinity, NaN, "not a number", "1e2", ".5", " 2 ", "0x10", 100000001]) reject({ ...base("use_case"), data: { start_year: value } });
  for (const value of [0, 1.5, "2", 100000000]) expect(validateRecord({ ...base("use_case"), data: { start_year: value } })).toBeNull();
});

test("strict calendar dates include leap years and chronological ranges", () => {
  for (const value of ["2023-02-29", "2024-02-30", "2024-13-01", "2024-00-01", "2024-1-01", "2024-01-01T00:00:00Z", 0, false, [], {}]) {
    reject({ ...base("engagement"), data: { start_date: value } });
  }
  expect(validateRecord({ ...base("engagement"), data: { start_date: "2024-02-29" } })).toBeNull();
  reject({ ...base("engagement"), data: { start_date: "2026-10-08", end_date: "2026-10-07" } });
  expect(validateRecord({ ...base("collaboration"), data: { item_group: "Bài toán", start_date: "2026-10-08", end_date: "2026-10-08" } })).toBeNull();
});

test("URL, email and enumeration validation excludes executable schemes and invented options", () => {
  for (const url of ["javascript:alert(1)", "data:text/html,<script>alert(1)</script>", "file:///etc/passwd", "not a url"]) reject({ ...base(), data: { website: url } });
  for (const email of ["missing-at.example.com", "a@b", "a b@example.com"]) reject({ ...base("contact"), data: { email } });
  reject({ ...base("collaboration"), data: { item_group: "Nhóm tự đặt" } });
  reject({ ...base("collaboration"), data: { item_group: "Quản trị AI", item_category: "Điện toán đám mây" } });
  expect(validateRecord({ ...base("collaboration"), data: { item_group: "Quản trị AI", item_category: "Chiến lược, kế hoạch AI" } })).toBeNull();
  reject({ ...base("collaboration"), data: {} });
  reject({ ...base("work_item"), data: { item_group: "Quản trị AI", start_date: "2026-13-01" } });
  expect(validateRecord({ ...base("work_item"), data: { item_group: "Quản trị AI", start_date: "2026-11-01" } })).toBeNull();
  reject({ ...base(), data: { conclusion: "Automatically approved" } });
  expect(validateRecord({ ...base(), data: { unit_type: "Đơn vị thành viên", website: "https://example.com" } })).toBeNull();
  reject({ ...base(), data: { website: "https://example.com" } });
});

test("updates require a valid UUID and a positive integer concurrency version", () => {
  const id = "f47ac10b-58cc-4372-a567-0e02b2c3d479";
  for (const version of [undefined, null, 0, -1, 1.5, "1", true, Infinity]) reject({ ...base(), id, version });
  for (const badId of ["not-a-uuid", "' OR 1=1 --", 5, [], {}]) reject({ ...base(), id: badId, version: 1 });
  expect(validateRecord({ ...base(), id, version: 1 })).toBeNull();
  expect(validateRecord({ ...base(), id, version: 32 })).toBeNull();
});


test("dossier navigation centers on entities while section actions use valid catalog kinds and relations", () => {
  const kinds = modules.map(module => module.kind);
  for (const [kind, sections] of Object.entries(dossierSections)) {
    expect(kinds).toContain(kind);
    expect(new Set(sections.map(section => section.id)).size).toBe(sections.length);
    for (const section of sections) {
      for (const relatedKind of section.kinds) expect(kinds).toContain(relatedKind);
      for (const action of section.actions) {
        expect(section.kinds).toContain(action.kind);
        expect(relations.map(relation => relation.value)).toContain(action.relation);
        expect(["to-parent", "from-parent"]).toContain(action.direction);
      }
    }
  }
});

test("the catalog only defines the kinds the app still shows", () => {
  expect(modules.map(module => module.kind).sort()).toEqual(["collaboration", "contact", "engagement", "expert", "partner", "reference", "unit", "use_case", "work_item"]);
});

test("activities start from an item, unit or partner and point at their owner", () => {
  const activityActions = Object.entries(dossierSections).flatMap(([ownerKind, sections]) => sections.flatMap(section => section.actions
    .filter(action => action.kind === "collaboration")
    .map(action => ({ ownerKind, relation: action.relation, direction: action.direction }))));
  expect(activityActions).toEqual([
    { ownerKind: "unit", relation: "unit", direction: "to-parent" },
    { ownerKind: "partner", relation: "partner", direction: "to-parent" },
    { ownerKind: "use_case", relation: "use_case", direction: "to-parent" },
    { ownerKind: "work_item", relation: "use_case", direction: "to-parent" },
    { ownerKind: "expert", relation: "expert", direction: "to-parent" },
  ]);
  expect(dossierSections.unit.find(section => section.id === "activities")!.actions[0].context).toEqual({ subject_role: "lead" });
});

test("dossier drill-down path preserves Vietnamese parent title and active section", () => {
  const trail = [{ id: "f47ac10b-58cc-4372-a567-0e02b2c3d479", title: "Đơn vị A & đối tác", tab: "collaborations" }];
  const path = dossierPath("child-id", "contacts", trail);
  const url = new URL(path, "https://catalog.example/");
  expect(url.pathname).toBe("/record/child-id");
  expect(url.searchParams.get("tab")).toBe("contacts");
  expect(readTrail(url.searchParams.get("trail"))).toEqual(trail);
});

test("dossier return trail ignores malformed entries and limits navigation history", () => {
  for (const value of [null, "{", "null", "{}", "false", '"text"']) expect(readTrail(value)).toEqual([]);
  const valid = { id: "parent-id", title: "Hồ sơ cha", tab: "needs" };
  expect(readTrail(JSON.stringify([null, {}, { ...valid, id: 1 }, { ...valid, tab: null }, valid]))).toEqual([valid]);
  const longTrail = Array.from({ length: 15 }, (_, index) => ({ ...valid, id: String(index) }));
  expect(readTrail(JSON.stringify(longTrail))).toEqual(longTrail.slice(-12));
});


test('new record codes are automatic unique and compatible with imported identifiers', () => {
  const input = base('partner');
  const first = assignNewRecordCode(input);
  const second = assignNewRecordCode(input);
  expect(first.code).toMatch(/^AI-[0-9a-f-]{36}$/);
  expect(second.code).not.toBe(first.code);
  expect(input.code).toBeUndefined();
  expect(validateRecord(first)).toBeNull();
  for (const code of [null, '', '   ']) expect(assignNewRecordCode({...input, code}).code).toMatch(/^AI-/);
  expect(assignNewRecordCode({...input, code: 'WB-legacy-001'}).code).toBe('WB-legacy-001');
});

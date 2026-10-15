import { expect, test } from "@playwright/test";
import { ACTIVITY_STATUSES, ITEM_CATEGORIES, ITEM_GROUPS, PARTNER_STATUSES, STANDARD_GROUP, WORK_ITEM_GROUPS } from "../src/lib/catalog";
import { statusColor, statusTone } from "../src/lib/status-tone";
import { activityPartnerIds, activityTitle, byId, countBy, latestMilestone, matchesSearch, itemActivities, itemPartnerIds, partnerActivities, UNCLASSIFIED, unitActivities, type Overview, type OverviewActivity } from "../src/lib/overview";

const at = "2026-10-14T00:00:00Z";
const activity = (id: string, fields: Partial<OverviewActivity>): OverviewActivity => ({ id, title: id, updated_at: at, status: "Đề xuất", item_group: "Bài toán", item_category: null, start_date: null, end_date: null, partner_id: null, provider_unit_id: null, party_lead_id: null, standard_id: null, work_item_id: null, lead_unit_id: null, unit_ids: [], ...fields });
const overview: Overview = {
  standards: [{ id: "s1", title: "Bài toán", updated_at: at, code: "BTC-01", status: "Đang thực hiện", program: "AI cho tìm kiếm, thăm dò và khai thác", category: null, is_priority: "Có", leadership_level: null, start_year: 2026, lead_unit_id: "u1", potential_unit_ids: ["u2"], potential_partner_ids: [] }],
  work_items: [{ id: "w1", title: "GPU dùng chung", updated_at: at, code: "HT-01", status: "Đang thực hiện", item_group: "Nền tảng, hạ tầng, công nghệ", scope_level: "Tập đoàn", apply_scope: "Toàn Tập đoàn", owner: null, coordinator: null, start_date: "2026-11-01", unit_ids: [] }],
  activities: [
    activity("a1", { status: "POC", partner_id: "consortium", standard_id: "s1", lead_unit_id: "u1", unit_ids: ["u1"] }),
    activity("a2", { status: "Vận hành", partner_id: "p1", standard_id: "s1", lead_unit_id: "u2", unit_ids: ["u2", "u1"] }),
    activity("a3", { partner_id: "p2", item_group: "Nền tảng, hạ tầng, công nghệ", work_item_id: "w1" }),
    activity("a5", { provider_unit_id: "u1", lead_unit_id: "u3", unit_ids: ["u3"] }),
  ],
  partners: [
    { id: "consortium", title: "Liên danh", updated_at: at, status: "Tiềm năng", short_name: null, partner_type: null, country: null, member_ids: ["p1", "p2"] },
    { id: "p1", title: "Đối tác một", updated_at: at, status: "Đang hợp tác", short_name: null, partner_type: null, country: null, member_ids: [] },
    { id: "p2", title: "Đối tác hai", updated_at: at, status: "Tiềm năng", short_name: null, partner_type: null, country: null, member_ids: [] },
  ],
  units: [], experts: [],
  milestones: [
    { id: "m1", title: "Cũ", updated_at: at, status: "Đã diễn ra", start_date: "2026-01-02", end_date: null, period_label: null, partner_ids: [], unit_ids: [], activity_ids: [] },
    { id: "m2", title: "Mới", updated_at: at, status: "Đã diễn ra", start_date: "2026-09-01", end_date: null, period_label: null, partner_ids: [], unit_ids: [], activity_ids: [] },
    { id: "m3", title: "Chưa rõ ngày", updated_at: "2026-10-01T00:00:00Z", status: "Dự kiến", start_date: null, end_date: null, period_label: "Quý IV", partner_ids: [], unit_ids: [], activity_ids: [] },
  ],
};

test("counts keep the lifecycle order and put unclassified values last", () => {
  const counts = countBy([...overview.activities, activity("a4", { status: "" })], item => item.status, ACTIVITY_STATUSES);
  expect(counts).toEqual([{ label: "Đề xuất", value: 2 }, { label: "POC", value: 1 }, { label: "Vận hành", value: 1 }, { label: UNCLASSIFIED, value: 1 }]);
});

test("an activity signed by a consortium counts for every member partner", () => {
  const partners = byId(overview.partners);
  expect(activityPartnerIds(overview.activities[0], partners)).toEqual(["consortium", "p1", "p2"]);
  expect(partnerActivities(overview, "p1").map(item => item.id)).toEqual(["a1", "a2"]);
  expect(partnerActivities(overview, "p2").map(item => item.id)).toEqual(["a1", "a3"]);
  expect(itemPartnerIds(overview, "s1").sort()).toEqual(["consortium", "p1", "p2"]);
});

test("unit activities include coordinating units and work done for another unit", () => {
  expect(unitActivities(overview, "u1").map(item => item.id)).toEqual(["a1", "a2", "a5"]);
});

test("the latest milestone prefers dated entries", () => {
  expect(latestMilestone(overview.milestones)?.id).toBe("m2");
  expect(latestMilestone([])).toBeNull();
});

test("search ignores Vietnamese accents and case", () => {
  expect(matchesSearch("dau khi", "Tổng công ty Thăm dò Khai thác Dầu khí")).toBe(true);
  expect(matchesSearch("ĐỐI TÁC", "đối tác một")).toBe(true);
  expect(matchesSearch("không có", "Đối tác")).toBe(false);
  expect(matchesSearch("", null)).toBe(true);
});

test("every lifecycle and partner status has its own colour, shared by badges and charts", () => {
  const tones = ACTIVITY_STATUSES.map(statusTone);
  expect(tones.every(Boolean)).toBe(true);
  expect(new Set(tones).size).toBe(ACTIVITY_STATUSES.length);
  expect(PARTNER_STATUSES.every(status => statusTone(status))).toBe(true);
  expect(statusTone("Không rõ")).toBeNull();
  expect(statusColor("POC")).not.toBe(statusColor("Vận hành"));
});

test("an activity title drops the partner or unit whose page is showing it", () => {
  expect(activityTitle("Amazon Web Services (AWS) · PTSC", ["Amazon Web Services (AWS)"])).toBe("PTSC");
  expect(activityTitle("Phát hiện bất thường · PVPGB · Amazon Web Services (AWS)", ["amazon web services (aws)"])).toBe("Phát hiện bất thường · PVPGB");
  expect(activityTitle("Quản lý dự án · PVCHEM", ["Tổng công ty Hóa chất", "PVCHEM"])).toBe("Quản lý dự án");
  expect(activityTitle("PVCHEM", ["PVCHEM"])).toBe("PVCHEM");
  expect(activityTitle("Trợ lý AI", [null, ""])).toBe("Trợ lý AI");
});

test("six item groups start with standard problems and each has its own detailed categories", () => {
  expect(ITEM_GROUPS).toEqual([STANDARD_GROUP, ...WORK_ITEM_GROUPS]);
  expect(ITEM_GROUPS).toHaveLength(6);
  for (const group of ITEM_GROUPS) expect(ITEM_CATEGORIES[group].length).toBeGreaterThan(0);
  const all = Object.values(ITEM_CATEGORIES).flat();
  expect(new Set(all).size).toBe(all.length);
});

test("items gather their activities and partners whether standard problems or work items", () => {
  expect(itemActivities(overview, "s1").map(item => item.id)).toEqual(["a1", "a2"]);
  expect(itemActivities(overview, "w1").map(item => item.id)).toEqual(["a3"]);
  expect(itemPartnerIds(overview, "w1")).toEqual(["p2"]);
});

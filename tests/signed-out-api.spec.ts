import { test, expect } from "@playwright/test";

test("session and all data reads refuse unauthenticated access without leaking records", async ({ request }) => {
  for (const path of ["session", "stats", "records", "records?kind=unit", "records/f47ac10b-58cc-4372-a567-0e02b2c3d479", "records/f47ac10b-58cc-4372-a567-0e02b2c3d479/dossier", "records/f47ac10b-58cc-4372-a567-0e02b2c3d479/survey", "documents", "documents/f47ac10b-58cc-4372-a567-0e02b2c3d479/download"]) {
    const response = await request.get(`/api/${path}`);
    expect(response.status(), path).toBe(401);
    expect(response.headers()["cache-control"]).toBe("no-store");
    const body = await response.json();
    expect(body).toEqual({ error: expect.any(String) });
  }
});

test("cross-origin and originless mutations are rejected before authentication", async ({ request, baseURL }) => {
  const cases: Record<string, string>[] = [{}, { Origin: "https://untrusted.example" }, { Origin: baseURL!, "Sec-Fetch-Site": "cross-site" }];
  for (const headers of cases) {
    const response = await request.post("/api/auth/login", { headers, data: { account: "", password: "" } });
    expect(response.status()).toBe(403);
  }
});

test("signed-out writes cannot create records, links, source snapshots or files", async ({ request, baseURL }) => {
  for (const path of ["records", "records/f47ac10b-58cc-4372-a567-0e02b2c3d479/related", "records/f47ac10b-58cc-4372-a567-0e02b2c3d479/restore", "links", "documents", "documents/link", "sources"]) {
    const response = await request.post(`/api/${path}`, { headers: { Origin: baseURL! }, data: {} });
    expect(response.status(), path).toBe(401);
  }
});

test("login rejects malformed content and oversized bodies locally", async ({ request, baseURL }) => {
  const headers = { Origin: baseURL!, "Content-Type": "application/json" };
  for (const data of ["{", "null", "[]", "true", '{"account":{},"password":[]}', '{"account":"../invalid","password":"x"}']) {
    const response = await request.post("/api/auth/login", { headers, data });
    expect(response.status(), data).toBe(400);
    expect(await response.json()).toEqual({ error: expect.any(String) });
  }
  const contentType = await request.post("/api/auth/login", { headers: { Origin: baseURL!, "Content-Type": "text/plain" }, data: "{}" });
  expect(contentType.status()).toBe(415);
  const tooLarge = await request.post("/api/auth/login", { headers, data: JSON.stringify({ account: "a".repeat(1024 * 1024), password: "x" }) });
  expect(tooLarge.status()).toBe(413);
});

test("streamed JSON is bounded even without a Content-Length header", async ({ baseURL }) => {
  const encoder = new TextEncoder();
  const body = new ReadableStream<Uint8Array>({
    start(controller) {
      controller.enqueue(encoder.encode('{"account":"'));
      controller.enqueue(encoder.encode("a".repeat(600_000)));
      controller.enqueue(encoder.encode("b".repeat(600_000)));
      controller.enqueue(encoder.encode('","password":"x"}'));
      controller.close();
    },
  });
  const options: RequestInit & { duplex: "half" } = {
    method: "POST", headers: { Origin: baseURL!, "Content-Type": "application/json" }, body, duplex: "half",
  };
  const response = await fetch(`${baseURL}/api/auth/login`, options);
  expect(response.status).toBe(413);
  expect(await response.json()).toEqual({ error: expect.any(String) });
});


test("delete rejects originless and cross-origin mutations before touching records", async ({ request, baseURL }) => {
  const cases: Record<string, string>[] = [{}, { Origin: "https://untrusted.example" }, { Origin: baseURL!, "Sec-Fetch-Site": "cross-site" }];
  for (const headers of cases) {
    const response = await request.delete("/api/records/f47ac10b-58cc-4372-a567-0e02b2c3d479", { headers, data: { version: 2 } });
    expect(response.status()).toBe(403);
    expect(await response.json()).toEqual({ error: expect.any(String) });
  }
});

test("dashboard overview requires a signed-in member", async ({ request }) => {
  const response = await request.get("/api/overview");
  expect(response.status()).toBe(401);
  expect(await response.json()).toEqual({ error: expect.any(String) });
});

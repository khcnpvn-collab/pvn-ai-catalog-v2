import { NextResponse } from "next/server";
import { createHash, randomUUID } from "node:crypto";
import { authorized, ApiError, boundedBody, configured, databaseError, jsonBody, sameOrigin, supabase } from "@/lib/server";
import { moduleMap, relations, UUID, validateRecord, type CatalogRecord, type RecordInput } from "@/lib/catalog";
import { assignNewRecordCode } from "@/lib/record-code";
import { DOCUMENT_FORMAT_HINT, MAX_DOCUMENT_BYTES, MAX_DOCUMENT_MIB, documentMimeType } from "@/lib/document-upload";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
const BUCKET = "ai-catalog-documents";
const MAX_FILE = MAX_DOCUMENT_BYTES;
const response = (value: unknown, status = 200) => NextResponse.json(value, { status, headers: { "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff" } });
const id = (value: unknown) => { if (typeof value !== "string" || !UUID.test(value)) throw new ApiError(400, "Mã hồ sơ không hợp lệ."); return value; };
function rpcError(error: { message: string; code?: string } | null) { if (error) throw databaseError(error); }
function relationContext(value: unknown): Record<string, string> {
  if (value == null) return {};
  if (typeof value !== "object" || Array.isArray(value) || Object.entries(value).some(([key, item]) => key.length > 80 || typeof item !== "string" || item.length > 1000)) throw new ApiError(400, "Thông tin thành phần không hợp lệ.");
  return value as Record<string, string>;
}
function missingRpc(error: { message?: string; code?: string } | null, name: string) {
  return Boolean(error && (error.code === "PGRST202" || error.message?.includes(name)));
}

async function handle(request: Request, context: { params: Promise<{ path: string[] }> }) {
  try {
    const { path } = await context.params;
    const route = path.join("/"); const method = request.method;
    const url = new URL(request.url);
    const mutation = method !== "GET";
    if (mutation) sameOrigin(request);

    if (route === "session" && method === "GET") {
      if (!configured()) return response({ data: { user: null, membership: null, configured: false } });
      const client = await supabase();
      const { data: { user } } = await client.auth.getUser();
      if (!user) throw new ApiError(401, "Vui lòng đăng nhập.");
      const { data: membership, error } = await client.rpc("ai_catalog_membership"); rpcError(error);
      return response({ data: { user: { id: user.id, email: user.email }, membership, configured: true } });
    }
    if (route === "auth/login" && method === "POST") {
      const body = await jsonBody(request);
      if (typeof body.account !== "string" || typeof body.password !== "string" || !body.password || body.password.length > 1000 || body.account.length > 254) throw new ApiError(400, "Vui lòng nhập tài khoản và mật khẩu.");
      const account = body.account.trim().toLowerCase();
      if (!account.includes("@") && !/^[a-z0-9][a-z0-9._-]{0,63}$/.test(account)) throw new ApiError(400, "Tên tài khoản không hợp lệ.");
      const email = account.includes("@") ? account : `${account}@pvn.vn`;
      const client = await supabase();
      const { error } = await client.auth.signInWithPassword({ email, password: body.password });
      if (error) throw new ApiError(error.status === 429 ? 429 : 401, error.status === 429 ? "Đăng nhập quá nhiều lần. Vui lòng thử lại sau." : "Tài khoản hoặc mật khẩu chưa đúng.");
      return response({ data: true });
    }
    if (route === "auth/logout" && method === "POST") {
      const client = await supabase(); await client.auth.signOut({ scope: "local" }); return response({ data: true });
    }
    const unitSurvey = path[0] === "records" && path.length === 3 && path[2] === "survey";
    const { client, user } = await authorized(mutation, unitSurvey);
    const rpc = async (name: string, params: Record<string, unknown> = {}) => { const { data, error } = await client.rpc(name, params); rpcError(error); return data; };
    const replaceLinkContext = async (link: Record<string, unknown>, context: Record<string, string>) => {
      const payload = { source_id: link.source_id, target_id: link.target_id, relation: link.relation, note: typeof link.note === "string" ? link.note : undefined, context };
      await rpc("ai_catalog_unlink", { p_id: id(link.id) });
      try { return await rpc("ai_catalog_link", { p_link: payload }); }
      catch (error) {
        try { await rpc("ai_catalog_link", { p_link: { ...payload, context: relationContext(link.context) } }); } catch { /* Preserve the original error. */ }
        throw error;
      }
    };
    const setConsortiumRole = async (sourceId: string, targetId: string, role: "lead" | "member") => {
      const detail = await rpc("ai_catalog_get", { p_id: sourceId }) as { links?: Record<string, unknown>[] };
      const links = (detail.links || []).filter(link => link.source_id === sourceId && link.relation === "partner");
      const current = links.find(link => link.target_id === targetId);
      if (!current) throw new ApiError(409, "Liên kết liên danh chưa được tạo.");
      if (role === "lead") {
        for (const link of links) {
          const context = relationContext(link.context);
          const value = String(context.consortium_role || context.role || context["Vai trò"] || "").toLocaleLowerCase("vi");
          if (link.id !== current.id && (value === "lead" || value.includes("đầu mối") || value.includes("đứng đầu"))) {
            await replaceLinkContext(link, { ...context, role: "", "Vai trò": "", consortium_role: "member" });
          }
        }
      }
      return replaceLinkContext(current, { ...relationContext(current.context), role: "", "Vai trò": "", consortium_role: role });
    };
    const setCollaborationSubjectRole = async (sourceId: string, targetId: string, role: "lead" | "supporting", requestedContext: Record<string, string>, note?: string) => {
      const detail = await rpc("ai_catalog_get", { p_id: sourceId }) as { data?: CatalogRecord; links?: Record<string, unknown>[] };
      if (!["collaboration", "use_case"].includes(String(detail.data?.kind))) throw new ApiError(400, "Vai trò đơn vị chỉ áp dụng cho hoạt động và bài toán chuẩn.");
      const links = (detail.links || []).filter(link => link.source_id === sourceId && link.relation === "unit");
      const current = links.find(link => link.target_id === targetId);
      const demoted: { link: Record<string, unknown>; context: Record<string, string> }[] = [];
      try {
        if (role === "lead") {
          for (const link of links) {
            const context = relationContext(link.context);
            if (link.id !== current?.id && context.subject_role === "lead") {
              demoted.push({ link, context });
              await replaceLinkContext(link, { ...context, subject_role: "supporting" });
            }
          }
        }
        if (current) return await replaceLinkContext(current, { ...relationContext(current.context), ...requestedContext, subject_role: role });
        return await rpc("ai_catalog_link", { p_link: { source_id: sourceId, target_id: targetId, relation: "unit", ...(note ? { note } : {}), context: { ...requestedContext, subject_role: role } } });
      } catch (error) {
        for (const item of demoted.reverse()) {
          try {
            const refreshed = await rpc("ai_catalog_get", { p_id: sourceId }) as { links?: Record<string, unknown>[] };
            const link = (refreshed.links || []).find(candidate => candidate.source_id === item.link.source_id && candidate.target_id === item.link.target_id && candidate.relation === "unit");
            if (link) await replaceLinkContext(link, item.context);
          } catch { /* Preserve the original error. */ }
        }
        throw error;
      }
    };

    if (route === "stats" && method === "GET") return response({ data: await rpc("ai_catalog_stats") });
    if (route === "overview" && method === "GET") return response({ data: await rpc("ai_catalog_overview") });
    if (route === "directory" && method === "GET") return response({ data: await rpc("ai_catalog_directory") });
    if (unitSurvey && method === "GET") return response({ data: await rpc("ai_catalog_unit_survey", { p_id: id(path[1]) }) });
    if (path[0] === "records" && path.length === 3 && path[2] === "dossier" && method === "GET") {
      return response(await rpc("ai_catalog_dossier", { p_id: id(path[1]) }));
    }
    if (path[0] === "records" && path.length === 3 && path[2] === "related" && method === "POST") {
      const parentId = id(path[1]);
      const body = await jsonBody(request);
      if (Object.keys(body).some(key => !["record", "relation", "direction", "context"].includes(key)) ||
          !["to-parent", "from-parent"].includes(String(body.direction)) ||
          !relations.some(relation => relation.value === body.relation)) throw new ApiError(400, "Liên kết hồ sơ không hợp lệ.");
      const record = body.record as RecordInput;
      const invalid = validateRecord(record);
      if (invalid) throw new ApiError(400, invalid);
      if (Object.hasOwn(record, "id")) throw new ApiError(400, "Không cung cấp mã khi tạo mới.");
      const prepared = assignNewRecordCode({ ...record, title: record.title.trim() });
      const linkContext = relationContext(body.context);
      if (linkContext.consortium_role != null && (body.relation !== "partner" || !["lead", "member"].includes(linkContext.consortium_role))) throw new ApiError(400, "Vai trò liên danh không hợp lệ.");
      const contextual = await client.rpc("ai_catalog_create_related_context", {
        p_parent_id: parentId, p_record: prepared, p_relation: body.relation, p_direction: body.direction, p_context: linkContext,
      });
      if (!contextual.error) return response({ data: contextual.data }, 201);
      if (!missingRpc(contextual.error, "ai_catalog_create_related_context")) rpcError(contextual.error);
      const created = await rpc("ai_catalog_create_related", { p_parent_id: parentId, p_record: prepared, p_relation: body.relation, p_direction: body.direction }) as CatalogRecord;
      if (typeof linkContext.consortium_role === "string") {
        const sourceId = body.direction === "to-parent" ? created.id : parentId;
        const targetId = body.direction === "to-parent" ? parentId : created.id;
        try { await setConsortiumRole(sourceId, targetId, linkContext.consortium_role === "lead" ? "lead" : "member"); }
        catch (error) {
          try {
            const detail = await rpc("ai_catalog_get", { p_id: sourceId }) as { links?: Record<string, unknown>[] };
            const link = (detail.links || []).find(item => item.source_id === sourceId && item.target_id === targetId && item.relation === "partner");
            if (link?.id) await rpc("ai_catalog_unlink", { p_id: id(link.id) });
            await rpc("ai_catalog_delete", { p_id: created.id, p_version: created.version });
          } catch { /* Preserve the contextual-link error. */ }
          throw error;
        }
      }
      return response({ data: created }, 201);
    }
    if (route === "records" && method === "GET") {
      const kind = url.searchParams.get("kind"); const page = Number(url.searchParams.get("page") || 1);
      if (kind && !moduleMap[kind]) throw new ApiError(400, "Loại hồ sơ không hợp lệ.");
      if (!Number.isInteger(page) || page < 1 || page > 100000) throw new ApiError(400, "Số trang không hợp lệ.");
      return response(await rpc("ai_catalog_list", { p_kind: kind || null, p_query: (url.searchParams.get("q") || "").slice(0, 250), p_status: url.searchParams.get("status") || null, p_page: page }));
    }
    if ((route === "records" && method === "POST") || (path[0] === "records" && path.length === 2 && method === "PATCH")) {
      const body = await jsonBody(request);
      const allowed = ["id", "kind", "title", "code", "summary", "status", "version", "data"];
      if (Object.keys(body).some(k => !allowed.includes(k))) throw new ApiError(400, "Yêu cầu chứa trường không hợp lệ.");
      if (method === "PATCH") body.id = id(path[1]);
      else if (body.id) throw new ApiError(400, "Không cung cấp mã khi tạo mới.");
      const invalid = validateRecord(body as RecordInput); if (invalid) throw new ApiError(400, invalid);
      body.title = String(body.title).trim();
      return response({ data: await rpc("ai_catalog_save", { p_record: method === "POST" ? assignNewRecordCode(body as RecordInput) : body }) }, method === "POST" ? 201 : 200);
    }
    if (path[0] === "records" && path.length === 2) {
      const recordId = id(path[1]);
      if (method === "GET") return response(await rpc("ai_catalog_get", { p_id: recordId }));
      if (method === "DELETE") { const body = await jsonBody(request); if (!Number.isInteger(body.version) || Number(body.version) < 1) throw new ApiError(400, "Thiếu phiên bản hồ sơ."); return response({ data: await rpc("ai_catalog_delete", { p_id: recordId, p_version: body.version }) }); }
    }
    if (route === "links" && method === "POST") {
      const body = await jsonBody(request); id(body.source_id); id(body.target_id);
      if (!relations.some(r => r.value === body.relation)) throw new ApiError(400, "Loại liên kết không hợp lệ.");
      if (body.note != null && (typeof body.note !== "string" || body.note.length > 5000)) throw new ApiError(400, "Ghi chú quá dài.");
      if (body.context != null) body.context = relationContext(body.context);
      if (typeof (body.context as Record<string, unknown> | undefined)?.subject_role === "string") {
        const requestedRole = (body.context as Record<string, string>).subject_role;
        if (body.relation !== "unit" || !["lead", "supporting"].includes(requestedRole)) throw new ApiError(400, "Vai trò đơn vị không hợp lệ.");
        const contextual = await client.rpc("ai_catalog_collaboration_unit_link", { p_link: body });
        if (!contextual.error) return response({ data: contextual.data }, 201);
        if (!missingRpc(contextual.error, "ai_catalog_collaboration_unit_link")) rpcError(contextual.error);
        return response({ data: await setCollaborationSubjectRole(body.source_id as string, body.target_id as string, requestedRole as "lead" | "supporting", body.context as Record<string, string>, typeof body.note === "string" ? body.note : undefined) }, 201);
      }
      if (typeof (body.context as Record<string, unknown> | undefined)?.consortium_role === "string") {
        if (body.relation !== "partner" || !["lead", "member"].includes((body.context as Record<string, string>).consortium_role)) throw new ApiError(400, "Vai trò liên danh không hợp lệ.");
        const contextual = await client.rpc("ai_catalog_consortium_link", { p_link: body });
        if (!contextual.error) return response({ data: contextual.data }, 201);
        if (!missingRpc(contextual.error, "ai_catalog_consortium_link")) rpcError(contextual.error);
        const requestedRole = (body.context as Record<string, string>).consortium_role === "lead" ? "lead" : "member";
        await rpc("ai_catalog_link", { p_link: { ...body, context: { ...(body.context as Record<string, string>), consortium_role: "member" } } });
        return response({ data: await setConsortiumRole(body.source_id as string, body.target_id as string, requestedRole) }, 201);
      }
      return response({ data: await rpc("ai_catalog_link", { p_link: body }) }, 201);
    }
    if (path[0] === "links" && path.length === 2 && method === "DELETE") return response({ data: await rpc("ai_catalog_unlink", { p_id: id(path[1]) }) });
    if (route === "documents" && method === "GET") return response({ data: await rpc("ai_catalog_documents", { p_query: (url.searchParams.get("q") || "").slice(0, 250) }) });
    if (route === "documents" && method === "POST") {
      const length = Number(request.headers.get("content-length") || "0");
      if (length > MAX_FILE + 1024 * 1024) throw new ApiError(413, `Tệp tối đa ${MAX_DOCUMENT_MIB} MB.`);
      if (!request.headers.get("content-type")?.startsWith("multipart/form-data")) throw new ApiError(415, "Cần gửi biểu mẫu tải tệp.");
      const bytesReceived = await boundedBody(request, MAX_FILE + 1024 * 1024);
      let form: FormData;
      try { form = await new Response(new Uint8Array(bytesReceived), { headers: { "Content-Type": request.headers.get("content-type")! } }).formData(); }
      catch { throw new ApiError(400, "Biểu mẫu tải tệp không hợp lệ."); }
      const file = form.get("file");
      if (!(file instanceof File) || file.size <= 0 || file.size > MAX_FILE) throw new ApiError(400, `Chọn một tệp có nội dung, tối đa ${MAX_DOCUMENT_MIB} MB.`);
      const ext = file.name.split(".").pop()?.toLowerCase() || "";
      const mime = documentMimeType(file.name, file.type);
      if (!mime) throw new ApiError(400, `Hỗ trợ ${DOCUMENT_FORMAT_HINT}`);
      const title = String(form.get("title") || file.name).trim();
      if (!title || title.length > 250) throw new ApiError(400, "Tên tài liệu tối đa 250 ký tự.");
      const documentId = form.get("document_id") ? id(form.get("document_id")) : null;
      const recordId = form.get("record_id") ? id(form.get("record_id")) : null;
      // Check the record before upload. Registration checks document write access
      // transactionally; failed registration removes the unregistered object.
      if (recordId) await rpc("ai_catalog_get", { p_id: recordId });
      const versionId = randomUUID();
      const filename = file.name.replace(/[\r\n/\\\x00-\x1f]/g, "_").slice(0, 180);
      const storagePath = `${user.id}/${versionId}/file.${ext}`;
      const bytes = Buffer.from(await file.arrayBuffer());
      const { error: uploadError } = await client.storage.from(BUCKET).upload(storagePath, bytes, { contentType: mime, upsert: false });
      if (uploadError) throw new ApiError(500, "Chưa thể tải tệp lên kho tài liệu. Kiểm tra quyền hoặc thử lại.");
      try {
        const data = await rpc("ai_catalog_document_save", { p_document: { title, document_id: documentId, record_id: recordId, version_id: versionId, filename, mime_type: mime, size_bytes: bytes.length, storage_path: storagePath, checksum: createHash("sha256").update(bytes).digest("hex") } });
        return response({ data }, 201);
      } catch (error) { await client.storage.from(BUCKET).remove([storagePath]); throw error; }
    }
    if (route === "documents/link" && method === "POST") {
      const body = await jsonBody(request);
      return response({ data: await rpc("ai_catalog_document_link", { p_record_id: id(body.record_id), p_document_id: id(body.document_id), p_version_id: body.version_id ? id(body.version_id) : null }) });
    }
    if (path[0] === "documents" && path.length === 3 && path[2] === "link" && method === "DELETE") {
      const body = await jsonBody(request);
      return response({ data: await rpc("ai_catalog_document_unlink", { p_record_id: id(body.record_id), p_document_id: id(path[1]) }) });
    }
    if (path[0] === "documents" && path.length === 2 && method === "DELETE") {
      return response({ data: await rpc("ai_catalog_document_archive", { p_document_id: id(path[1]) }) });
    }
    if (path[0] === "documents" && path[2] === "download" && path.length === 3 && method === "GET") {
      const data = await rpc("ai_catalog_download", { p_version_id: id(path[1]) });
      const preview = url.searchParams.get("preview") === "1";
      const { data: signed, error } = await client.storage.from(BUCKET).createSignedUrl(data.storage_path, 60, preview ? {} : { download: data.filename });
      if (error || !signed) throw new ApiError(403, "Không thể tải tài liệu này.");
      return NextResponse.redirect(signed.signedUrl, { status: 302, headers: { "Cache-Control": "no-store", "Referrer-Policy": "no-referrer" } });
    }
    throw new ApiError(404, "Không tìm thấy chức năng.");
  } catch (error) {
    if (error instanceof ApiError) return response({ error: error.message }, error.status);
    console.error("Catalog request failed", { type: error instanceof Error ? error.name : "unknown" });
    return response({ error: "Không thể hoàn tất yêu cầu. Vui lòng thử lại." }, 500);
  }
}
export const GET = handle;
export const POST = handle;
export const PATCH = handle;
export const DELETE = handle;

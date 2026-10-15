import "server-only";
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import type { Membership } from "./catalog";

export class ApiError extends Error {
  constructor(public status: number, message: string) { super(message); }
}
export const configured = () => !!(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
export async function supabase() {
  if (!configured()) throw new ApiError(503, "Chưa cấu hình kết nối cơ sở dữ liệu.");
  const jar = await cookies();
  return createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    cookieOptions: { name: "pvn-ai-catalog-session", httpOnly: true, sameSite: "lax", secure: process.env.NODE_ENV === "production", path: "/" },
    cookies: { getAll: () => jar.getAll(), setAll: values => values.forEach(({ name, value, options }) => jar.set(name, value, options)) },
  });
}
export async function authorized(write = false, admin = false) {
  const client = await supabase();
  const { data: { user }, error } = await client.auth.getUser();
  if (error || !user) throw new ApiError(401, "Vui lòng đăng nhập để tiếp tục.");
  const { data, error: membershipError } = await client.rpc("ai_catalog_membership");
  if (membershipError) throw databaseError(membershipError);
  const membership = data as Membership | null;
  if (!membership) throw new ApiError(403, "Tài khoản chưa được cấp quyền sử dụng app quản trị. Vui lòng liên hệ quản trị viên.");
  if ((write && membership.role === "reader") || (admin && membership.role !== "admin")) throw new ApiError(403, "Bạn không có quyền thực hiện thao tác này.");
  return { client, user, membership };
}
export function databaseError(error: { message: string; code?: string }): ApiError {
  if (/PGRST202|PGRST106|42883|42P01/.test(error.code ?? "")) return new ApiError(503, "Kết nối database đã cấu hình. Vùng dữ liệu quản trị chưa được khởi tạo hoặc chưa sẵn sàng.");
  if (/CONFLICT/i.test(error.message)) return new ApiError(409, "Hồ sơ đã được người khác cập nhật. Vui lòng tải lại trước khi lưu.");
  if (/FORBIDDEN|permission denied/i.test(error.message) || error.code === "42501") return new ApiError(403, "Bạn không có quyền truy cập nội dung này.");
  if (/NOT_FOUND/i.test(error.message)) return new ApiError(404, "Không tìm thấy hồ sơ hoặc bạn không có quyền xem.");
  if (error.code === "23505") return new ApiError(409, "Mã hoặc liên kết này đã tồn tại.");
  if (/VALIDATION/i.test(error.message) || /^22|^23/.test(error.code ?? "")) return new ApiError(400, "Dữ liệu không hợp lệ. Kiểm tra thông tin, loại liên kết và hồ sơ cha.");
  console.error("Catalog database request failed", { code: error.code });
  return new ApiError(500, "Không thể xử lý dữ liệu lúc này. Vui lòng thử lại.");
}
export function sameOrigin(request: Request) {
  const origin = request.headers.get("origin");
  if (!origin || origin !== new URL(request.url).origin) throw new ApiError(403, "Yêu cầu phải được gửi từ chính ứng dụng.");
  if (request.headers.get("sec-fetch-site") === "cross-site") throw new ApiError(403, "Yêu cầu không hợp lệ.");
}
export async function jsonBody(request: Request): Promise<Record<string, unknown>> {
  if (!request.headers.get("content-type")?.includes("application/json")) throw new ApiError(415, "Cần gửi dữ liệu JSON.");
  const bytes = await boundedBody(request, 1024 * 1024);
  try {
    const value = JSON.parse(bytes.toString("utf8"));
    if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error();
    return value;
  } catch { throw new ApiError(400, "Nội dung JSON không hợp lệ."); }
}
export async function boundedBody(request: Request, limit: number): Promise<Buffer> {
  const reader = request.body?.getReader();
  if (!reader) throw new ApiError(400, "Thiếu nội dung yêu cầu.");
  const chunks: Uint8Array[] = []; let length = 0;
  for (;;) { const { done, value } = await reader.read(); if (done) break; length += value.byteLength; if (length > limit) { await reader.cancel(); throw new ApiError(413, "Dữ liệu tải lên vượt quá giới hạn cho phép."); } chunks.push(value); }
  return Buffer.concat(chunks);
}

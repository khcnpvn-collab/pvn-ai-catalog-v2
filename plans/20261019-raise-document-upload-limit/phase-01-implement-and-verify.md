# Triển khai và xác minh

1. Đổi ngưỡng giao diện/API sang 50 MiB và thông báo tương ứng; giữ kiểm tra chính xác tại ngưỡng và byte kế tiếp.
2. Viết migration bổ sung: constraint `document_versions.size_bytes` tối đa 100 MiB, bucket `ai-catalog-documents` tối đa 50 MiB, gateway `ai_catalog_document_save` nhận các đuôi tệp UI đang cho phép.
3. Chạy kiểm tra tài liệu và SQL biệt lập; typecheck, lint, build. Sau đó áp dụng migration qua Supabase MCP và đối chiếu cấu hình thật.
4. Cập nhật tài liệu kiến trúc/hợp đồng và ghi rõ giới hạn gói Supabase. Sau khi người dùng nâng gói, thay trần global/bucket/app sang 100 MiB trong cùng đợt kiểm chứng.

Rủi ro: gửi tệp lớn qua Next API tiêu thụ bộ nhớ của tiến trình; ở mức 50 MiB vẫn dùng luồng hiện hữu. Đổi sang upload resumable nếu vận hành thực tế cho thấy lỗi timeout hoặc cần dung lượng lớn hơn. Rollback bằng migration tiến lên đặt bucket/app lại 20 MiB và constraint DB theo yêu cầu dữ liệu hiện hữu; không hạ constraint nếu đã có tệp lớn.

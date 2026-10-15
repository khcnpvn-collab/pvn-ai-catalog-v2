export const MAX_DOCUMENT_BYTES = 20 * 1024 * 1024;
export const DOCUMENT_EXTENSIONS = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', 'png', 'jpg', 'jpeg'];
export const DOCUMENT_ACCEPT = DOCUMENT_EXTENSIONS.map(extension => `.${extension}`).join(',');

export function validateUploadFiles(files: { name: string; size: number }[]): string | null {
  if (!files.length) return 'Chọn ít nhất một tệp để đính kèm.';
  for (const file of files) {
    const extension = file.name.split('.').pop()?.toLowerCase() ?? '';
    if (!DOCUMENT_EXTENSIONS.includes(extension)) return `Tệp “${file.name}” chưa được hỗ trợ. Chọn PDF, Word, Excel, PowerPoint, TXT, CSV hoặc ảnh PNG/JPG.`;
    if (file.size <= 0) return `Tệp “${file.name}” không có nội dung.`;
    if (file.size > MAX_DOCUMENT_BYTES) return `Tệp “${file.name}” vượt quá giới hạn 20 MB.`;
  }
  return null;
}

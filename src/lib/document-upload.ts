export const MAX_DOCUMENT_MIB = 50;
export const MAX_DOCUMENT_BYTES = MAX_DOCUMENT_MIB * 1024 * 1024;
export const DOCUMENT_MIME_TYPES: Record<string, string[]> = {
  pdf: ['application/pdf'],
  doc: ['application/msword', 'application/vnd.ms-word'],
  docx: ['application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
  xls: ['application/vnd.ms-excel', 'application/x-msexcel'],
  xlsx: ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
  ppt: ['application/vnd.ms-powerpoint', 'application/mspowerpoint', 'application/powerpoint', 'application/x-mspowerpoint'],
  pptx: ['application/vnd.openxmlformats-officedocument.presentationml.presentation'],
  txt: ['text/plain', 'application/text'],
  csv: ['text/csv', 'application/vnd.ms-excel', 'application/csv'],
  md: ['text/markdown', 'text/plain', 'application/x-markdown'],
  rtf: ['application/rtf', 'text/rtf', 'application/x-rtf'],
  png: ['image/png'],
  jpg: ['image/jpeg'],
  jpeg: ['image/jpeg'],
  gif: ['image/gif'],
  webp: ['image/webp'],
  zip: ['application/zip', 'application/x-zip-compressed', 'application/x-zip'],
  '7z': ['application/x-7z-compressed'],
  rar: ['application/vnd.rar', 'application/x-rar-compressed', 'application/x-rar'],
};
export const DOCUMENT_EXTENSIONS = Object.keys(DOCUMENT_MIME_TYPES);
export const DOCUMENT_ACCEPT = DOCUMENT_EXTENSIONS.map(extension => `.${extension}`).join(',');
export const DOCUMENT_FORMAT_HINT = 'PDF, Word, Excel, PowerPoint, TXT, CSV, MD, RTF, ảnh PNG/JPG/GIF/WEBP hoặc tệp ZIP/7Z/RAR.';

export function documentMimeType(name: string, browserType = ''): string | null {
  const extension = name.split('.').pop()?.toLowerCase() ?? '';
  if (!Object.hasOwn(DOCUMENT_MIME_TYPES, extension)) return null;
  const supported = DOCUMENT_MIME_TYPES[extension];
  const supplied = browserType.split(';', 1)[0].trim().toLowerCase();
  if (supplied && supplied !== 'application/octet-stream' && !supported.includes(supplied)) return null;
  return supported[0];
}

export function validateUploadFiles(files: { name: string; size: number; type?: string }[]): string | null {
  if (!files.length) return 'Chọn ít nhất một tệp để đính kèm.';
  for (const file of files) {
    const extension = file.name.split('.').pop()?.toLowerCase() ?? '';
    if (!Object.hasOwn(DOCUMENT_MIME_TYPES, extension)) return `Tệp “${file.name}” chưa được hỗ trợ. Chọn ${DOCUMENT_FORMAT_HINT}`;
    if (!documentMimeType(file.name, file.type)) return `Định dạng tệp “${file.name}” không khớp với loại tệp đã chọn.`;
    if (file.size <= 0) return `Tệp “${file.name}” không có nội dung.`;
    if (file.size > MAX_DOCUMENT_BYTES) return `Tệp “${file.name}” vượt quá giới hạn ${MAX_DOCUMENT_MIB} MB.`;
  }
  return null;
}

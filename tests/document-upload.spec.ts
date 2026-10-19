import { test, expect } from '@playwright/test';
import { canPreviewFile, currentFile } from '../src/lib/document-presentation';
import type { CatalogDocument, DocumentVersion } from '../src/lib/catalog';
import { DOCUMENT_ACCEPT, MAX_DOCUMENT_BYTES, documentMimeType, validateUploadFiles } from '../src/lib/document-upload';

test('supported document families and uppercase extensions can be selected', () => {
  const names = ['biên bản.PDF', 'report.doc', 'report.docx', 'data.xls', 'data.xlsx', 'slides.ppt', 'slides.pptx', 'notes.txt', 'data.csv', 'notes.md', 'letter.rtf', 'image.png', 'image.jpg', 'image.jpeg', 'image.gif', 'image.webp', 'archive.ZIP', 'backup.7z', 'backup.rar'];
  expect(validateUploadFiles(names.map(name => ({ name, size: 1 })))).toBeNull();
  for (const extension of ['.pdf', '.docx', '.xlsx', '.ppt', '.pptx', '.txt', '.csv', '.md', '.rtf', '.png', '.jpg', '.jpeg', '.gif', '.webp', '.zip', '.7z', '.rar']) expect(DOCUMENT_ACCEPT.split(',')).toContain(extension);
});

test('unsupported final extensions are rejected even when an earlier suffix looks valid', () => {
  for (const name of ['report.pdf.exe', 'archive.tar', 'README', 'notes.', 'file.constructor', 'file.__proto__']) {
    const error = validateUploadFiles([{ name, size: 1 }]);
    expect(error).toContain(name);
    expect(error).toContain('chưa được hỗ trợ');
  }
});

test('the API and form agree on canonical MIME types and common browser variants', () => {
  expect(documentMimeType('archive.ZIP', 'application/x-zip-compressed')).toBe('application/zip');
  expect(documentMimeType('archive.zip', 'application/octet-stream')).toBe('application/zip');
  expect(documentMimeType('slides.ppt', 'application/mspowerpoint')).toBe('application/vnd.ms-powerpoint');
  expect(documentMimeType('image.png', 'image/png')).toBe('image/png');
  expect(documentMimeType('notes.txt', 'text/plain')).toBe('text/plain');
  expect(documentMimeType('archive.zip', 'text/html')).toBeNull();
  expect(documentMimeType('malware.exe', 'application/zip')).toBeNull();
  expect(validateUploadFiles([{ name: 'archive.zip', size: 12, type: 'application/x-zip-compressed' }])).toBeNull();
  expect(validateUploadFiles([{ name: 'archive.zip', size: 12, type: 'text/html' }])).toContain('không khớp');
});

test('empty selection and zero-byte files have explicit validation errors', () => {
  expect(validateUploadFiles([])).toContain('Chọn ít nhất một tệp');
  expect(validateUploadFiles([{ name: 'empty.pdf', size: 0 }])).toContain('không có nội dung');
});

test('fifty MiB is allowed per file and the next byte is rejected', () => {
  expect(MAX_DOCUMENT_BYTES).toBe(50 * 1024 * 1024);
  expect(validateUploadFiles([{ name: 'limit.pdf', size: MAX_DOCUMENT_BYTES }])).toBeNull();
  expect(validateUploadFiles([{ name: 'large.pdf', size: MAX_DOCUMENT_BYTES + 1 }])).toContain('vượt quá giới hạn 50 MB');
  expect(validateUploadFiles([{ name: 'one.pdf', size: MAX_DOCUMENT_BYTES }, { name: 'two.pdf', size: MAX_DOCUMENT_BYTES }])).toBeNull();
});

test('a later invalid file rejects the complete selection before any upload starts', () => {
  const files = [{ name: 'valid.pdf', size: 32 }, { name: 'invalid.exe', size: 32 }];
  const before = structuredClone(files);
  expect(validateUploadFiles(files)).toContain('invalid.exe');
  expect(files).toEqual(before);
  expect(validateUploadFiles([{ name: 'valid.pdf', size: 32 }, { name: 'empty.csv', size: 0 }])).toContain('empty.csv');
});

test('document view chooses the current file and previews only browser-readable types', () => {
  const version = (number: number, mime_type: string): DocumentVersion => ({ id: String(number), document_id: 'doc', version: number, filename: `file-${number}`, mime_type, size_bytes: 12, created_at: '' });
  const document = { id: 'doc', title: 'File', created_by: 'owner', created_at: '', versions: [version(2, 'application/pdf'), version(1, 'text/plain')] } satisfies CatalogDocument;
  expect(currentFile(document)?.version).toBe(2);
  expect(canPreviewFile(currentFile(document))).toBe(true);
  expect(canPreviewFile(version(3, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'))).toBe(false);
  expect(canPreviewFile(version(4, 'application/zip'))).toBe(false);
  expect(canPreviewFile(null)).toBe(false);
});

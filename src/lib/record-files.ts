import type { CatalogRecord, Membership, RecordInput } from './catalog';
import type { Dossier, RelatedRecord } from './dossier';

export function isPrimaryDossier(kind: string) {
  return ['unit', 'partner', 'expert', 'use_case', 'work_item', 'collaboration'].includes(kind);
}

// Every member reads every record; admins and editors may change them.
export function canWriteRecord(membership: Membership): boolean {
  return membership.role === 'admin' || membership.role === 'editor';
}

// Existing document metadata records are retained as readable containers, including their URLs.
export function dossierFolders(dossier: Dossier): RelatedRecord[] {
  const folders = new Map<string, RelatedRecord>();
  for (const entry of dossier.related) {
    const contentFolder = dossier.data.kind === 'partner' && entry.record.kind === 'collaboration' && !entry.via;
    if (entry.record.kind !== 'reference' && !contentFolder) continue;
    if (!folders.has(entry.record.id) || (folders.get(entry.record.id)?.via && !entry.via)) folders.set(entry.record.id, entry);
  }
  return [...folders.values()];
}

export function dossierAttachmentOwners(dossier: Dossier, folders = dossierFolders(dossier)): CatalogRecord[] {
  const folderIds = new Set(folders.map(entry => entry.record.id));
  const owners = new Map<string, CatalogRecord>();
  for (const item of dossier.attachments) {
    if (item.record.kind === 'reference' || item.record.id === dossier.data.id || folderIds.has(item.record.id)) continue;
    owners.set(item.record.id, item.record);
  }
  return [...owners.values()];
}

function folderTitle(title: string) {
  const value = title.trim();
  if (!value || value.length > 250) throw new Error('Tên thư mục cần từ 1 đến 250 ký tự.');
  return value;
}

export function folderCreateInput(parent: CatalogRecord, title: string): RecordInput {
  if (parent.kind === 'reference') throw new Error('Hiện hỗ trợ một cấp thư mục trong mỗi hồ sơ.');
  return { kind: 'reference', title: folderTitle(title), status: 'Chưa đính kèm', data: { reference_type: 'Thư mục' } };
}

export function folderRenameInput(folder: CatalogRecord, title: string): RecordInput {
  if (folder.kind !== 'reference') throw new Error('Hồ sơ này không phải thư mục tài liệu.');
  return { id: folder.id, version: folder.version, kind: folder.kind, title: folderTitle(title),
    status: folder.status, code: folder.code, summary: folder.summary, data: { ...folder.data } };
}

import type { CatalogDocument, DocumentVersion } from './catalog';

export function currentFile(document: CatalogDocument): DocumentVersion | null {
  return document.versions.reduce<DocumentVersion | null>((latest, version) => !latest || version.version > latest.version ? version : latest, null);
}

export function canPreviewFile(version: DocumentVersion | null): boolean {
  return Boolean(version && (version.mime_type === 'application/pdf' || version.mime_type.startsWith('image/') || version.mime_type === 'text/plain' || version.mime_type === 'text/csv'));
}

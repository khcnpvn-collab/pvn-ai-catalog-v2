"use client";
import { useState, type FormEvent } from 'react';
import { moduleMap, type CatalogRecord, type Membership } from '@/lib/catalog';
import type { Dossier } from '@/lib/dossier';
import { canWriteRecord, dossierAttachmentOwners, dossierFolders, folderCreateInput, folderRenameInput } from '@/lib/record-files';
import { DocumentItems, ReuseDocument, UploadForm } from './document-library';
import { api, ErrorBox, Icon, Loading, message, useResource } from './ui';
import AddMenu from './add-menu';

function FolderNameForm({ record, rename, onDone, onCancel }: {
  record: CatalogRecord; rename: boolean; onDone: () => void; onCancel: () => void;
}) {
  const [title, setTitle] = useState(rename ? record.title : '');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  async function save(event: FormEvent) {
    event.preventDefault(); setBusy(true); setError(null);
    try {
      const input = rename ? folderRenameInput(record, title) : folderCreateInput(record, title);
      await api(rename ? `/api/records/${record.id}` : `/api/records/${record.id}/related`, {
        method: rename ? 'PATCH' : 'POST',
        body: JSON.stringify(rename ? input : { record: input, relation: record.kind === 'expert' ? 'expert' : 'related', direction: 'to-parent' }),
      });
      onDone();
    } catch (e) { setError(message(e)); } finally { setBusy(false); }
  }
  return <form className="inline-form" onSubmit={save} aria-label={rename ? 'Đổi tên thư mục' : 'Tạo thư mục'}>
    <label className="field">{rename ? 'Tên mới' : 'Tên thư mục'}<input required autoFocus maxLength={250} value={title} disabled={busy} onChange={event => setTitle(event.target.value)}/></label>
    <p className="muted">{rename ? 'Đổi tên áp dụng ở mọi hồ sơ đang dùng thư mục này.' : `Thư mục được tạo trong “${record.title}”, cùng phạm vi chia sẻ với hồ sơ.`}</p>
    <ErrorBox error={error}/><div className="actions"><button className="button primary" disabled={busy}>{busy ? 'Đang lưu…' : rename ? 'Lưu tên' : 'Tạo thư mục'}</button><button className="button" type="button" disabled={busy} onClick={onCancel}>Hủy</button></div>
  </form>;
}

export default function RecordFiles({ dossier, membership, onOpen, onRefresh }: {
  dossier: Dossier; membership: Membership; onOpen: (id: string) => void; onRefresh: () => void;
}) {
  const [selected, setSelected] = useState<string | null>(null);
  const [folderChanged, setFolderChanged] = useState(false);
  const [deleteFolder, setDeleteFolder] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [action, setAction] = useState<'upload' | 'reuse' | 'create' | 'rename' | null>(null);
  const folderResource = useResource<Dossier>(selected ? `/api/records/${selected}/dossier` : null);
  const current = selected ? folderResource.data : dossier;
  const target = current?.data;
  const writable = canWriteRecord(membership) && Boolean(target);
  const folders = current ? dossierFolders(current) : [];
  const otherOwners = current ? dossierAttachmentOwners(current, folders) : [];
  const fileCount = (id: string) => (current?.attachments || []).filter(item => item.record.id === id).length;
  // An activity folder repeats the activity list above unless it actually holds files.
  const shownFolders = folders.filter(({record}) => record.kind !== 'collaboration' || fileCount(record.id) > 0);
  function openFolder(id: string) { setAction(null); setSelected(id); }
  async function removeFolder() {
    if (!target || target.kind !== 'reference' || target.data.reference_type !== 'Thư mục' || deleting) return;
    setDeleting(true); setDeleteError(null);
    try {
      await api(`/api/records/${target.id}`, { method: 'DELETE', body: JSON.stringify({ version: target.version }) });
      setDeleteFolder(false); setSelected(null); setAction(null); onRefresh();
    } catch (cause) { setDeleteError(message(cause)); } finally { setDeleting(false); }
  }
  function refresh() {
    setAction(null);
    if (selected) { setFolderChanged(true); folderResource.refresh(); } else onRefresh();
  }
  function backToFiles() {
    setAction(null); setSelected(null);
    if (folderChanged) { setFolderChanged(false); onRefresh(); }
  }
  function cancelUpload() {
    setAction(null);
    if (folderChanged) { if (selected) folderResource.refresh(); else onRefresh(); }
  }
  const url = String(target?.data.external_url || '');
  const metadata = target?.kind === 'reference' ? moduleMap.reference.fields.filter(field => {
    const value = target.data[field.key];
    return field.key !== 'external_url' && value != null && String(value).trim() && !(field.key === 'reference_type' && value === 'Thư mục');
  }) : [];
  return <section className="record-files" aria-label="File & tài liệu">
    <header className="section-heading"><div><h2>File & tài liệu</h2>{!selected && <p>{target?.kind === 'reference' ? 'Các file được lưu trong thư mục này.' : target?.kind === 'collaboration' ? 'File của hoạt động và file từ các mốc liên quan được tập hợp tại đây.' : 'Tải file trực tiếp hoặc sắp xếp theo thư mục.'}</p>}</div>
      {writable && !action && <AddMenu label="Thêm file" options={[
        { label: 'Tải file lên', onSelect: () => setAction('upload') },
        { label: 'Dùng file có sẵn', onSelect: () => setAction('reuse') },
        ...(!selected && target?.kind !== 'reference' ? [{ label: 'Tạo thư mục', onSelect: () => setAction('create') }] : []),
      ]}/>}
    </header>
    {selected && <div className="file-location"><button className="text-button" disabled={Boolean(action)} onClick={backToFiles}><Icon name="back"/>Tất cả file & thư mục</button>{target && <strong>{target.title}</strong>}{writable && target?.kind === 'reference' && target.data.reference_type === 'Thư mục' && !action && <div className="actions"><button className="text-button" onClick={() => setAction('rename')}>Đổi tên</button><button className="text-button danger-text" onClick={() => setDeleteFolder(true)}>Xóa thư mục</button></div>}</div>}
    {selected && deleteFolder && <div className="document-confirm"><p>Xóa thư mục “{target?.title}” ở tất cả hồ sơ đang dùng thư mục này? File trong thư mục vẫn được giữ ở kho chung.</p><ErrorBox error={deleteError}/><div className="actions"><button className="button small danger" disabled={deleting} onClick={removeFolder}>{deleting ? 'Đang xóa…' : 'Xác nhận xóa'}</button><button className="button small" disabled={deleting} onClick={() => { setDeleteFolder(false); setDeleteError(null); }}>Hủy</button></div></div>}
    {selected && folderResource.loading ? <Loading label="Đang mở thư mục…"/> : selected && folderResource.error ? <ErrorBox error={folderResource.error} retry={folderResource.refresh}/> : target && current && <>
      {selected && /^https?:\/\//i.test(url) && <p><a className="text-button" href={url} target="_blank" rel="noreferrer"><Icon name="link"/>Mở liên kết đã lưu</a></p>}
      {selected && (metadata.length > 0 || target.summary) && <details className="file-metadata"><summary>Thông tin tài liệu đã ghi nhận</summary>{target.summary && <p className="preserve-lines">{target.summary}</p>}<dl className="record-facts">{metadata.map(field => <div key={field.key}><dt>{field.label}</dt><dd className="preserve-lines">{target.data[field.key]}</dd></div>)}</dl></details>}
      {writable && action === 'create' && !selected && target.kind !== 'reference' && <FolderNameForm record={target} rename={false} onDone={refresh} onCancel={() => setAction(null)}/>}
      {writable && action === 'rename' && target.kind === 'reference' && <FolderNameForm record={target} rename onDone={refresh} onCancel={() => setAction(null)}/>}
      {writable && action === 'upload' && <UploadForm key={target.id} recordId={target.id} onUploaded={() => setFolderChanged(true)} onDone={refresh} onCancel={cancelUpload}/>}
      {writable && action === 'reuse' && <ReuseDocument recordId={target.id} onDone={refresh} onCancel={() => setAction(null)}/>}
      {target.kind !== 'reference' && shownFolders.length > 0 && <div className="file-folders" aria-label="Thư mục và tài liệu đã lưu">{shownFolders.map(({record, via}) => {
        const count = fileCount(record.id);
        const externalUrl = String(record.data.external_url || '');
        return <article className="file-folder-row" key={record.id}><Icon name="folder"/><div><button className="related-record-title" onClick={() => openFolder(record.id)}>{record.title}<Icon name="arrow" size={16}/></button><p>{record.kind === 'collaboration' ? `Hoạt động · ${count} file` : `${count} file`}{via ? ` · Trong ${via.title}` : ''}</p></div>{/^https?:\/\//i.test(externalUrl) && <a className="text-button" href={externalUrl} target="_blank" rel="noreferrer">Mở liên kết<Icon name="arrow" size={16}/></a>}</article>;
      })}</div>}
      {current.documents.length > 0 && <DocumentItems documents={current.documents} membership={membership} onOpen={onOpen} onRefresh={refresh} recordId={target.id} showLinkedRecords={false} allowChanges={writable}/>}
      {target.kind !== 'reference' && otherOwners.length > 0 && <div className="file-folders" aria-label="File từ hồ sơ liên quan">{otherOwners.map(owner => <article className="file-folder-row" key={owner.id}><Icon name="folder"/><div><button className="related-record-title" onClick={() => openFolder(owner.id)}>{owner.title}<Icon name="arrow" size={16}/></button><p>{moduleMap[owner.kind].label} · {(current?.attachments || []).filter(item => item.record.id === owner.id).length} file</p></div></article>)}</div>}
      {!current.documents.length && (selected || target.kind === 'reference' || (!shownFolders.length && !otherOwners.length)) && <p className="muted">Chưa có file trong {selected || target.kind === 'reference' ? 'thư mục này' : 'hồ sơ này'}.</p>}
    </>}
  </section>;
}

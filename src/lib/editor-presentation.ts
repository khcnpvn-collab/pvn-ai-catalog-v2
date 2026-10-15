import { isInternalCodeField } from './record-presentation';

export type EditorPresentation = {
  dataKeys: string[] | null;
  showCode: boolean;
  showStatus: boolean;
  showSummary: boolean;
  compact: boolean;
};

const full: EditorPresentation = {
  dataKeys: null,
  showCode: false,
  showStatus: true,
  showSummary: true,
  compact: false,
};

const presets: Record<string, Omit<EditorPresentation, 'showStatus'>> = {
  partner: {
    dataKeys: ['partner_type', 'strategic_level', 'country', 'website', 'specialties'],
    showCode: false,
    showSummary: true,
    compact: true,
  },
  contact: {
    dataKeys: ['role', 'position', 'department', 'email', 'phone', 'is_primary', 'work_status'],
    showCode: false,
    showSummary: false,
    compact: true,
  },
  collaboration: {
    dataKeys: ['item_group', 'item_category', 'declared_title', 'scope', 'lead', 'start_date', 'end_date', 'agreement', 'results'],
    showCode: false,
    showSummary: false,
    compact: true,
  },
  engagement: {
    dataKeys: ['start_date', 'end_date', 'period_label', 'location', 'participants', 'responsible', 'conclusions', 'next_notes'],
    showCode: false,
    showSummary: true,
    compact: true,
  },
};

export function editorPresentation(kind: string, parentKind?: string): EditorPresentation {
  const usePreset = ['partner', 'collaboration', 'engagement'].includes(kind) || (parentKind === 'partner' && kind === 'contact');
  if (!usePreset) return full;
  return { ...presets[kind], showStatus: ['collaboration', 'engagement', 'partner'].includes(kind) };
}

export function visibleEditorDataKeys(kind: string, parentKind: string | undefined, available: string[]): string[] {
  const keys = editorPresentation(kind, parentKind).dataKeys;
  return (keys ? keys.filter(key => available.includes(key)) : available).filter(key => !isInternalCodeField(key));
}

// The record summary is named the same in the form and on the record page.
export function summaryFieldLabel(kind: string) {
  return kind === 'partner' ? 'Giới thiệu đối tác' : kind === 'unit' ? 'Giới thiệu đơn vị' : 'Tóm tắt';
}

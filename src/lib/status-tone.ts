// One colour per status, shared by badges and charts so a stage reads the same everywhere.
// Checked for colour-blind separation between neighbouring lifecycle stages; the two
// greys (not started, paused) are deliberately neutral and always shown with their label.
export type Tone = 'slate' | 'sky' | 'amber' | 'blue' | 'pink' | 'green' | 'stone' | 'red' | 'navy';

const toneByStatus: Record<string, Tone> = {
  'Đề xuất': 'slate', 'Đang trao đổi': 'sky', 'POC': 'amber', 'Triển khai chính thức': 'blue', 'Pilot': 'pink', 'Vận hành': 'green', 'Tạm dừng': 'stone', 'Dừng': 'red',
  'Đang hợp tác': 'green', 'Tiềm năng': 'sky',
  'Đang thực hiện': 'blue', 'Hoàn thành': 'navy', 'Ưu tiên': 'green',
  // Role tags read as one family.
  'Đầu mối': 'navy', 'Đầu mối liên danh': 'navy', 'Đối tác này là đầu mối': 'navy', 'Đầu mối chính': 'navy', 'Phối hợp': 'slate',
};

export const toneColor: Record<Tone, string> = {
  slate: '#a8b4c4', sky: '#4b9bd6', amber: '#e3a22b', blue: '#2c4fa8', pink: '#d0679a', green: '#2a8a55', stone: '#9e9588', red: '#b8433d', navy: '#102d55',
};

export function statusTone(label: string): Tone | null { return toneByStatus[label] || null; }
export function statusColor(label: string) { const tone = statusTone(label); return tone ? toneColor[tone] : '#b6bfcc'; }

import { randomUUID } from 'node:crypto';
import type { RecordInput } from './catalog';

// Preserve imported identifiers; assign new internal codes only on creation.
export function assignNewRecordCode(record: RecordInput): RecordInput {
  return { ...record, code: record.code?.trim() || `AI-${randomUUID()}` };
}

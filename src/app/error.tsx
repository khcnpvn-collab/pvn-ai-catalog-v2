"use client";
export default function ErrorPage({ reset }: { error: Error & { digest?: string }; reset: () => void }) { return <main className="center-state"><h1>Không thể mở trang</h1><p>Vui lòng tải lại để tiếp tục làm việc.</p><button className="button primary" onClick={reset}>Thử lại</button></main>; }

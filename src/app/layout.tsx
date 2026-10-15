import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "Danh mục AI | Petrovietnam", description: "Cơ sở dữ liệu hồ sơ, hợp tác, bài toán, dữ liệu và đào tạo AI của Petrovietnam.", icons: { icon: "/brand/logo-pvn-flame-color.png" }, robots: { index: false, follow: false } };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="vi"><head><link rel="preload" href="/fonts/be-vietnam-pro-400.ttf" as="font" type="font/ttf" crossOrigin="anonymous"/></head><body>{children}</body></html>; }

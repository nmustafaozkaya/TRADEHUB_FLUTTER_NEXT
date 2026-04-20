import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { Header } from "@/components/Header";
import { PageTransition } from "@/components/PageTransition";
import { HeaderGate } from "@/components/HeaderGate";
import { AdminContainerGate } from "@/components/AdminContainerGate";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "TradeHub",
  description: "TradeHub MSSQL e-commerce (Next.js + TS)",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased min-h-full bg-slate-950 text-slate-100`}
      >
        <PageTransition />
        <HeaderGate>
          <Header />
        </HeaderGate>
        <AdminContainerGate>{children}</AdminContainerGate>
      </body>
    </html>
  );
}

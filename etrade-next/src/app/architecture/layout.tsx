import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Technical Architecture | TradeHub",
  description: "Flutter, Next.js, and MSSQL — scalable production architecture overview.",
};

export default function ArchitectureLayout({ children }: { children: React.ReactNode }) {
  return children;
}

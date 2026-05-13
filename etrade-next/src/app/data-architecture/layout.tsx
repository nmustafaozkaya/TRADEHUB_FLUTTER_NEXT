import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Data Architecture & Integrity | TradeHub",
  description: "MSSQL schema, constraints, and Next.js data access layer overview.",
};

export default function DataArchitectureLayout({ children }: { children: React.ReactNode }) {
  return children;
}

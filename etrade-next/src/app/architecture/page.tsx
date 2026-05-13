"use client";

import Link from "next/link";

const LOGO = {
  flutter: "https://cdn.simpleicons.org/flutter/02569B",
  nextjs: "https://cdn.simpleicons.org/nextdotjs/000000",
  mssql: "https://cdn.simpleicons.org/microsoftsqlserver/CC2927",
} as const;

export default function ArchitecturePage() {
  return (
    <main className="min-h-[calc(100vh-4rem)] bg-gradient-to-b from-slate-950 via-[#0b1020] to-slate-950 px-4 py-10 print:min-h-screen print:bg-white print:p-8 print:text-slate-900">
      <div className="mx-auto max-w-4xl">
        <p className="mb-2 text-center text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 print:text-slate-600">
          Page 2 · Technical architecture
        </p>
        <h1 className="text-center text-2xl font-extrabold tracking-tight text-slate-100 print:text-slate-900 sm:text-3xl">
          The Core
        </h1>
        <p className="mx-auto mt-3 max-w-xl text-center text-lg font-medium text-indigo-200 print:text-indigo-800">
          Scalable &amp; Production-Ready Architecture.
        </p>

        <div className="mt-10 flex flex-col items-stretch justify-center gap-2 sm:flex-row sm:items-center sm:gap-4">
          <StackCard
            title="Client"
            subtitle="Flutter"
            logo={LOGO.flutter}
            logoClass="bg-white"
          />
          <FlowConnector />
          <StackCard
            title="API"
            subtitle="Next.js"
            logo={LOGO.nextjs}
            logoClass="bg-white"
          />
          <FlowConnector />
          <StackCard
            title="Database"
            subtitle="Microsoft SQL Server"
            logo={LOGO.mssql}
            logoClass="bg-white"
          />
        </div>

        <p className="mt-10 text-center text-base text-slate-300 print:text-slate-700 sm:text-lg">
          <span className="font-semibold text-white print:text-slate-900">Client (Flutter)</span>
          <span className="mx-2 text-indigo-400 print:text-indigo-700">↔</span>
          <span className="font-semibold text-white print:text-slate-900">API (Next.js)</span>
          <span className="mx-2 text-indigo-400 print:text-indigo-700">↔</span>
          <span className="font-semibold text-white print:text-slate-900">Database (MSSQL)</span>
        </p>

        <div className="no-print mt-10 flex flex-wrap items-center justify-center gap-4">
          <button
            type="button"
            onClick={() => window.print()}
            className="rounded-xl bg-indigo-600 px-5 py-2.5 text-sm font-semibold text-white shadow-lg shadow-indigo-900/40 transition hover:bg-indigo-500"
          >
            Print / Save as PDF
          </button>
          <Link
            href="/"
            className="rounded-xl border border-white/15 px-5 py-2.5 text-sm font-semibold text-slate-200 transition hover:border-white/30 hover:text-white"
          >
            ← Back to shop
          </Link>
        </div>

        <p className="no-print mt-6 text-center text-xs text-slate-500">
          In the print dialog, choose <strong>Save as PDF</strong> (or Microsoft Print to PDF).
        </p>
      </div>

      <style jsx global>{`
        @media print {
          header,
          nav,
          .no-print {
            display: none !important;
          }
          body {
            background: #fff !important;
          }
        }
      `}</style>
    </main>
  );
}

function StackCard({
  title,
  subtitle,
  logo,
  logoClass,
}: {
  title: string;
  subtitle: string;
  logo: string;
  logoClass: string;
}) {
  return (
    <div className="flex flex-1 flex-col items-center rounded-2xl border border-white/10 bg-slate-900/50 p-6 shadow-xl print:border-slate-200 print:bg-slate-50 print:shadow-none">
      <div
        className={`flex h-20 w-20 items-center justify-center rounded-2xl ${logoClass} print:ring-0`}
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={logo} alt="" width={48} height={48} className="h-12 w-12 object-contain" />
      </div>
      <p className="mt-4 text-xs font-semibold uppercase tracking-wider text-slate-500 print:text-slate-600">
        {title}
      </p>
      <p className="mt-1 text-center text-sm font-bold text-slate-100 print:text-slate-900">{subtitle}</p>
    </div>
  );
}

function FlowConnector() {
  return (
    <div
      className="flex shrink-0 justify-center py-1 text-2xl font-bold text-indigo-400 sm:py-0 print:text-indigo-700"
      aria-hidden
    >
      <span className="sm:hidden">↕</span>
      <span className="hidden sm:inline">↔</span>
    </div>
  );
}

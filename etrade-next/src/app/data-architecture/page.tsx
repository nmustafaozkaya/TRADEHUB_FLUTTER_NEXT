"use client";

import Link from "next/link";

export default function DataArchitecturePage() {
  return (
    <main className="min-h-[calc(100vh-4rem)] bg-gradient-to-b from-slate-950 via-[#0b1020] to-slate-950 px-4 py-10 print:min-h-screen print:bg-white print:p-6 print:text-slate-900">
      <div className="mx-auto max-w-4xl space-y-10">
        <header className="text-center">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 print:text-slate-600">
            TradeHub · Documentation
          </p>
          <h1 className="mt-2 text-2xl font-extrabold tracking-tight text-slate-100 print:text-slate-900 sm:text-3xl">
            DATA ARCHITECTURE &amp; INTEGRITY
          </h1>
          <p className="mx-auto mt-3 max-w-2xl text-sm text-slate-400 print:text-slate-600 sm:text-base">
            Single source of truth in <strong className="text-slate-200 print:text-slate-800">MSSQL</strong>;
            integrity enforced in the database (constraints, indexes) and in the{" "}
            <strong className="text-slate-200 print:text-slate-800">Next.js</strong> server layer
            (parameterized SQL, business rules).
          </p>
        </header>

        <section className="rounded-2xl border border-white/10 bg-slate-900/40 p-5 print:border-slate-200 print:bg-slate-50 sm:p-6">
          <h2 className="text-lg font-bold text-indigo-200 print:text-indigo-900">SQL · Schema &amp; integrity</h2>
          <p className="mt-2 text-sm text-slate-400 print:text-slate-600">
            Example: <code className="rounded bg-black/30 px-1.5 py-0.5 text-slate-200 print:bg-slate-200 print:text-slate-900">dbo.REVIEWS</code>{" "}
            (from <code className="rounded bg-black/30 px-1.5 print:bg-slate-200">migrate-create-reviews-and-seed.js</code>).
          </p>
          <SqlBlock
            title="Table + domain rules"
            sql={`CREATE TABLE dbo.REVIEWS (
  ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  USERID INT NOT NULL,
  ORDERID INT NOT NULL,
  ITEMID INT NOT NULL,
  RATING TINYINT NOT NULL,
  COMMENT NVARCHAR(800) NULL,
  ISACTIVE BIT NOT NULL DEFAULT (1),
  CREATEDAT DATETIME NOT NULL DEFAULT (GETDATE()),
  UPDATEDAT DATETIME NULL,
  CONSTRAINT CK_REVIEWS_RATING CHECK (RATING BETWEEN 1 AND 5)
);`}
          />
          <SqlBlock
            title="Uniqueness (one active review per user + order + item)"
            sql={`CREATE UNIQUE INDEX UX_REVIEWS_USER_ORDER_ITEM_ACTIVE
ON dbo.REVIEWS (USERID, ORDERID, ITEMID)
WHERE ISACTIVE = 1;`}
          />
          <SqlBlock
            title="Query performance indexes"
            sql={`CREATE INDEX IX_REVIEWS_ITEM_ACTIVE
  ON dbo.REVIEWS (ITEMID, ISACTIVE, CREATEDAT DESC);
CREATE INDEX IX_REVIEWS_USER_ACTIVE
  ON dbo.REVIEWS (USERID, ISACTIVE, CREATEDAT DESC);`}
          />
          <p className="mt-4 text-sm text-slate-400 print:text-slate-600">
            <strong className="text-slate-200 print:text-slate-800">Referential integrity:</strong> optional{" "}
            <code className="text-xs">FOREIGN KEY</code> from <code className="text-xs">REVIEWS</code> to{" "}
            <code className="text-xs">USERS</code>, <code className="text-xs">ORDERS</code>, <code className="text-xs">ITEMS</code>{" "}
            (see your DBA script). App logic joins these tables in{" "}
            <code className="text-xs">src/lib/repos/reviews.ts</code> and <code className="text-xs">ordersHistory.ts</code>.
          </p>
        </section>

        <section className="rounded-2xl border border-white/10 bg-slate-900/40 p-5 print:border-slate-200 print:bg-slate-50 sm:p-6">
          <h2 className="text-lg font-bold text-indigo-200 print:text-indigo-900">Code · Data access layer</h2>
          <ul className="mt-3 list-inside list-disc space-y-2 text-sm text-slate-300 print:text-slate-700">
            <li>
              <code className="rounded bg-black/30 px-1 print:bg-slate-200">src/lib/db.ts</code> — connection pool +{" "}
              <code className="rounded bg-black/30 px-1 print:bg-slate-200">query()</code> with{" "}
              <strong>bound parameters</strong> (no string-built SQL for user input).
            </li>
            <li>
              <code className="rounded bg-black/30 px-1 print:bg-slate-200">src/lib/repos/*.ts</code> — one domain per file
              (e.g. <code className="text-xs">reviews.ts</code>, <code className="text-xs">items.ts</code>,{" "}
              <code className="text-xs">ordersHistory.ts</code>); all DB access from{" "}
              <strong>server</strong> routes / Server Components.
            </li>
            <li>
              <strong>API routes</strong> (<code className="text-xs">src/app/api/...</code>) call repos;{" "}
              <strong>Flutter</strong> calls HTTP JSON only — no direct DB from the mobile client.
            </li>
            <li>
              Business rules (e.g. review only after purchase, order + item pairing) live in SQL{" "}
              <code className="text-xs">EXISTS</code> / <code className="text-xs">NOT EXISTS</code> subqueries in repos, aligned
              with <code className="text-xs">UX_REVIEWS_USER_ORDER_ITEM_ACTIVE</code>.
            </li>
          </ul>
        </section>

        <section className="rounded-2xl border border-dashed border-white/15 p-5 print:border-slate-300">
          <h2 className="text-sm font-bold uppercase tracking-wider text-slate-400 print:text-slate-600">
            PDF export
          </h2>
          <p className="mt-2 text-sm text-slate-400 print:hidden">
            Use <strong className="text-slate-200">Print / Save as PDF</strong> below, or{" "}
            <kbd className="rounded border border-white/20 px-1.5 py-0.5 text-xs">Ctrl+P</kbd> → hedef:{" "}
            <strong>Save as PDF</strong> / <strong>Microsoft Print to PDF</strong>.
          </p>
        </section>

        <div className="no-print flex flex-wrap justify-center gap-4">
          <button
            type="button"
            onClick={() => window.print()}
            className="rounded-xl bg-indigo-600 px-5 py-2.5 text-sm font-semibold text-white shadow-lg shadow-indigo-900/40 transition hover:bg-indigo-500"
          >
            Print / Save as PDF
          </button>
          <Link
            href="/architecture"
            className="rounded-xl border border-white/15 px-5 py-2.5 text-sm font-semibold text-slate-200 transition hover:border-white/30 hover:text-white"
          >
            Technical architecture →
          </Link>
          <Link
            href="/items"
            className="rounded-xl border border-white/15 px-5 py-2.5 text-sm font-semibold text-slate-200 transition hover:border-white/30 hover:text-white"
          >
            ← Shop
          </Link>
        </div>
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

function SqlBlock({ title, sql }: { title: string; sql: string }) {
  return (
    <div className="mt-4">
      <p className="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-500 print:text-slate-600">{title}</p>
      <pre className="overflow-x-auto rounded-xl border border-white/10 bg-black/40 p-4 text-left text-[11px] leading-relaxed text-emerald-100/95 print:border-slate-200 print:bg-slate-100 print:text-slate-900 sm:text-xs">
        <code>{sql.trim()}</code>
      </pre>
    </div>
  );
}

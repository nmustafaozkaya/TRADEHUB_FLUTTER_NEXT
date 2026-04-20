import Link from "next/link";

export default function NotFound() {
  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
      <h1 className="text-2xl font-extrabold">404</h1>
      <p className="mt-2 text-slate-300">Page not found.</p>
      <Link
        className="mt-4 inline-block rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm hover:bg-white/10"
        href="/items"
      >
        Back to items
      </Link>
    </div>
  );
}


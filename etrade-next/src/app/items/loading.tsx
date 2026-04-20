export default function LoadingItems() {
  return (
    <div className="space-y-4">
      <div className="h-[142px] rounded-2xl border border-white/10 bg-white/5" />
      <div className="flex items-center justify-between">
        <div className="h-4 w-40 rounded bg-white/10" />
        <div className="h-4 w-28 rounded bg-white/10" />
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 9 }).map((_, i) => (
          <div key={i} className="rounded-2xl border border-white/10 bg-white/5 p-4">
            <div className="h-40 rounded-xl bg-white/10" />
            <div className="mt-3 h-4 w-3/4 rounded bg-white/10" />
            <div className="mt-2 h-3 w-2/3 rounded bg-white/10" />
            <div className="mt-4 flex items-center justify-between">
              <div className="h-5 w-20 rounded bg-white/10" />
              <div className="h-9 w-28 rounded-xl bg-white/10" />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}


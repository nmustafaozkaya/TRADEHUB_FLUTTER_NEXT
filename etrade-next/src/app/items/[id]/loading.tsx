export default function LoadingItem() {
  return (
    <div className="space-y-4">
      <div className="h-4 w-40 rounded bg-white/10" />
      <div className="rounded-2xl border border-white/10 bg-white/5 p-5">
        <div className="grid gap-4 lg:grid-cols-2">
          <div className="h-[280px] rounded-2xl bg-white/10" />
          <div>
            <div className="h-7 w-3/4 rounded bg-white/10" />
            <div className="mt-3 space-y-2">
              <div className="h-4 w-1/2 rounded bg-white/10" />
              <div className="h-4 w-1/3 rounded bg-white/10" />
              <div className="h-4 w-2/3 rounded bg-white/10" />
            </div>
            <div className="mt-6 flex items-center justify-between">
              <div className="h-7 w-32 rounded bg-white/10" />
              <div className="h-10 w-32 rounded-xl bg-white/10" />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}


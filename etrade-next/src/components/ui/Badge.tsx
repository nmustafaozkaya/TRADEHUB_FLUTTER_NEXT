import { cn } from "@/lib/ui";

export function Badge(props: React.HTMLAttributes<HTMLSpanElement>) {
  return (
    <span
      {...props}
      className={cn(
        "inline-flex items-center rounded-full border border-white/10 bg-white/5 px-2 py-0.5 text-[11px] text-slate-200/90",
        props.className
      )}
    />
  );
}


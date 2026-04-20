import Link from "next/link";

import { cn } from "@/lib/ui";

type Variant = "ghost" | "soft" | "primary" | "danger";
type Size = "sm" | "md";

const base =
  "inline-flex items-center justify-center gap-2 rounded-xl border text-sm font-medium transition active:translate-y-px disabled:pointer-events-none disabled:opacity-60";

const variants: Record<Variant, string> = {
  ghost: "border-transparent bg-transparent text-slate-200 hover:bg-white/5",
  soft: "border-white/10 bg-white/5 text-slate-200 hover:bg-white/10",
  primary: "border-white/10 bg-sky-400/20 text-sky-200 hover:bg-sky-400/25",
  danger: "border-rose-400/25 bg-rose-400/10 text-rose-100 hover:bg-rose-400/15",
};

const sizes: Record<Size, string> = {
  sm: "px-3 py-1.5",
  md: "px-3 py-2",
};

export function Button({
  variant = "soft",
  size = "md",
  className,
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant; size?: Size }) {
  return <button {...props} className={cn(base, variants[variant], sizes[size], className)} />;
}

export function ButtonLink({
  variant = "soft",
  size = "md",
  className,
  ...props
}: React.ComponentProps<typeof Link> & { variant?: Variant; size?: Size; className?: string }) {
  return <Link {...props} className={cn(base, variants[variant], sizes[size], className)} />;
}


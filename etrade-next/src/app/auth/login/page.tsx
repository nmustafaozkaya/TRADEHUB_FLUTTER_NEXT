import Link from "next/link";
import Image from "next/image";
import { LoginForm } from "../ui/LoginForm";

export const runtime = "nodejs";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string }>;
}) {
  const sp = await searchParams;
  const nextPath = typeof sp?.next === "string" ? sp.next : undefined;
  return (
    <div className="mx-auto max-w-md space-y-4">
      <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
        <div className="relative mb-4 overflow-hidden rounded-2xl border border-white/10 bg-black/20">
          <Image
            src="/TradeHub-story.png"
            alt="TradeHub"
            width={800}
            height={500}
            priority
            className="h-40 w-full object-cover"
          />
          <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-slate-950/50 via-slate-950/10 to-transparent" />
        </div>
        <h1 className="text-2xl font-extrabold">Sign in</h1>
        <div className="mt-4">
          <LoginForm nextPath={nextPath} />
        </div>
      </div>
      <p className="text-sm text-slate-400">
        Don’t have an account?{" "}
        <Link className="text-sky-200 hover:underline" href="/auth/register">
          Create one
        </Link>
        .
      </p>
    </div>
  );
}


import Link from "next/link";
import Image from "next/image";
import { RegisterForm } from "../ui/RegisterForm";

export const runtime = "nodejs";

export default function RegisterPage() {
  return (
    <div className="mx-auto max-w-lg space-y-4">
      <div className="rounded-2xl border border-white/10 bg-white/5 p-8">
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
        <h1 className="text-2xl font-extrabold">Create account</h1>
        <p className="mt-2 text-sm text-slate-400">Fill in your information to create your account in this MVP.</p>
        <div className="mt-4">
          <RegisterForm />
        </div>
      </div>
      <p className="text-sm text-slate-400">
        Already have an account?{" "}
        <Link className="text-sky-200 hover:underline" href="/auth/login">
          Sign in
        </Link>
        .
      </p>
    </div>
  );
}


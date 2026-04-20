"use client";

import { useActionState } from "react";
import { loginAction } from "../actions";
import { Button } from "@/components/ui/Button";

export function LoginForm({ nextPath }: { nextPath?: string }) {
  const [state, formAction, pending] = useActionState(loginAction, { error: null });

  return (
    <form action={formAction} className="space-y-3">
      {nextPath ? <input type="hidden" name="next" value={nextPath} /> : null}
      {state.error ? (
        <div className="rounded-xl border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-100">
          {state.error}
        </div>
      ) : null}

      <label className="block text-sm">
        <div className="mb-1 text-slate-300">Username or Email</div>
        <input
          name="username"
          required
          placeholder="e.g. nickname or mail@example.com"
          className="w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 outline-none focus:border-white/20"
        />
      </label>

      <label className="block text-sm">
        <div className="mb-1 text-slate-300">Password</div>
        <input
          name="password"
          type="password"
          required
          className="w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 outline-none focus:border-white/20"
        />
      </label>

      <Button disabled={pending} variant="primary" className="w-full">
        {pending ? "Signing in..." : "Sign in"}
      </Button>
    </form>
  );
}


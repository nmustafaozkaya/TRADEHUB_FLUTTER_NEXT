"use client";

import { useActionState } from "react";

import { changePasswordAction, type ChangePasswordFormState } from "./actions";

const initialState: ChangePasswordFormState = { error: null, success: null };

export function ChangePasswordForm() {
  const [state, formAction, pending] = useActionState(changePasswordAction, initialState);

  return (
    <form action={formAction} className="space-y-4">
      {state.error ? (
        <div className="rounded-xl border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-100">
          {state.error}
        </div>
      ) : null}
      {state.success ? (
        <div className="rounded-xl border border-emerald-400/30 bg-emerald-400/10 px-3 py-2 text-sm text-emerald-100">
          {state.success}
        </div>
      ) : null}

      <div>
        <label className="text-xs text-slate-400">Current password</label>
        <input
          name="oldPassword"
          type="password"
          autoComplete="current-password"
          className="mt-1 w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 text-sm text-slate-100 outline-none focus:border-white/20"
        />
      </div>
      <div>
        <label className="text-xs text-slate-400">New password</label>
        <input
          name="newPassword"
          type="password"
          autoComplete="new-password"
          className="mt-1 w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 text-sm text-slate-100 outline-none focus:border-white/20"
        />
      </div>
      <div>
        <label className="text-xs text-slate-400">Confirm new password</label>
        <input
          name="confirmPassword"
          type="password"
          autoComplete="new-password"
          className="mt-1 w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 text-sm text-slate-100 outline-none focus:border-white/20"
        />
      </div>

      <button
        disabled={pending}
        className="rounded-xl border border-white/10 bg-sky-400/20 px-4 py-2 text-sm font-semibold text-sky-200 hover:bg-sky-400/25 disabled:opacity-70"
      >
        {pending ? "Updating..." : "Change password"}
      </button>
    </form>
  );
}

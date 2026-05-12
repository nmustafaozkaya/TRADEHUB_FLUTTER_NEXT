"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";

import { updateUserInfoAction, type UserInfoFormState } from "./actions";

const initialState: UserInfoFormState = { error: null, success: null };

const inputClass =
  "mt-1.5 w-full rounded-xl border border-white/10 bg-[#0b1020]/55 px-3.5 py-2.5 text-sm text-slate-100 outline-none transition placeholder:text-slate-600 focus:border-indigo-400/45 focus:ring-2 focus:ring-indigo-400/20";

const labelClass = "text-[11px] font-semibold uppercase tracking-wide text-slate-500";

export function UserInfoForm(props: {
  initial: {
    username: string;
    nameSurname: string;
    email: string;
    gender: string;
    birthdate: string;
    phone: string;
  };
}) {
  const router = useRouter();
  const [state, formAction, pending] = useActionState(updateUserInfoAction, initialState);

  useEffect(() => {
    if (!state.success) return;
    router.refresh();
  }, [state.success, router]);

  const normalizedPhone = (props.initial.phone || "").trim();
  const phoneNumberOnly = normalizedPhone.startsWith("+90")
    ? normalizedPhone.slice(3).replace(/\s+/g, "")
    : normalizedPhone.replace(/\s+/g, "");

  return (
    <form action={formAction} className="space-y-5">
      {state.error ? (
        <div className="rounded-xl border border-rose-400/30 bg-rose-500/10 px-4 py-3 text-sm text-rose-100">
          {state.error}
        </div>
      ) : null}
      {state.success ? (
        <div className="rounded-xl border border-emerald-400/30 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-100">
          {state.success}
        </div>
      ) : null}

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="sm:col-span-2">
          <label className={labelClass}>Full name</label>
          <input name="nameSurname" defaultValue={props.initial.nameSurname} className={inputClass} required />
        </div>
        <div className="sm:col-span-2">
          <label className={labelClass}>Email</label>
          <input name="email" type="email" defaultValue={props.initial.email} className={inputClass} />
        </div>
        <div>
          <label className={labelClass}>Gender</label>
          <select
            name="gender"
            defaultValue={props.initial.gender || ""}
            className={`${inputClass} cursor-pointer`}
          >
            <option value="">Not selected</option>
            <option value="M">Male</option>
            <option value="F">Female</option>
            <option value="O">Other</option>
          </select>
        </div>
        <div>
          <label className={labelClass}>Birthday</label>
          <input name="birthdate" type="date" defaultValue={props.initial.birthdate} className={inputClass} />
        </div>
        <div className="sm:col-span-2">
          <label className={labelClass}>Phone</label>
          <div className="mt-1.5 grid grid-cols-5 gap-2">
            <div className="col-span-2 flex items-center gap-2 rounded-xl border border-white/10 bg-slate-950/60 px-3 py-2.5">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src="https://flagcdn.com/w20/tr.png"
                alt=""
                width={20}
                height={14}
                className="rounded-[2px] border border-white/15"
              />
              <span className="text-sm font-semibold text-slate-200">+90</span>
              <input type="hidden" name="phoneCode" value="+90" />
            </div>
            <input
              name="phoneNumber"
              defaultValue={phoneNumberOnly}
              placeholder="555 XXX XX XX"
              className="col-span-3 rounded-xl border border-white/10 bg-[#0b1020]/55 px-3.5 py-2.5 text-sm text-slate-100 outline-none transition focus:border-indigo-400/45 focus:ring-2 focus:ring-indigo-400/20"
            />
          </div>
        </div>
      </div>

      <button
        type="submit"
        disabled={pending}
        className="w-full rounded-xl bg-gradient-to-r from-indigo-500 to-indigo-600 px-4 py-3 text-sm font-bold text-white shadow-lg shadow-indigo-900/30 transition hover:from-indigo-400 hover:to-indigo-500 disabled:cursor-not-allowed disabled:opacity-60"
      >
        {pending ? "Saving…" : "Save profile"}
      </button>
    </form>
  );
}

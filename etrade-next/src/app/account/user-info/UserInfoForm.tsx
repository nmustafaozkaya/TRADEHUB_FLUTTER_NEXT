"use client";

import { useActionState } from "react";

import { updateUserInfoAction, type UserInfoFormState } from "./actions";

const initialState: UserInfoFormState = { error: null, success: null };

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
  const [state, formAction, pending] = useActionState(updateUserInfoAction, initialState);
  const normalizedPhone = (props.initial.phone || "").trim();
  const phoneNumberOnly = normalizedPhone.startsWith("+90")
    ? normalizedPhone.slice(3).replace(/\s+/g, "")
    : normalizedPhone.replace(/\s+/g, "");

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
        <label className="text-xs text-slate-400">Username</label>
        <input
          value={props.initial.username}
          disabled
          className="mt-1 w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 text-sm text-slate-300"
        />
      </div>
      <div>
        <label className="text-xs text-slate-400">Full name</label>
        <input
          name="nameSurname"
          defaultValue={props.initial.nameSurname}
          className="mt-1 w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 text-sm text-slate-100 outline-none focus:border-white/20"
        />
      </div>
      <div>
        <label className="text-xs text-slate-400">Email</label>
        <input
          name="email"
          type="email"
          defaultValue={props.initial.email}
          className="mt-1 w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 text-sm text-slate-100 outline-none focus:border-white/20"
        />
      </div>
      <div className="grid gap-3 sm:grid-cols-2">
        <div>
          <label className="text-xs text-slate-400">Gender</label>
          <select
            name="gender"
            defaultValue={props.initial.gender}
            className="mt-1 w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 text-sm text-slate-100 outline-none focus:border-white/20"
          >
            <option value="">Not selected</option>
            <option value="M">Male</option>
            <option value="F">Female</option>
            <option value="O">Other</option>
          </select>
        </div>
        <div>
          <label className="text-xs text-slate-400">Birth date</label>
          <input
            name="birthdate"
            type="date"
            defaultValue={props.initial.birthdate}
            className="mt-1 w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 text-sm text-slate-100 outline-none focus:border-white/20"
          />
        </div>
      </div>
      <div>
        <label className="text-xs text-slate-400">Phone</label>
        <div className="mt-1 grid grid-cols-5 gap-2">
          <div className="col-span-2 flex items-center gap-2 rounded-xl border border-white/10 bg-slate-900 px-2 py-2">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="https://flagcdn.com/w20/tr.png"
              alt="Turkey"
              width={20}
              height={14}
              className="rounded-[2px] border border-white/15"
            />
            <span className="text-sm font-medium text-slate-100">+90</span>
            <input type="hidden" name="phoneCode" value="+90" />
          </div>
          <input
            name="phoneNumber"
            defaultValue={phoneNumberOnly}
            placeholder="555 XXX XX XX"
            className="col-span-3 rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 text-sm text-slate-100 outline-none focus:border-white/20"
          />
        </div>
      </div>

      <button
        disabled={pending}
        className="rounded-xl border border-white/10 bg-sky-400/20 px-4 py-2 text-sm font-semibold text-sky-200 hover:bg-sky-400/25 disabled:opacity-70"
      >
        {pending ? "Saving..." : "Save changes"}
      </button>
    </form>
  );
}

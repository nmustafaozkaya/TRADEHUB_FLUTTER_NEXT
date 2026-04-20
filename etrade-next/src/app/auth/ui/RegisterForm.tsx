"use client";

import { useActionState } from "react";
import { registerAction } from "../actions";
import { Button } from "@/components/ui/Button";

export function RegisterForm() {
  const [state, formAction, pending] = useActionState(registerAction, {
    error: null,
    values: {
      username: "",
      password: "",
      nameSurname: "",
      email: "",
      gender: "",
      birthYear: "",
      birthMonth: "",
      birthDay: "",
      phoneCode: "+90",
      phoneNumber: "",
    },
  });
  const selectBaseClass =
    "w-full appearance-none rounded-xl border border-white/10 bg-slate-900 text-slate-100 text-base px-4 py-3 pr-10 outline-none focus:border-white/30";
  const birthSelectClass =
    "w-full appearance-none rounded-xl border border-white/10 bg-slate-900 text-slate-100 text-lg px-4 py-3 pr-10 outline-none focus:border-white/30";

  return (
    <form action={formAction} className="space-y-4">
      {state.error ? (
        <div className="rounded-xl border border-rose-400/30 bg-rose-400/10 px-3 py-2 text-sm text-rose-100">
          {state.error}
        </div>
      ) : null}

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <label className="block text-sm">
          <div className="mb-1 text-slate-300">Username</div>
          <input
            name="username"
            required
            defaultValue={state.values.username}
            className="w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 outline-none focus:border-white/20"
          />
        </label>

        <label className="block text-sm">
          <div className="mb-1 text-slate-300">Password (max 50)</div>
          <input
            name="password"
            type="password"
            required
            maxLength={50}
            defaultValue={state.values.password}
            className="w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 outline-none focus:border-white/20"
          />
        </label>

        <label className="block text-sm">
          <div className="mb-1 text-slate-300">Full name</div>
          <input
            name="nameSurname"
            defaultValue={state.values.nameSurname}
            className="w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 outline-none focus:border-white/20"
          />
        </label>

        <label className="block text-sm">
          <div className="mb-1 text-slate-300">Email</div>
          <input
            name="email"
            type="email"
            defaultValue={state.values.email}
            className="w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 outline-none focus:border-white/20"
          />
        </label>

        <label className="block text-sm">
          <div className="mb-1 text-slate-300">Gender</div>
          <div className="relative">
            <select
              name="gender"
              required
              className={selectBaseClass}
              defaultValue={state.values.gender || ""}
            >
              <option value="" disabled className="bg-slate-900 text-slate-400">
                Select gender
              </option>
              <option value="Male" className="bg-slate-900 text-slate-100">
                Male
              </option>
              <option value="Female" className="bg-slate-900 text-slate-100">
                Female
              </option>
              <option value="Other" className="bg-slate-900 text-slate-100">
                Other
              </option>
            </select>
            <span className="pointer-events-none absolute inset-y-0 right-3 flex items-center text-slate-400">▾</span>
          </div>
        </label>

        <div className="block text-sm sm:col-span-2">
          <div className="mb-1 text-slate-300">Birth date</div>
          <div className="grid grid-cols-3 gap-3">
            <div className="relative">
              <select
                name="birthYear"
                required
                defaultValue={state.values.birthYear || ""}
                className={birthSelectClass}
              >
                <option value="" disabled className="bg-slate-900 text-slate-300">
                  Year
                </option>
                {Array.from({ length: 80 }).map((_, index) => {
                  const year = new Date().getFullYear() - index;
                  return (
                    <option key={year} value={year}>
                      {year}
                    </option>
                  );
                })}
              </select>
              <span className="pointer-events-none absolute inset-y-0 right-3 flex items-center text-base text-slate-300">▾</span>
            </div>
            <div className="relative">
              <select
                name="birthMonth"
                required
                defaultValue={state.values.birthMonth || ""}
                className={birthSelectClass}
              >
                <option value="" disabled className="bg-slate-900 text-slate-300">
                  Month
                </option>
                {Array.from({ length: 12 }).map((_, index) => {
                  const month = String(index + 1).padStart(2, "0");
                  return (
                    <option key={month} value={month}>
                      {month}
                    </option>
                  );
                })}
              </select>
              <span className="pointer-events-none absolute inset-y-0 right-3 flex items-center text-base text-slate-300">▾</span>
            </div>
            <div className="relative">
              <select
                name="birthDay"
                required
                defaultValue={state.values.birthDay || ""}
                className={birthSelectClass}
              >
                <option value="" disabled className="bg-slate-900 text-slate-300">
                  Day
                </option>
                {Array.from({ length: 31 }).map((_, index) => {
                  const day = String(index + 1).padStart(2, "0");
                  return (
                    <option key={day} value={day}>
                      {day}
                    </option>
                  );
                })}
              </select>
              <span className="pointer-events-none absolute inset-y-0 right-3 flex items-center text-base text-slate-300">▾</span>
            </div>
          </div>
        </div>

        <div className="sm:col-span-2">
          <div className="mb-1 text-sm text-slate-300">Phone</div>
          <div className="grid grid-cols-5 gap-2">
            <div className="col-span-2 flex items-center gap-2 rounded-xl border border-white/10 bg-slate-900 px-2 py-1">
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
              required
              placeholder="555 XXX XX XX"
              defaultValue={state.values.phoneNumber}
              className="col-span-3 rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 outline-none focus:border-white/20"
            />
          </div>
        </div>
      </div>

      <Button disabled={pending} variant="primary" className="w-full">
        {pending ? "Creating..." : "Create account"}
      </Button>
    </form>
  );
}


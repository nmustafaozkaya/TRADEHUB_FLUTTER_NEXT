"use client";

import Link from "next/link";
import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

export default function AdminPage() {
  const router = useRouter();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    if (username === "admin" && password === "password") {
      sessionStorage.setItem("admin-auth", "ok");
      router.push("/admin/dashboard");
      return;
    }

    setError("Invalid username or password.");
  };

  return (
    <main className="relative mx-auto flex min-h-[72vh] w-full max-w-3xl items-center justify-center overflow-hidden rounded-3xl border border-indigo-500/20 bg-gradient-to-br from-slate-950 via-indigo-950 to-slate-950 p-6">
      <div className="absolute -left-16 -top-16 h-48 w-48 rounded-full bg-cyan-500/20 blur-3xl" />
      <div className="absolute -bottom-20 -right-10 h-52 w-52 rounded-full bg-fuchsia-500/20 blur-3xl" />

      <section className="relative w-full max-w-md rounded-2xl border border-slate-700/70 bg-slate-900/85 p-6 shadow-2xl shadow-black/40 backdrop-blur">
        <p className="text-xs uppercase tracking-[0.25em] text-cyan-300">
          Admin Access
        </p>
        <h1 className="mt-2 text-2xl font-semibold text-white">Admin Login</h1>
        <p className="mt-2 text-sm text-slate-300">
          This area is separate from the store interface. Sign in with your
          username and password to continue.
        </p>
        <form onSubmit={handleSubmit} className="mt-6 space-y-4">
          <div className="space-y-2">
            <label
              htmlFor="admin-username"
              className="text-xs font-medium uppercase tracking-wide text-slate-300"
            >
              Username
            </label>
            <input
              id="admin-username"
              type="text"
              name="username"
              placeholder="admin"
              value={username}
              onChange={(event) => setUsername(event.target.value)}
              className="w-full rounded-lg border border-slate-700 bg-slate-950/70 px-3 py-2 text-sm text-white outline-none transition focus:border-cyan-400"
            />
          </div>

          <div className="space-y-2">
            <label
              htmlFor="admin-password"
              className="text-xs font-medium uppercase tracking-wide text-slate-300"
            >
              Password
            </label>
            <input
              id="admin-password"
              type="password"
              name="password"
              placeholder="********"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className="w-full rounded-lg border border-slate-700 bg-slate-950/70 px-3 py-2 text-sm text-white outline-none transition focus:border-cyan-400"
            />
          </div>

          {error ? (
            <p className="rounded-md border border-rose-500/40 bg-rose-500/10 px-3 py-2 text-xs text-rose-200">
              {error}
            </p>
          ) : null}

          <button
            type="submit"
            className="w-full rounded-lg bg-cyan-500 px-4 py-2 text-sm font-semibold text-slate-950 transition hover:bg-cyan-400"
          >
            Sign In
          </button>
        </form>

        <Link
          href="/items"
          className="mt-4 inline-flex text-xs text-slate-400 transition hover:text-cyan-300"
        >
          Back to store
        </Link>
      </section>
    </main>
  );
}

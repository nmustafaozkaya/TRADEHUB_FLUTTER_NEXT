"use client";

import { useEffect, useMemo, useState } from "react";

import { Card, CardBody } from "@/components/ui/Card";
import { AddressForm } from "@/components/AddressForm";
import { DeleteAddressButton } from "@/components/DeleteAddressButton";
import { Button } from "@/components/ui/Button";

type AddressRow = {
  ID: number;
  AddressText: string | null;
  PostalCode: string | null;
  Country: string | null;
  City: string | null;
  Town: string | null;
  District: string | null;
};

export function AddressesManager(props: { addresses: AddressRow[] }) {
  const [open, setOpen] = useState(false);

  const hasAddresses = props.addresses.length > 0;
  const addresses = useMemo(() => props.addresses || [], [props.addresses]);

  useEffect(() => {
    if (!open) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open]);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-lg font-bold">Addresses</h2>
        {hasAddresses ? (
          <Button variant="primary" onClick={() => setOpen((v) => !v)}>
            {open ? "Close" : "Add new address"}
          </Button>
        ) : null}
      </div>

      {!hasAddresses ? (
        <div className="grid gap-3 md:grid-cols-2">
          <button
            type="button"
            onClick={() => setOpen(true)}
            className="group aspect-square rounded-2xl border border-dashed border-white/15 bg-white/5 p-5 text-left hover:border-white/25 hover:bg-white/10"
          >
            <div className="flex h-full flex-col items-center justify-center gap-3">
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl border border-white/10 bg-white/5 text-3xl font-black text-slate-100 transition group-hover:-translate-y-0.5">
                +
              </div>
                <div className="text-sm font-semibold text-slate-100">Add new address</div>
                <div className="text-xs text-slate-400">Click to save your address</div>
            </div>
          </button>
        </div>
      ) : (
        <div className="grid gap-3 md:grid-cols-2">
          {addresses.map((a) => (
            <Card key={a.ID}>
              <CardBody>
                <div className="text-sm font-bold text-slate-100">
                  {[a.Country, a.City, a.Town, a.District].filter(Boolean).join(" / ") || "Address"}
                </div>
                <div className="mt-2 text-sm text-slate-300">{a.AddressText || "-"}</div>
                <div className="mt-2 text-xs text-slate-400">Postal code: {a.PostalCode || "-"}</div>
                <div className="mt-4 flex justify-end">
                  <DeleteAddressButton id={a.ID} />
                </div>
              </CardBody>
            </Card>
          ))}

          <button
            type="button"
            onClick={() => setOpen(true)}
            className="group rounded-2xl border border-dashed border-white/15 bg-white/5 p-5 text-left hover:border-white/25 hover:bg-white/10"
          >
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-2xl font-black text-slate-100">
                +
              </div>
              <div>
                <div className="text-sm font-semibold text-slate-100">Add new address</div>
                <div className="text-xs text-slate-400">New delivery address</div>
              </div>
            </div>
          </button>
        </div>
      )}

      {open ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button
            type="button"
            aria-label="Close"
            onClick={() => setOpen(false)}
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
          />

          <div
            role="dialog"
            aria-modal="true"
            className="relative w-full max-w-2xl"
          >
            <Card className="bg-slate-950/95">
              <CardBody>
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h3 className="text-lg font-bold">Add address</h3>
                    <p className="mt-1 text-sm text-slate-400">
                      Country/city/town/district options come from the database.
                    </p>
                  </div>
                  <Button variant="soft" onClick={() => setOpen(false)}>
                    Close
                  </Button>
                </div>
                <div className="mt-4">
                  <AddressForm onSuccess={() => setOpen(false)} />
                </div>
              </CardBody>
            </Card>
          </div>
        </div>
      ) : null}
    </div>
  );
}


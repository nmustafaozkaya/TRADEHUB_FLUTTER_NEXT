"use client";

import { useEffect, useMemo, useState } from "react";
import { AddressForm } from "@/components/AddressForm";
import { Card, CardBody } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { cn } from "@/lib/ui";

type AddressRow = {
  ID: number;
  AddressText: string | null;
  PostalCode?: string | null;
  Country: string | null;
  City: string | null;
  Town: string | null;
  District: string | null;
};

function formatPlace(a: AddressRow) {
  const place = [a.Country, a.City, a.Town, a.District].filter(Boolean).join(" / ");
  return place || "Address";
}

export function CheckoutAddressPicker(props: {
  addresses: AddressRow[];
  name: string;
  inputName?: string;
}) {
  const inputName = props.inputName || "addressId";
  const addresses = useMemo(() => props.addresses || [], [props.addresses]);

  const [selectedId, setSelectedId] = useState<number>(() => Number(addresses[0]?.ID || 0));
  const [open, setOpen] = useState(false);
  const selectedIdEffective = useMemo(() => {
    if (!addresses.length) return 0;
    const exists = addresses.some((a) => Number(a.ID) === Number(selectedId));
    return exists ? Number(selectedId) : Number(addresses[0]?.ID || 0);
  }, [addresses, selectedId]);

  useEffect(() => {
    if (!open) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open]);

  return (
    <div className="space-y-3">
      <input
        type="hidden"
        name={inputName}
        value={selectedIdEffective ? String(selectedIdEffective) : ""}
      />

      <div className="flex items-center justify-between gap-3">
        <div>
          <div className="text-sm font-bold text-slate-100">Delivery address</div>
          <div className="mt-1 text-xs text-slate-400">Select where your order will be delivered.</div>
        </div>
        <Button type="button" variant="soft" onClick={() => setOpen(true)}>
          Add new address
        </Button>
      </div>

      {!addresses.length ? (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="group w-full rounded-2xl border border-dashed border-white/15 bg-white/5 p-5 text-left hover:border-white/25 hover:bg-white/10"
        >
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl border border-white/10 bg-white/5 text-2xl font-black text-slate-100 transition group-hover:-translate-y-0.5">
              +
            </div>
            <div>
              <div className="text-sm font-semibold text-slate-100">Add a delivery address</div>
              <div className="text-xs text-slate-400">You need an address to place an order.</div>
            </div>
          </div>
        </button>
      ) : (
        <div className="grid gap-3 md:grid-cols-2">
          {addresses.map((a) => {
            const active = Number(a.ID) === Number(selectedIdEffective);
            return (
              <button
                key={a.ID}
                type="button"
                role="radio"
                aria-checked={active}
                onClick={() => setSelectedId(Number(a.ID))}
                className={cn(
                  "rounded-2xl border bg-white/5 p-4 text-left transition hover:-translate-y-0.5 hover:border-white/20",
                  active ? "border-sky-400/30 bg-sky-400/10" : "border-white/10"
                )}
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="text-sm font-bold text-slate-100">{formatPlace(a)}</div>
                    <div className="mt-2 text-sm text-slate-300">{a.AddressText || "-"}</div>
                  </div>
                  <div
                    className={cn(
                      "mt-1 inline-flex h-5 w-5 shrink-0 items-center justify-center rounded-full border",
                      active ? "border-sky-400/50 bg-sky-400/20" : "border-white/15 bg-white/5"
                    )}
                  >
                    {active ? <span className="h-2.5 w-2.5 rounded-full bg-sky-200" /> : null}
                  </div>
                </div>
              </button>
            );
          })}
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

          <div role="dialog" aria-modal="true" className="relative w-full max-w-2xl">
            <Card className="bg-slate-950/95">
              <CardBody>
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h3 className="text-lg font-bold">Add address</h3>
                    <p className="mt-1 text-sm text-slate-400">
                      Country/city/town/district options come from the database.
                    </p>
                  </div>
                  <Button type="button" variant="soft" onClick={() => setOpen(false)}>
                    Close
                  </Button>
                </div>
                <div className="mt-4">
                  <AddressForm onSuccess={() => setOpen(false)} />
                </div>
              </CardBody>
            </Card>
            <div className="mt-2 text-xs text-slate-400">
              After adding an address, close this window and select it from the list.
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}


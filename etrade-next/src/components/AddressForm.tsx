"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";

import { Button } from "@/components/ui/Button";
import { showToast } from "@/components/ToastHost";

type Opt = { ID: number; Name: string };

async function fetchJson<T>(url: string): Promise<T> {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("Could not load.");
  return (await res.json()) as T;
}

export function AddressForm(props?: { onSuccess?: () => void }) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  const [countries, setCountries] = useState<Opt[]>([]);
  const [cities, setCities] = useState<Opt[]>([]);
  const [towns, setTowns] = useState<Opt[]>([]);
  const [districts, setDistricts] = useState<Opt[]>([]);

  const [countryId, setCountryId] = useState<number>(0);
  const [cityId, setCityId] = useState<number>(0);
  const [townId, setTownId] = useState<number>(0);
  const [districtId, setDistrictId] = useState<number>(0);

  const [postalCode, setPostalCode] = useState("");
  const [addressText, setAddressText] = useState("");

  useEffect(() => {
    fetchJson<Opt[]>("/api/locations/countries")
      .then((r) => setCountries(r))
      .catch(() => setCountries([]));
  }, []);

  useEffect(() => {
    setCityId(0);
    setTownId(0);
    setDistrictId(0);
    setCities([]);
    setTowns([]);
    setDistricts([]);

    if (!countryId) return;
    fetchJson<Opt[]>(`/api/locations/cities?countryId=${countryId}`)
      .then((r) => setCities(r))
      .catch(() => setCities([]));
  }, [countryId]);

  useEffect(() => {
    setTownId(0);
    setDistrictId(0);
    setTowns([]);
    setDistricts([]);

    if (!cityId) return;
    fetchJson<Opt[]>(`/api/locations/towns?cityId=${cityId}`)
      .then((r) => setTowns(r))
      .catch(() => setTowns([]));
  }, [cityId]);

  useEffect(() => {
    setDistrictId(0);
    setDistricts([]);

    if (!townId) return;
    fetchJson<Opt[]>(`/api/locations/districts?townId=${townId}`)
      .then((r) => setDistricts(r))
      .catch(() => setDistricts([]));
  }, [townId]);

  const canSubmit = useMemo(() => {
    return countryId && cityId && townId && districtId && addressText.trim().length >= 5;
  }, [countryId, cityId, townId, districtId, addressText]);
  const selectClass =
    "w-full rounded-xl border border-white/10 bg-slate-900 px-3 py-2 text-slate-100 outline-none focus:border-white/30 disabled:opacity-60";

  const submit = async () => {
    if (!canSubmit || loading) return;
    setLoading(true);
    try {
      const res = await fetch("/api/account/addresses", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          countryId,
          cityId,
          townId,
          districtId,
          postalCode: postalCode.trim() || null,
          addressText: addressText.trim(),
        }),
      });
      if (!res.ok) {
        const text = await res.text();
        throw new Error(text || "Could not add address.");
      }
      showToast({ type: "success", message: "Address added." });
      setPostalCode("");
      setAddressText("");
      router.refresh();
      props?.onSuccess?.();
    } catch (e) {
      showToast({ type: "danger", message: e instanceof Error ? e.message : "Error" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-3">
      <div className="grid gap-2 sm:grid-cols-2">
        <label className="text-sm">
          <div className="mb-1 text-slate-300">Country</div>
          <select
            value={countryId || ""}
            onChange={(e) => setCountryId(Number(e.target.value))}
            className={selectClass}
          >
            <option value="" className="bg-slate-900 text-slate-300">
              Select...
            </option>
            {countries.map((c) => (
              <option key={c.ID} value={c.ID} className="bg-slate-900 text-slate-100">
                {c.Name}
              </option>
            ))}
          </select>
        </label>

        <label className="text-sm">
          <div className="mb-1 text-slate-300">City</div>
          <select
            value={cityId || ""}
            onChange={(e) => setCityId(Number(e.target.value))}
            disabled={!countryId}
            className={selectClass}
          >
            <option value="" className="bg-slate-900 text-slate-300">
              Select...
            </option>
            {cities.map((c) => (
              <option key={c.ID} value={c.ID} className="bg-slate-900 text-slate-100">
                {c.Name}
              </option>
            ))}
          </select>
        </label>

        <label className="text-sm">
          <div className="mb-1 text-slate-300">Town</div>
          <select
            value={townId || ""}
            onChange={(e) => setTownId(Number(e.target.value))}
            disabled={!cityId}
            className={selectClass}
          >
            <option value="" className="bg-slate-900 text-slate-300">
              Select...
            </option>
            {towns.map((t) => (
              <option key={t.ID} value={t.ID} className="bg-slate-900 text-slate-100">
                {t.Name}
              </option>
            ))}
          </select>
        </label>

        <label className="text-sm">
          <div className="mb-1 text-slate-300">District</div>
          <select
            value={districtId || ""}
            onChange={(e) => setDistrictId(Number(e.target.value))}
            disabled={!townId}
            className={selectClass}
          >
            <option value="" className="bg-slate-900 text-slate-300">
              Select...
            </option>
            {districts.map((d) => (
              <option key={d.ID} value={d.ID} className="bg-slate-900 text-slate-100">
                {d.Name}
              </option>
            ))}
          </select>
        </label>
      </div>

      <div className="grid gap-2 sm:grid-cols-3">
        <label className="text-sm sm:col-span-1">
          <div className="mb-1 text-slate-300">Postal code</div>
          <input
            value={postalCode}
            onChange={(e) => setPostalCode(e.target.value)}
            className="w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 outline-none focus:border-white/20"
          />
        </label>
        <label className="text-sm sm:col-span-2">
          <div className="mb-1 text-slate-300">Address</div>
          <input
            value={addressText}
            onChange={(e) => setAddressText(e.target.value)}
            placeholder="Street, building no, apartment no..."
            className="w-full rounded-xl border border-white/10 bg-slate-950/30 px-3 py-2 outline-none focus:border-white/20"
          />
        </label>
      </div>

      <Button variant="primary" disabled={!canSubmit || loading} onClick={submit}>
        {loading ? "Adding..." : "Add address"}
      </Button>
    </div>
  );
}


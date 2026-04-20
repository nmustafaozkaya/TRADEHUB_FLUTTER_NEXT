import Link from "next/link";

import { requireAuth } from "@/lib/requireAuth";
import { listAddressesForUser } from "@/lib/repos/addresses";
import { AddressesManager } from "@/components/AddressesManager";

export const runtime = "nodejs";

export default async function AddressesPage() {
  const user = await requireAuth();
  const addresses = await listAddressesForUser(user.id);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-2xl font-extrabold">My Addresses</h1>
        <Link className="text-sm text-slate-400 hover:text-slate-200" href="/account">
          ← Back to account
        </Link>
      </div>

      <AddressesManager addresses={addresses} />
    </div>
  );
}


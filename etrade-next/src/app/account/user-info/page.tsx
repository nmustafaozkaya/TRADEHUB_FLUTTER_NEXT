import Link from "next/link";

import { Card, CardBody } from "@/components/ui/Card";
import { requireAuth } from "@/lib/requireAuth";
import { getUserProfileById } from "@/lib/repos/users";
import { UserInfoForm } from "./UserInfoForm";

export const runtime = "nodejs";

export default async function UserInfoPage() {
  const user = await requireAuth();
  const profile = await getUserProfileById(user.id);
  if (!profile) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-extrabold">My User Information</h1>
        <Card>
          <CardBody>
            <div className="text-slate-300">Could not load your profile.</div>
          </CardBody>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-2xl font-extrabold">My User Information</h1>
        <Link className="text-sm text-slate-400 hover:text-slate-200" href="/account">
          ← Back to account
        </Link>
      </div>

      <Card>
        <CardBody>
          <UserInfoForm
            initial={{
              username: profile.username,
              nameSurname: profile.nameSurname,
              email: profile.email,
              gender: profile.gender,
              birthdate: profile.birthdate,
              phone: profile.phone,
            }}
          />
        </CardBody>
      </Card>

    </div>
  );
}

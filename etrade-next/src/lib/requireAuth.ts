import { redirect } from "next/navigation";
import { getUser } from "./auth";

export async function requireAuth(nextPath?: string) {
  const user = await getUser();
  if (!user) {
    if (nextPath && nextPath.startsWith("/") && !nextPath.startsWith("//")) {
      redirect(`/auth/login?next=${encodeURIComponent(nextPath)}`);
    }
    redirect("/auth/login");
  }
  return user;
}


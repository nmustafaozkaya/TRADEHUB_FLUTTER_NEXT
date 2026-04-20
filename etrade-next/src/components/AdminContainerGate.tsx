"use client";

import { ReactNode } from "react";
import { usePathname } from "next/navigation";

type AdminContainerGateProps = {
  children: ReactNode;
};

export function AdminContainerGate({ children }: AdminContainerGateProps) {
  const pathname = usePathname();
  const isAdminRoute = pathname.startsWith("/admin");

  if (isAdminRoute) {
    return <div className="w-full px-4 py-6 lg:px-8">{children}</div>;
  }

  return <div className="mx-auto w-full max-w-6xl px-4 py-6">{children}</div>;
}


"use client";

import { ReactNode } from "react";
import { usePathname } from "next/navigation";

type HeaderGateProps = {
  children: ReactNode;
};

export function HeaderGate({ children }: HeaderGateProps) {
  const pathname = usePathname();
  const hideHeader = pathname.startsWith("/admin");

  if (hideHeader) {
    return null;
  }

  return <>{children}</>;
}

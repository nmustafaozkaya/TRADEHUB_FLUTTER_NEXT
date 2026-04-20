"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

export function PageTransition() {
  const router = useRouter();

  useEffect(() => {
    const reduce =
      typeof window !== "undefined" &&
      window.matchMedia &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    if (!reduce) {
      document.body.classList.add("ready");
    } else {
      document.body.classList.add("ready");
      return;
    }

    const onClick = (e: MouseEvent) => {
      if (e.defaultPrevented) return;
      if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
      const target = e.target as HTMLElement | null;
      const a = target?.closest?.("a") as HTMLAnchorElement | null;
      if (!a) return;
      if (a.target && a.target !== "_self") return;
      if (a.hasAttribute("download")) return;

      const href = a.getAttribute("href") || "";
      if (!href || href.startsWith("#") || href.startsWith("mailto:") || href.startsWith("tel:")) return;
      if (href.startsWith("http://") || href.startsWith("https://")) return;
      if (!href.startsWith("/")) return;

      e.preventDefault();
      document.body.classList.add("leaving");
      window.setTimeout(() => {
        router.push(href);
      }, 140);
      window.setTimeout(() => {
        document.body.classList.remove("leaving");
        document.body.classList.add("ready");
      }, 460);
    };

    document.addEventListener("click", onClick);
    return () => document.removeEventListener("click", onClick);
  }, [router]);

  return null;
}


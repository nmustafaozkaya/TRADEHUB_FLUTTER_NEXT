import { cn } from "@/lib/ui";

export function Card(props: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      {...props}
      className={cn(
        "rounded-2xl border border-white/10 bg-white/5 shadow-[0_18px_44px_rgba(0,0,0,0.18)]",
        props.className
      )}
    />
  );
}

export function CardBody(props: React.HTMLAttributes<HTMLDivElement>) {
  return <div {...props} className={cn("p-5", props.className)} />;
}


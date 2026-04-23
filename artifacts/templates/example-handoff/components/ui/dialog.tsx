import { ReactNode, useEffect } from "react";

interface Props {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
}

export function Dialog({ open, onClose, title, children }: Props) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={title}
      className="fixed inset-0 z-50 flex items-center justify-center"
    >
      <div
        className="absolute inset-0 bg-foreground/40"
        onClick={onClose}
      />
      <div className="relative bg-surface border border-muted rounded-lg p-6 max-w-md w-[90vw] shadow-lg">
        <h2 className="font-display text-xl font-semibold mb-3">{title}</h2>
        <div className="text-foreground">{children}</div>
      </div>
    </div>
  );
}

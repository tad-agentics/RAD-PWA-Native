import { HTMLAttributes } from "react";

type Tone = "neutral" | "success" | "warning" | "danger";

interface Props extends HTMLAttributes<HTMLSpanElement> {
  tone?: Tone;
}

const tones: Record<Tone, string> = {
  neutral: "bg-muted text-muted-foreground",
  success: "bg-success/15 text-success",
  warning: "bg-warning/15 text-warning",
  danger:  "bg-danger/15 text-danger",
};

export const Badge = ({ className = "", tone = "neutral", ...props }: Props) => (
  <span
    className={`inline-flex items-center px-2 py-0.5 rounded-sm text-xs font-medium ${tones[tone]} ${className}`}
    {...props}
  />
);

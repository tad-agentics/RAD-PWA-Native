import { HTMLAttributes, forwardRef } from "react";

export const Card = forwardRef<HTMLDivElement, HTMLAttributes<HTMLDivElement>>(
  ({ className = "", ...props }, ref) => (
    <div
      ref={ref}
      className={`bg-surface border border-muted rounded-lg p-4 ${className}`}
      {...props}
    />
  ),
);
Card.displayName = "Card";

export const CardHeader = ({ className = "", ...props }: HTMLAttributes<HTMLDivElement>) => (
  <div className={`mb-3 ${className}`} {...props} />
);

export const CardTitle = ({ className = "", ...props }: HTMLAttributes<HTMLHeadingElement>) => (
  <h3 className={`font-display text-lg font-semibold ${className}`} {...props} />
);

export const CardBody = ({ className = "", ...props }: HTMLAttributes<HTMLDivElement>) => (
  <div className={`text-foreground ${className}`} {...props} />
);

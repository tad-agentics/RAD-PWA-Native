import { useState } from "react";
import { Button } from "../components/ui/button";
import { Card, CardHeader, CardTitle, CardBody } from "../components/ui/card";
import { Badge } from "../components/ui/badge";

interface Props {
  onBack: () => void;
}

export function SettingsScreen({ onBack }: Props) {
  const [theme, setTheme] = useState<"system" | "light" | "dark">("system");
  const [autosave, setAutosave] = useState(true);

  return (
    <main className="max-w-2xl mx-auto p-6">
      <header className="flex items-center justify-between mb-6">
        <Button variant="ghost" size="sm" onClick={onBack}>
          ← Back
        </Button>
        <h1 className="font-display text-xl font-semibold">Settings</h1>
        <div className="w-16" /> {/* spacer for symmetric header */}
      </header>

      <div className="space-y-4">
        <Card>
          <CardHeader>
            <CardTitle>Appearance</CardTitle>
          </CardHeader>
          <CardBody>
            <div className="flex gap-2">
              {(["system", "light", "dark"] as const).map((t) => (
                <Button
                  key={t}
                  variant={theme === t ? "primary" : "secondary"}
                  size="sm"
                  onClick={() => setTheme(t)}
                >
                  {t[0].toUpperCase() + t.slice(1)}
                </Button>
              ))}
            </div>
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Editor</CardTitle>
          </CardHeader>
          <CardBody>
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium">Autosave</p>
                <p className="text-sm text-muted-foreground">
                  Save the current note as you type.
                </p>
              </div>
              <Button
                variant={autosave ? "primary" : "secondary"}
                size="sm"
                onClick={() => setAutosave((v) => !v)}
              >
                {autosave ? "On" : "Off"}
              </Button>
            </div>
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>Plan</CardTitle>
              <Badge tone="success">Free</Badge>
            </div>
          </CardHeader>
          <CardBody>
            <p className="text-sm text-muted-foreground mb-3">
              You're on the free plan. Upgrade for unlimited notes and shared
              workspaces.
            </p>
            <Button variant="primary" size="sm">
              Upgrade
            </Button>
          </CardBody>
        </Card>
      </div>
    </main>
  );
}

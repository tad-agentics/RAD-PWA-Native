import { useState } from "react";
import { Button } from "../components/ui/button";
import { Card, CardHeader, CardTitle, CardBody } from "../components/ui/card";
import { Badge } from "../components/ui/badge";
import { Input } from "../components/ui/input";

// Mock data colocated with the screen — Foundation replaces this with a
// useNotes() TanStack Query hook against Supabase. The shape stays the same.
const MOCK_NOTES = [
  { id: "n1", title: "Quarterly review prep", excerpt: "Three themes — retention, pricing, hiring.", tag: "work",   updatedAt: "2026-04-18" },
  { id: "n2", title: "Trip ideas: April long weekend", excerpt: "Đà Lạt vs Phú Quốc; weather + flight cost trade.", tag: "personal", updatedAt: "2026-04-17" },
  { id: "n3", title: "Reading queue", excerpt: "Two books from the studio compounding-asset doc.", tag: "personal", updatedAt: "2026-04-15" },
  { id: "n4", title: "RAD wiring contract notes", excerpt: "Trust mode per binding, Zod parse on Edge response.", tag: "work",   updatedAt: "2026-04-12" },
];

interface Props {
  onOpenNote: (id: string) => void;
  onOpenSettings: () => void;
}

export function NotesListScreen({ onOpenNote, onOpenSettings }: Props) {
  const [query, setQuery] = useState("");
  const filtered = MOCK_NOTES.filter((n) =>
    n.title.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <main className="max-w-2xl mx-auto p-6">
      <header className="flex items-center justify-between mb-6">
        <h1 className="font-display text-2xl font-semibold">Notebook</h1>
        <Button variant="ghost" size="sm" onClick={onOpenSettings}>
          Settings
        </Button>
      </header>

      <Input
        placeholder="Search notes…"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        className="mb-4"
      />

      {filtered.length === 0 ? (
        <Card>
          <CardBody>
            <p className="text-muted-foreground">
              No notes match. Clear the search or start a new note.
            </p>
          </CardBody>
        </Card>
      ) : (
        <ul className="space-y-3">
          {filtered.map((n) => (
            <li key={n.id}>
              <Card
                role="button"
                tabIndex={0}
                onClick={() => onOpenNote(n.id)}
                className="cursor-pointer hover:border-primary/40 transition-colors"
              >
                <CardHeader>
                  <div className="flex items-center justify-between gap-3">
                    <CardTitle>{n.title}</CardTitle>
                    <Badge tone={n.tag === "work" ? "neutral" : "success"}>
                      {n.tag}
                    </Badge>
                  </div>
                </CardHeader>
                <CardBody>
                  <p className="text-sm text-muted-foreground mb-2">
                    {n.excerpt}
                  </p>
                  <span className="text-xs text-muted-foreground">
                    Updated {n.updatedAt}
                  </span>
                </CardBody>
              </Card>
            </li>
          ))}
        </ul>
      )}

      <Button
        className="fixed bottom-6 right-6 shadow-lg"
        size="lg"
        onClick={() => onOpenNote("new")}
      >
        New note
      </Button>
    </main>
  );
}

import { useState } from "react";
import { Button } from "../components/ui/button";
import { Card, CardBody } from "../components/ui/card";
import { Input, Textarea } from "../components/ui/input";
import { Dialog } from "../components/ui/dialog";

// Mock note source — Foundation replaces with useNote(id) hook.
const MOCK_NOTE = {
  id: "n1",
  title: "Quarterly review prep",
  body:
    "Three themes for the review: retention (focus on day-7 cohort), pricing (intro tier ceiling), hiring (one senior backend, one designer).",
  tag: "work",
  updatedAt: "2026-04-18",
};

interface Props {
  noteId: string;
  onBack: () => void;
}

export function NoteDetailScreen({ noteId, onBack }: Props) {
  const isNew = noteId === "new";
  const [title, setTitle] = useState(isNew ? "" : MOCK_NOTE.title);
  const [body, setBody] = useState(isNew ? "" : MOCK_NOTE.body);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [savedAt, setSavedAt] = useState<string | null>(
    isNew ? null : MOCK_NOTE.updatedAt
  );

  function handleSave() {
    // Foundation wires this to a useUpdateNote / useCreateNote mutation.
    setSavedAt(new Date().toISOString().slice(0, 10));
  }

  return (
    <main className="max-w-2xl mx-auto p-6">
      <header className="flex items-center justify-between mb-6">
        <Button variant="ghost" size="sm" onClick={onBack}>
          ← Back
        </Button>
        <div className="flex gap-2">
          {!isNew && (
            <Button
              variant="danger"
              size="sm"
              onClick={() => setConfirmDelete(true)}
            >
              Delete
            </Button>
          )}
          <Button size="sm" onClick={handleSave} disabled={!title.trim()}>
            Save
          </Button>
        </div>
      </header>

      <Card>
        <CardBody>
          <Input
            placeholder="Title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="mb-3 text-lg font-semibold"
          />
          <Textarea
            placeholder="Write your note…"
            value={body}
            onChange={(e) => setBody(e.target.value)}
          />
          {savedAt && (
            <p className="text-xs text-muted-foreground mt-3">
              Saved {savedAt}
            </p>
          )}
        </CardBody>
      </Card>

      <Dialog
        open={confirmDelete}
        onClose={() => setConfirmDelete(false)}
        title="Delete this note?"
      >
        <p className="mb-4 text-muted-foreground">
          This cannot be undone. The note will be removed from your account.
        </p>
        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={() => setConfirmDelete(false)}>
            Cancel
          </Button>
          <Button
            variant="danger"
            onClick={() => {
              // Foundation wires this to useDeleteNote mutation.
              setConfirmDelete(false);
              onBack();
            }}
          >
            Delete
          </Button>
        </div>
      </Dialog>
    </main>
  );
}

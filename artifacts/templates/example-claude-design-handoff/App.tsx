// Example Claude Design entrypoint.
// In a real handoff this file wires every screen into the routes available
// at preview time. RAD's Foundation step copies the screens from screens/*
// into src/routes/_app/* and re-wires routing via React Router v7.

import { useState } from "react";
import { NotesListScreen } from "./screens/notes-list";
import { NoteDetailScreen } from "./screens/note-detail";
import { SettingsScreen } from "./screens/settings";

type Screen = "list" | "detail" | "settings";

export default function App() {
  const [screen, setScreen] = useState<Screen>("list");
  const [activeNoteId, setActiveNoteId] = useState<string | null>(null);

  if (screen === "detail" && activeNoteId) {
    return (
      <NoteDetailScreen
        noteId={activeNoteId}
        onBack={() => setScreen("list")}
      />
    );
  }

  if (screen === "settings") {
    return <SettingsScreen onBack={() => setScreen("list")} />;
  }

  return (
    <NotesListScreen
      onOpenNote={(id) => {
        setActiveNoteId(id);
        setScreen("detail");
      }}
      onOpenSettings={() => setScreen("settings")}
    />
  );
}

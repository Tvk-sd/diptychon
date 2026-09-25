import {
  Action,
  ActionPanel,
  Icon,
  Keyboard,
  List,
  closeMainWindow,
  showHUD,
} from "@raycast/api";
import { useEffect, useState } from "react";
import {
  basename,
  isInstalled,
  readState,
  revealInDiptychon,
  shortenPath,
  SITE,
  type DiptychonState,
} from "./diptychon";

/**
 * Show what Diptychon has open, and jump to either side.
 *
 * Two honest limits are surfaced in the UI rather than papered over:
 * the state is the last *saved* state (written on a 500 ms debounce), and
 * which panel is Active is not persisted, so this says Left and Right.
 */
export default function Command() {
  const [state, setState] = useState<DiptychonState | null>(null);
  const [loading, setLoading] = useState(true);
  const installed = isInstalled();

  useEffect(() => {
    if (!installed) {
      setLoading(false);
      return;
    }
    readState()
      .then(setState)
      .finally(() => setLoading(false));
  }, [installed]);

  if (!installed) {
    return (
      <List>
        <List.EmptyView
          icon={Icon.Download}
          title="Diptychon is not installed"
          actions={
            <ActionPanel>
              <Action.OpenInBrowser title="Open Diptychon.com" url={SITE} />
            </ActionPanel>
          }
        />
      </List>
    );
  }

  const workspace = state?.workspace ?? null;
  const staged = workspace?.staging ?? [];

  const panels: { side: string; path: string }[] = workspace
    ? [
        { side: "Left Panel", path: workspace.left.directoryPath },
        { side: "Right Panel", path: workspace.right.directoryPath },
      ]
    : [];

  return (
    <List
      isLoading={loading}
      searchBarPlaceholder="Search what Diptychon has open"
    >
      <List.EmptyView
        icon={Icon.Window}
        title="No saved workspace"
        description="Diptychon has not written a state yet, or runs with DIPTYCHON_DIR set."
      />

      {panels.length > 0 && (
        <List.Section title="Panels" subtitle="last saved state">
          {panels.map(({ side, path }) => (
            <List.Item
              key={side}
              icon={Icon.Folder}
              title={basename(path)}
              subtitle={shortenPath(path)}
              accessories={[{ text: side }]}
              actions={<OpenActions path={path} />}
            />
          ))}
        </List.Section>
      )}

      {staged.length > 0 && (
        <List.Section
          title="Staging"
          subtitle={`${staged.length} item${staged.length === 1 ? "" : "s"}`}
        >
          {staged.map((path) => (
            <List.Item
              key={path}
              icon={Icon.Tray}
              title={basename(path)}
              subtitle={shortenPath(path)}
              actions={<OpenActions path={path} />}
            />
          ))}
        </List.Section>
      )}
    </List>
  );
}

function OpenActions({ path }: { path: string }) {
  return (
    <ActionPanel>
      <Action
        title="Open in Diptychon"
        icon={Icon.ArrowRight}
        onAction={async () => {
          await closeMainWindow();
          await revealInDiptychon(path);
          await showHUD(`Opened ${basename(path)} in Diptychon`);
        }}
      />
      <Action.ShowInFinder path={path} />
      <Action.CopyToClipboard
        title="Copy Path"
        content={path}
        shortcut={Keyboard.Shortcut.Common.CopyPath}
      />
    </ActionPanel>
  );
}

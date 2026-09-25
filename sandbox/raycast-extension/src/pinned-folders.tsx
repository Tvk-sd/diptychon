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
} from "./diptychon";

/**
 * List the folders already pinned in Diptychon's sidebar.
 *
 * Deliberately not a second pin list: this reads `pinnedFolders` out of the
 * app's own preferences, so there is exactly one place to add or remove a pin,
 * and it is inside Diptychon.
 */
export default function Command() {
  const [pinned, setPinned] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const installed = isInstalled();

  useEffect(() => {
    if (!installed) {
      setLoading(false);
      return;
    }
    readState()
      .then((state) => setPinned(state.pinnedFolders))
      .finally(() => setLoading(false));
  }, [installed]);

  if (!installed) {
    return (
      <List>
        <List.EmptyView
          icon={Icon.Download}
          title="Diptychon is not installed"
          description="This command reads the pinned folders out of the app."
          actions={
            <ActionPanel>
              <Action.OpenInBrowser title="Open Diptychon.com" url={SITE} />
            </ActionPanel>
          }
        />
      </List>
    );
  }

  return (
    <List isLoading={loading} searchBarPlaceholder="Search pinned folders">
      <List.EmptyView
        icon={Icon.Pin}
        title="No pinned folders"
        description="Pin a folder in Diptychon's sidebar and it appears here."
      />
      {pinned.map((path) => (
        <List.Item
          key={path}
          icon={Icon.Folder}
          title={basename(path)}
          subtitle={shortenPath(path)}
          actions={
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
          }
        />
      ))}
    </List>
  );
}

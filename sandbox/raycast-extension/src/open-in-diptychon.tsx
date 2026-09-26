import {
  Toast,
  closeMainWindow,
  getSelectedFinderItems,
  showHUD,
  showToast,
} from "@raycast/api";
import { basename, requireDiptychon, revealInDiptychon } from "./diptychon";

/**
 * Take what is selected in Finder and open it in Diptychon's Active Panel.
 *
 * Known limit, stated rather than hidden: `getSelectedFinderItems` answers only
 * for Finder. If the selection lives in another file manager — including
 * Diptychon itself — Raycast cannot see it, and no API exists that would let it.
 */
export default async function command() {
  if (!(await requireDiptychon())) return;

  let paths: string[] = [];
  try {
    paths = (await getSelectedFinderItems()).map((item) => item.path);
  } catch {
    // Rejects when Finder is not the frontmost application.
    await showToast({
      style: Toast.Style.Failure,
      title: "No Finder selection",
      message: "Bring Finder forward and select a file or folder.",
    });
    return;
  }

  if (paths.length === 0) {
    await showToast({
      style: Toast.Style.Failure,
      title: "Nothing selected in Finder",
      message: "Select a file or folder first.",
    });
    return;
  }

  // One Active Panel means one destination. Say so instead of silently
  // dropping the rest.
  const [first] = paths;
  await closeMainWindow();
  await revealInDiptychon(first);
  await showHUD(
    paths.length === 1
      ? `Opened ${basename(first)} in Diptychon`
      : `Opened ${basename(first)} in Diptychon — ${paths.length - 1} more not opened`,
  );
}

import { execFile, execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { promisify } from "node:util";
import { Toast, showToast, open } from "@raycast/api";

const run = promisify(execFile);

export const BUNDLE_ID = "com.diptychon.app";
export const APP_PATH = "/Applications/Diptychon.app";
export const SITE = "https://diptychon.com";

export function isInstalled(): boolean {
  return existsSync(APP_PATH);
}

/**
 * Show one honest failure toast when Diptychon is missing, with a way out.
 * Returns false when the caller should stop.
 */
export async function requireDiptychon(): Promise<boolean> {
  if (isInstalled()) return true;
  await showToast({
    style: Toast.Style.Failure,
    title: "Diptychon is not installed",
    message: "Get it at diptychon.com",
    primaryAction: { title: "Open diptychon.com", onAction: () => open(SITE) },
  });
  return false;
}

/**
 * Hand a path to Diptychon. A folder opens in the Active Panel; a file opens
 * its folder and highlights the file — both are `navigateIfPath` on the app
 * side, so this command adds no behaviour of its own.
 */
export async function revealInDiptychon(path: string): Promise<void> {
  await open(path, BUNDLE_ID);
}

/** The whole preferences domain as an XML plist, or null when unreadable. */
async function exportPreferences(): Promise<string | null> {
  try {
    const { stdout } = await run("defaults", ["export", BUNDLE_ID, "-"]);
    return stdout;
  } catch {
    return null;
  }
}

function extract(
  plist: string,
  key: string,
  format: "json" | "raw",
): string | null {
  try {
    return execFileSync("plutil", ["-extract", key, format, "-o", "-", "-"], {
      input: plist,
      encoding: "utf8",
    }).trim();
  } catch {
    // The key is simply absent — Diptychon writes a key only once it has a value.
    return null;
  }
}

export type PaneState = {
  directoryPath: string;
  sort?: { column: string; ascending: boolean };
  displayMode?: string;
};

export type WorkspaceState = {
  schemaVersion: number;
  left: PaneState;
  right: PaneState;
  staging?: string[];
  terminalVisible?: boolean;
};

export type DiptychonState = {
  pinnedFolders: string[];
  workspace: WorkspaceState | null;
};

/**
 * Read what Diptychon persisted. This is a snapshot of the *saved* state, not
 * the live window: the app writes on a 500 ms debounce, so a folder changed a
 * moment ago may not be here yet. Selection is not persisted at all and cannot
 * be read from outside.
 */
export async function readState(): Promise<DiptychonState> {
  const plist = await exportPreferences();
  if (!plist) return { pinnedFolders: [], workspace: null };

  let pinnedFolders: string[] = [];
  const pinnedJson = extract(plist, "pinnedFolders", "json");
  if (pinnedJson) {
    try {
      pinnedFolders = JSON.parse(pinnedJson);
    } catch {
      pinnedFolders = [];
    }
  }

  let workspace: WorkspaceState | null = null;
  const blob = extract(plist, "workspaceState", "raw");
  if (blob) {
    try {
      workspace = JSON.parse(Buffer.from(blob, "base64").toString("utf8"));
    } catch {
      // A shape this extension does not know. Treat it as absent rather than
      // guessing — the app tolerates the same case on its own restore path.
      workspace = null;
    }
  }

  return { pinnedFolders, workspace };
}

/** `/Users/till/Projects` reads as `~/Projects`. */
export function shortenPath(path: string): string {
  const home = process.env.HOME;
  return home && path.startsWith(home) ? `~${path.slice(home.length)}` : path;
}

export function basename(path: string): string {
  const parts = path.replace(/\/+$/, "").split("/");
  return parts[parts.length - 1] || path;
}

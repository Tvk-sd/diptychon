import { defineConfig } from "oxlint";
import core from "ultracite/oxlint/core";

export default defineConfig({
  extends: [core],
  // Same scope as the formatter: the Worker source only.
  ignorePatterns: [...core.ignorePatterns, "/*", "!/src/"],
});

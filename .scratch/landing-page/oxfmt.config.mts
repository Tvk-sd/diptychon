import { defineConfig } from "oxfmt";
import ultracite from "ultracite/oxfmt";

export default defineConfig({
  ...ultracite,
  // The site's HTML/CSS/Markdown is hand-written and shipped as-is; only the
  // Cloudflare Worker source is Ultracite's business here.
  ignorePatterns: ["/*", "!/src/"],
});

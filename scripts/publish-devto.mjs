#!/usr/bin/env node

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";

const API = "https://dev.to/api/articles";
const STATE_FILE = resolve("content/blog/.devto.json");
const CONFIG_FILE = resolve("content/blog/.config.json");

function loadConfig() {
  if (!existsSync(CONFIG_FILE)) return { ownSiteLive: false };
  return JSON.parse(readFileSync(CONFIG_FILE, "utf8"));
}

function usage() {
  console.log(`Publish an article to Dev.to from a markdown file with YAML frontmatter.

Usage:
  node scripts/publish-devto.mjs <article.md> [--draft|--publish] [--dry-run]

Options:
  --draft       Create/update the article as a draft (default for new posts)
  --publish     Create/update the article as published
  --dry-run     Print the payload without calling the API

Environment:
  DEVTO_API_KEY  Your Dev.to API key (dev.to/settings/extensions)

Examples:
  DEVTO_API_KEY=xxx node scripts/publish-devto.mjs content/blog/drafts/first-post/index.md --draft
  DEVTO_API_KEY=xxx node scripts/publish-devto.mjs content/blog/drafts/first-post/index.md --publish`);
}

function parseArgs(argv) {
  const articlePath = argv.find((a) => !a.startsWith("--"));
  const flags = argv.filter((a) => a.startsWith("--"));
  if (!articlePath || flags.length === 0) {
    usage();
    process.exit(1);
  }
  return {
    articlePath: resolve(articlePath),
    publish: flags.includes("--publish"),
    draft: flags.includes("--draft"),
    dryRun: flags.includes("--dry-run"),
  };
}

function parseScalar(raw) {
  let value = raw.trim();
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    value = value.slice(1, -1);
  }
  return value;
}

function parseFrontmatter(raw) {
  const lines = raw.replace(/^\uFEFF/, "").split(/\r?\n/);
  const frontmatter = {};
  let body = "";
  let inFrontmatter = false;
  let closed = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (i === 0 && line.trim() === "---") {
      inFrontmatter = true;
      continue;
    }
    if (inFrontmatter) {
      if (line.trim() === "---") {
        inFrontmatter = false;
        closed = true;
        continue;
      }
      const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
      if (match) {
        const [, key, value] = match;
        if (value.startsWith("[") && value.endsWith("]")) {
          frontmatter[key] = value
            .slice(1, -1)
            .split(",")
            .map((t) => parseScalar(t))
            .filter(Boolean);
        } else {
          frontmatter[key] = parseScalar(value);
        }
      }
      continue;
    }
    if (closed) {
      body = lines.slice(i).join("\n");
      break;
    }
  }
  return { frontmatter, body };
}

function loadState() {
  if (!existsSync(STATE_FILE)) return {};
  return JSON.parse(readFileSync(STATE_FILE, "utf8"));
}

function saveState(state) {
  writeFileSync(STATE_FILE, JSON.stringify(state, null, 2) + "\n");
}

async function callDevto(path, key, payload) {
  const res = await fetch(path, {
    method: "POST",
    headers: {
      "api-key": key,
      "content-type": "application/json",
      accept: "application/vnd.forem.api-v1+json",
    },
    body: JSON.stringify(payload),
  });
  const json = await res.json();
  if (!res.ok) {
    throw new Error(`Dev.to API error ${res.status}: ${JSON.stringify(json)}`);
  }
  return json;
}

async function findArticleByTitle(key, title) {
  for (let page = 1; ; page++) {
    const res = await fetch(`${API}/me/all?page=${page}&per_page=1000`, {
      headers: {
        "api-key": key,
        accept: "application/vnd.forem.api-v1+json",
      },
    });
    const json = await res.json();
    if (!res.ok) {
      throw new Error(`Dev.to API error ${res.status}: ${JSON.stringify(json)}`);
    }
    const found = json.find((a) => a.title === title);
    if (found) return found;
    if (json.length < 1000) return null;
  }
}

async function main() {
  const { articlePath, publish, draft, dryRun } = parseArgs(process.argv.slice(2));

  const file = readFileSync(articlePath, "utf8");
  const { frontmatter, body } = parseFrontmatter(file);

  if (!frontmatter.title || !body.trim()) {
    console.error("Error: article must have a title and body content.");
    process.exit(1);
  }

  const tags = Array.isArray(frontmatter.tags) ? frontmatter.tags.slice(0, 4) : [];
  if (Array.isArray(frontmatter.tags) && frontmatter.tags.length > 4) {
    console.warn(`Warning: Dev.to allows max 4 tags; using [${tags.join(", ")}].`);
  }

  const apiKey = process.env.DEVTO_API_KEY;
  if (!apiKey && !dryRun) {
    console.error("Error: DEVTO_API_KEY is not set.");
    process.exit(1);
  }

  const config = loadConfig();
  const payload = {
    article: {
      title: frontmatter.title,
      body_markdown: body.trim(),
      published: publish,
      tags,
      ...(frontmatter.description ? { description: frontmatter.description } : {}),
      ...(config.ownSiteLive && frontmatter.canonical
        ? { canonical_url: frontmatter.canonical }
        : {}),
    },
  };

  const state = loadState();
  let existing = state[articlePath] ?? null;
  if (!existing && apiKey) {
    existing = await findArticleByTitle(apiKey, frontmatter.title);
  }

  if (dryRun) {
    console.log("DRY RUN — would send:");
    console.log(JSON.stringify(payload, null, 2));
    if (existing) console.log(`\n(existing article id ${existing.id} would be updated)`);
    return;
  }

  const key = existing ? existing.id : null;
  const endpoint = existing ? `${API}/${key}` : API;

  if (existing) {
    const res = await fetch(endpoint, {
      method: "PUT",
      headers: {
        "api-key": apiKey,
        "content-type": "application/json",
        accept: "application/vnd.forem.api-v1+json",
      },
      body: JSON.stringify(payload),
    });
    const json = await res.json();
    if (!res.ok) {
      throw new Error(`Dev.to API error ${res.status}: ${JSON.stringify(json)}`);
    }
    state[articlePath] = { id: json.id, url: json.url };
    saveState(state);
    console.log(`Updated: ${json.url}`);
    return;
  }

  const created = await callDevto(endpoint, apiKey, payload);
  state[articlePath] = { id: created.id, url: created.url };
  saveState(state);
  console.log(
    `${created.published ? "Published" : "Draft created"}: ${created.url}`
  );
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});

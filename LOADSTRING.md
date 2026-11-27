# Loadstrings

Repo: `vornecc-pixel/NHAC-V2---SOURCE-CODE-SKID` (private)
Branch with these files: `arena/54e891b6-nhac-v2-source-code-skid` (head `81c52d3`)

## Status: not publicly reachable yet

The loadstrings below need a **public** URL. Executors download anonymously, so a
private repo answers `404: Not Found` — that is the error in the console
(`[VORNECC] download failed -> 404: Not Found`).

Publishing from this session was attempted and blocked by the Arena GitHub
connection, which only has write access to `NHAC-V2---SOURCE-CODE-SKID`:

| Attempt | Result |
|---|---|
| `gh gist create --public ui_test.lua ...` | `403 Resource not accessible by integration` |
| `gh repo create vornecc-ui --public` | `403 createRepository` |
| `gh api PUT .../NHAC-V2---SOURCE-CODE-SKIDDED/contents/ui_test.lua` | `403` |
| `git push --dry-run` → public mirror repo | `403 Permission denied` |

Fix on the Arena side: reconnect GitHub with broader permissions (gist + repo
creation + write to other repos), or do one of the 2-minute routes below.

---

## Publish it yourself (pick one)

### A. Make this repo public — zero other work

GitHub → repo → **Settings → General → Danger zone → Change visibility → Public**.
The URLs in section 1/2/3 then work exactly as written, nothing else to change.

### B. Create the gist (web, ~1 min)

1. Open <https://gist.github.com>
2. Drag `ui_test.lua` (+ optionally `ui_test_harness.lua`, `gamesense.txt`) into the page
3. **Create public gist**, then copy the URL, e.g.
   `https://gist.github.com/vornecc-pixel/abc123def456`

Raw URL for a file in that gist:

```
https://gist.githubusercontent.com/vornecc-pixel/abc123def456/raw/ui_test.lua
```

### C. Create the gist (CLI, one command)

From a clone of this repo:

```bash
gh gist create --public ui_test.lua ui_test_harness.lua gamesense.txt
```

It prints the gist URL; take the raw URL as in B.

> **Tip:** if pasting the 363 KB `ui_test.lua` is annoying, publish only
> `ui_test_harness.lua` (29 KB). Run your existing menu script first, then run
> the harness loadstring — it appends the test UI to the loaded `Library`.

---

## 1. Full UI + self-test  (`ui_test.lua`)

```lua
loadstring(game:HttpGet("https://gist.githubusercontent.com/vornecc-pixel/<GIST_ID>/raw/ui_test.lua"))()
```

Same thing, using this repo's raw URL (only after route A):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/vornecc-pixel/NHAC-V2---SOURCE-CODE-SKID/arena/54e891b6-nhac-v2-source-code-skid/ui_test.lua"))()
```

## 2. Redesigned UI only, no tests  (`gamesense.txt`)

```lua
loadstring(game:HttpGet("https://gist.githubusercontent.com/vornecc-pixel/<GIST_ID>/raw/gamesense.txt"))()
```

## 3. Harness only  (`ui_test_harness.lua`)

Not standalone — `Library` must already be loaded in the executor.

```lua
loadstring(game:HttpGet("https://gist.githubusercontent.com/vornecc-pixel/<GIST_ID>/raw/ui_test_harness.lua"))()
```

---

## Safer loader (use this one)

Uses `loadstring` or `load`, and reports the real failure instead of dying silently:

```lua
local URL = "https://gist.githubusercontent.com/vornecc-pixel/<GIST_ID>/raw/ui_test.lua"

local Ok, Source = pcall(function() return game:HttpGet(URL, true) end)

if not Ok or type(Source) ~= "string" or #Source < 1000 then
    return warn("[VORNECC] download failed -> " .. tostring(Source) .. " (private repo / wrong gist id?)")
end

local Chunk, Err = (loadstring or load)(Source, "VORNECC_UI")

if not Chunk then
    return warn("[VORNECC] compile failed -> " .. tostring(Err))
end

Chunk()
```

## No hosting at all

1. Drop `ui_test.lua` into the executor's workspace folder, then:

   ```lua
   loadstring(readfile("ui_test.lua"))()
   ```

2. Or open `ui_test.lua` in the executor editor and press execute — no network
   dependency, works even if GitHub is blocked.

## Housekeeping

- Never put a GitHub personal access token in a loadstring; anything running in
  an executor can read it.
- Gist URLs can be deleted at any time — for a stable version, use a commit-pinned
  URL (`.../raw/<commit-sha>/ui_test.lua`) or make the repo public and pin to a
  commit there (`https://raw.githubusercontent.com/vornecc-pixel/NHAC-V2---SOURCE-CODE-SKID/81c52d3.../ui_test.lua`).

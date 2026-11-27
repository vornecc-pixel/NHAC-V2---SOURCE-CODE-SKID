# Loadstrings

Repo: `vornecc-pixel/NHAC-V2---SOURCE-CODE-SKID`
Branch with these files: `arena/54e891b6-nhac-v2-source-code-skid`

> **The repo is currently PRIVATE.** A Roblox executor fetches raw files
> anonymously, so `raw.githubusercontent.com` returns **404** for a private
> repo — the loadstrings below only work after the repo is public
> (GitHub → Settings → General → Danger zone → Change visibility → Public),
> or after the files are mirrored somewhere public (gist, jsDelivr, your own
> host). See "If the repo stays private" at the bottom.

---

## 1. Full UI + self-test  (`ui_test.lua`)

Self-contained: library + VORNECC redesign + 9 tabs of controls + 31 automated checks.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/vornecc-pixel/NHAC-V2---SOURCE-CODE-SKID/arena/54e891b6-nhac-v2-source-code-skid/ui_test.lua"))()
```

## 2. Just the redesigned UI, no tests  (`gamesense.txt`)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/vornecc-pixel/NHAC-V2---SOURCE-CODE-SKID/arena/54e891b6-nhac-v2-source-code-skid/gamesense.txt"))()
```

## 3. Test harness only  (`ui_test_harness.lua`)

For appending under a library you already loaded — **not** standalone.
It needs `Library` to already exist in the executor environment.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/vornecc-pixel/NHAC-V2---SOURCE-CODE-SKID/arena/54e891b6-nhac-v2-source-code-skid/ui_test_harness.lua"))()
```

---

## Safer loader (survives HttpGet / loadstring quirks)

Most executors provide `loadstring`; a few only expose `load`. This version uses
whichever exists and tells you what failed instead of dying silently:

```lua
local URL = "https://raw.githubusercontent.com/vornecc-pixel/NHAC-V2---SOURCE-CODE-SKID/arena/54e891b6-nhac-v2-source-code-skid/ui_test.lua"

local Ok, Source = pcall(function()
    return game:HttpGet(URL, true)
end)

if not Ok or type(Source) ~= "string" or #Source < 1000 then
    warn("[VORNECC] download failed (private repo? blocked host?) -> " .. tostring(Source))
    return
end

local Chunk, Err = (loadstring or load)(Source, "VORNECC_UI")

if not Chunk then
    warn("[VORNECC] compile failed -> " .. tostring(Err))
    return
end

Chunk()
```

## Pinned to an exact commit (immutable URL)

`ui_test.lua` at commit `106cc784070183a4896a4824f3ba103779265d31`:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/vornecc-pixel/NHAC-V2---SOURCE-CODE-SKID/106cc784070183a4896a4824f3ba103779265d31/ui_test.lua"))()
```

Once this branch is merged into `main`, `main` becomes the stable path —
swap `arena/54e891b6-nhac-v2-source-code-skid` for `main` in any URL above.

---

## If the repo stays private

Pick one:

1. **Make it public** (simplest — the branch URL above then just works).
2. **Public gist** — create one with the file contents and use its raw URL:
   `loadstring(game:HttpGet("https://gist.githubusercontent.com/<user>/<gist-id>/raw/ui_test.lua"))()`
3. **jsDelivr mirror** (public repos only, CDN in front of GitHub):
   `https://cdn.jsdelivr.net/gh/vornecc-pixel/NHAC-V2---SOURCE-CODE-SKID@arena/54e891b6-nhac-v2-source-code-skid/ui_test.lua`
4. **No HTTP at all** — drop `ui_test.lua` into the executor's workspace folder
   and run it locally:

   ```lua
   loadstring(readfile("ui_test.lua"))()
   ```

   (`readfile` is available in most executors; some need the file inside the
   executor's `workspace` folder specifically.)
5. **Copy-paste** `ui_test.lua` straight into the executor's editor and hit run —
   no network dependency at all.

Never put a GitHub personal access token inside a loadstring: anything you run
in an executor can read it.

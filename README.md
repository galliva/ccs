# ccs — Claude Code Sessions

A terminal session browser for [Claude Code](https://docs.anthropic.com/en/docs/claude-code),
in the spirit of the sessions view of the Claude desktop app: one list for every
project, pinned sessions on top, rename, search, preview, resume. It runs *outside*
Claude Code and launches `claude --resume` for you, from the right project directory.

```
▶ ★    today 09:31    my-webapp          │ Add rate limiting to the API
  ★    Fri 18:02      dotfiles           │ Zsh prompt cleanup
   ●   today 09:24    my-webapp          │ Flaky integration test on CI
     ◆ yesterday 22:10 scratch           │ explain this stack trace
```

Single file: bash + embedded Python 3. Dependencies: `fzf` ≥ 0.58, `python3`, `claude`.
macOS first (Finder, clipboard), should work on Linux with `xdg-open` / `xclip`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/galliva/ccs/main/install.sh | sh
```

Installs `ccs` into `~/.local/bin` (override with `CCS_INSTALL_DIR`). From a clone,
`./install.sh` symlinks the checkout instead, so `git pull` updates it.
`./install.sh --uninstall` removes it.

```sh
brew install fzf        # if you do not have it yet
```

## Keys

| Key | Action |
|-----|--------|
| `Enter` | resume the session (`claude --resume <id>`, run from its project directory); a conversation still running in the background is opened with `claude attach`, which makes no copy |
| `f` | resume as a fork (`--fork-session`: new id, the original stays untouched) |
| `h` / `t` | inside [herdr](https://herdr.dev): resume in a new pane split to the right / in a new tab |
| `r` | rename (stored exactly like `/rename`, so Claude's own picker shows it too) |
| `p` | pin / unpin (pinned sessions stay on top, alphabetically) |
| `x` | move to the trash (`ccs trash`, `ccs restore <id>`) |
| `e` | export the conversation to Markdown in `~/Downloads` |
| `y` | copy `cd <project> && claude --resume <id>` to the clipboard |
| `o` | open the project directory in Finder |
| `Space` | select several sessions; `p` and `x` act on all of them |
| `/` | search in the list (`Esc` back to navigation, the filter stays) |
| `ctrl-f` | text filter: only sessions whose prompts or title contain all the words (bounded: the first 1000 prompts, 500 characters each) |
| `s` | cycle sort: date → name → project |
| `ctrl-p` | cycle filter: all → pinned → open now → this directory |
| `ctrl-a` | show / hide empty sessions |
| `ctrl-v` | show / hide forks and daemon worker copies of a conversation (folded by default, `⑂N` on the row kept) |
| `ctrl-x` | prune: trash sessions older than 30 days with at most 2 prompts (asks first) |
| `j` `k` `g` `G` | down, up, first, last |
| `Tab` | show / hide the preview pane |
| `?` | help in the preview pane |
| `ctrl-r` | rebuild the index from disk |
| `q` / `Esc` | quit |

Markers: `★` pinned, `●` open right now in another terminal, `◆` started in the
current directory, `⑂N` N transcripts belong to this conversation (forks made with
`--fork-session`, and the copies the Claude Code daemon runs for a session); only the
newest one is listed, `ctrl-v` shows them all and the preview explains who is who. Titles: white = renamed by you, cyan = Claude's automatic title,
dim = first prompt. Every project gets its own stable color.

The preview shows id, project, branch, model, Claude version, number of prompts,
dates, size, the first prompts, the last prompt and the last reply.

## Command line

```
ccs                       open the list
ccs <text>                open the list already filtered
ccs -g <words>            open the list with the text filter set
ccs -a                    start with empty sessions visible
ccs -- <arg…>             extra arguments for claude on resume (ccs -- --model opus)

ccs resume|fork <id> [-- arg…]      resume directly (a unique prefix of the id is enough)
ccs herdr <id> [--tab]              resume in a new herdr pane (or tab)
ccs rename <id> [new name]
ccs pin <id>…
ccs delete <id>… | trash | restore <id>
ccs prune [--days N] [--max N] [--yes]
ccs dedupe [--forks N] [--yes]      trash copies of a conversation with no message of their own (forks with ≤ N own too)
ccs export <id> [file]
ccs grep <words>                    print the sessions whose prompts, title or path contain the words
ccs stats                           sessions and size per project
ccs list | preview <id> | reindex | help
```

## How it works

Claude Code keeps one JSONL transcript per session under
`~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`. `ccs` indexes them
(metadata from the first entry, the user prompts for the text filter, the
last title, the model) and caches the result in `~/.cache/ccs/index.json`, keyed by
file mtime and size. The first run over a few hundred sessions takes about a
second, later runs are instant.

Own files are created private (0700 directories, 0600 files), since the index holds
excerpts of your prompts.

**Rename** appends a `custom-title` entry to the transcript and writes the
`custom-title.json` sidecar, which is what `/rename` does, so the name shows up in
`claude --resume` as well. **Open now** comes from the registry Claude itself
maintains in `~/.claude/sessions/`. **Trash** moves the transcript and its sidecar
directory to `~/.local/share/ccs/trash/`, keeping the project layout, so a restore puts
everything back.

Note that Claude Code deletes transcripts older than `cleanupPeriodDays`
(default 30) from `~/.claude/settings.json`. Raise it if you want ccs to show more
history:

```json
{ "cleanupPeriodDays": 365 }
```

## Files and environment

| | |
|-|-|
| `~/.config/ccs/pins` | pinned session ids |
| `~/.config/ccs/state.json` | sort, filter, text filter |
| `~/.cache/ccs/index.json` | index cache (safe to delete) |
| `~/.local/share/ccs/trash/` | trashed sessions (never overwritten: a second deletion of the same id sets the first aside) |
| `CCS_CLAUDE_DIR` | Claude Code directory (default `~/.claude`) |
| `CCS_CLAUDE_BIN` | claude binary (default: the one in `PATH`) |
| `CCS_CLAUDE_ARGS` | arguments always appended to `claude` on resume (space-separated, no quoting) |

## License

MIT

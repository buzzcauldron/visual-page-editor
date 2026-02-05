# Keyboard Shortcuts

**Mod** = `Ctrl` on Windows/Linux, `Cmd` on macOS.

## Application (desktop / NW.js)

| Shortcut | Action |
|----------|--------|
| `Mod + O` | Open file |
| `Mod + S` | Save file |
| `Mod + Shift + S` | Save As |
| `Mod + P` | Print |
| `Mod + Q` / `Mod + W` | Quit / close window |
| `Mod + N` | New window |
| `Mod + ?` / `Mod + Shift + /` | Open keyboard shortcuts reference |
| `Mod + Shift + I` (Win/Linux) / `Mod + Option + I` (macOS) | Toggle DevTools |
| `Mod + Option + R` (macOS) | Reload ignoring cache |
| `Mod + Shift + R` | Reload (prompt if unsaved) |

## Document navigation

| Shortcut | Action |
|----------|--------|
| `Page Down` / `Shift + Page Down` | Next page / +10 pages |
| `Page Up` / `Shift + Page Up` | Previous page / −10 pages |
| `Left` / `Up` | Previous page |
| `Right` / `Down` | Next page |
| `Enter` (in page number field) | Go to entered page |

## View & zoom

| Shortcut | Action |
|----------|--------|
| `Mod + 0` / `Alt + 0` | Fit page to view |
| `Mod + Shift + W` / `Alt + Shift + W` | Fit width |
| `Mod + Shift + H` / `Alt + Shift + H` | Fit height |
| `Mod + =` / `Alt + =` | Zoom in |
| `Mod + -` / `Alt + -` | Zoom out |
| `Mod + 1` | Zoom to page |
| `Mod + 2` | Zoom to selected element |
| `Mod + Page Down` | Scale font down |
| `Mod + Page Up` | Scale font up |
| `Mod + Shift + Page Down` | Scale font down (alternate) |
| `Mod + Shift + Page Up` | Scale font up (alternate) |
| `Mod + Right` / `Alt + Right` | Pan right / table: next column |
| `Mod + Left` / `Alt + Left` | Pan left / table: previous column |
| `Mod + Up` / `Alt + Up` | Pan up / table: previous row |
| `Mod + Down` / `Alt + Down` | Pan down / table: next row |

## Edit modes (element type & tool)

| Shortcut | Action |
|----------|--------|
| `Mod + ,` | Next element type (mode1: Page → Region → Line → …) |
| `Mod + Shift + ,` | Previous element type |
| `Mod + .` | Next tool (mode2: Select → Baseline → Coords → …) |
| `Mod + Shift + .` | Previous tool |
| `c` | Create mode |
| `b` | Baseline mode |
| `m` | Baseline type: Margin (set preference + convert selected line(s)) |
| `d` | Baseline type: Default (set preference + convert selected line(s)) |

## Selection & editing

| Shortcut | Action |
|----------|--------|
| `Tab` | Next editable element |
| `Shift + Tab` | Previous editable element |
| `Ctrl + Tab` | Next drag point |
| `Ctrl + Shift + Tab` | Previous drag point |
| `Esc` | Deselect / close modal / close drawer |
| `Mod + Z` | Undo |
| `Mod + Y` | Redo |
| `Mod + E` | Open property modal (selected element) |
| `Delete` / `Backspace` | Delete (context-dependent) |
| `Mod + Delete` / `Mod + Backspace` | Delete (alternate) |
| `Mod + R` | Toggle protection |
| `Mod + G` | Gamma filter (cycle) |
| `Mod + I` | Invalid text (mark) / Show only image |
| `Mod + H` | Highlight editables |
| `Mod + Shift + H` | Unhighlight editables |
| `Mod + F` | Focus filter field |
| `Mod + Shift + F` | Clear filter |
| `Mod + Enter` | Toggle drawer (sidebar) |
| `Alt + A` | Add (in create mode) |

## Baseline / coords (points)

| Shortcut | Action |
|----------|--------|
| `-` then `.` | Remove poly point |
| `+` then `.` | Add poly point |

## Table mode

| Shortcut | Action |
|----------|--------|
| `Alt + Right` | Next column |
| `Alt + Left` | Previous column |
| `Alt + Up` | Previous row |
| `Alt + Down` | Next row |
| `+` then `C` | Add column |
| `+` then `R` | Add row |
| `-` then `C` | Delete column |
| `-` then `R` | Delete row |

## Web app

Same as above where applicable; additionally:

| Shortcut | Action |
|----------|--------|
| `Mod + S` / `Alt + S` | Save file |

## Notes

- Inputs and dropdowns (e.g. page number, filter, baseline type) receive key events when focused; shortcuts (including single keys `c`/`b`/`m`/`d`) are ignored there so you can type normally.
- **Edit modes** tooltip in the drawer: use `Mod + ,` / `Mod + .` (and Shift for reverse) to cycle element type and tool.

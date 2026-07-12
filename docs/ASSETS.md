# Asset Placement Guide

Place the following files in `docs/` for the README to render correctly:

```
docs/
├── logo.svg              # Project logo (light theme, 520×120 recommended)
├── logo-dark.svg         # Project logo (dark theme variant)
├── demo.gif              # Full demo recording: audit → dashboard → fix
└── screenshots/          # Optional: comparison screenshots
    ├── before-audit.png
    ├── after-fixes.png
    └── dashboard.png
```

## Logo Requirements

- **Format:** SVG (preferred) or PNG with transparent background
- **Dimensions:** 520×120 px (2:1 aspect ratio)
- **Dark variant:** white/light text on transparent background
- **Light variant:** dark text on transparent background
- **Tool:** Use [Excalidraw](https://excalidraw.com/) or Figma to create

## Demo GIF Requirements

- **Content:** Show the full end-to-end flow:
  1. Run `/perf analyze https://example.com`
  2. Terminal output scrolls through SCAN → ANALYZE → SCORE → REPORT
  3. Open `dashboard.html` — score ring animates, issues list populates
  4. Scroll through a P0 issue → copy the fix code → apply it
- **Length:** 15–30 seconds
- **Dimensions:** 800×500 px
- **Format:** GIF or WebM (GitHub supports both)
- **Tool:** [ScreenToGif](https://www.screentogif.com/) (Windows) or [Kap](https://getkap.co/) (macOS)

## Screenshots (Optional)

| Screenshot | Content |
|-----------|---------|
| `before-audit.png` | Lighthouse report showing poor scores |
| `after-fixes.png` | Lighthouse report after applying P0 fixes |
| `dashboard.png` | Full dashboard view with score ring + charts + issue list |

## Placeholder Alternative

If you don't have assets yet, remove or comment out the `<img>` tags in README.md:

```html
<!-- <img src="docs/demo.gif" alt="demo" width="800"> -->
```

The README will still render fine without images — the text content is self-contained.

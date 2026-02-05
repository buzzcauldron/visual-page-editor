# TypeScript branch

This project can be developed with TypeScript on a dedicated branch. The setup allows gradual migration: existing `.js` files are type-checked when you run `npm run typecheck`; you can add `.ts` files and types over time.

## Quick start (TypeScript branch)

1. **Create and switch to the TypeScript branch**
   ```bash
   git checkout -b typescript
   ```

2. **Install dependencies** (includes TypeScript and `@types/jquery`)
   ```bash
   npm install
   ```

3. **Type-check the codebase** (no build step by default; existing JS stays as-is)
   ```bash
   npm run typecheck
   ```

4. **Optional: enable stricter checking**  
   Edit `tsconfig.json`: set `"strict": true` or `"checkJs": true` to start typing existing `.js` files.

## What’s included

- **tsconfig.json**  
  - `allowJs: true` – TypeScript parses your existing `.js` files.  
  - `noEmit: true` – type-check only; no compiled output (app keeps using `js/*.js`).  
  - `strict: false` – relaxed so current code passes without changes.

- **types/canvas.d.ts**  
  - Type definitions for `SvgCanvas` and `PageCanvas` APIs.  
  - Augments `Window` with `pageCanvas`, `PageCanvas`, `SvgCanvas`.  
  - Improves IDE autocomplete in `page-editor.js`, `web-app.js`, `nw-app.js`.

- **package.json**  
  - `typescript` and `@types/jquery` in devDependencies.  
  - Scripts: `npm run typecheck` (tsc --noEmit), `npm run ts` (tsc).

## Migrating to TypeScript gradually

1. **Rename a file**  
   `js/page-editor.js` → `js/page-editor.ts` (and fix any type errors).

2. **Or add new code in `.ts`**  
   New modules in `js/*.ts` are included; use JSDoc `@param` / `@returns` in `.js` for better inference.

3. **Emit compiled JS (optional)**  
   If you want to compile TS to JS (e.g. for production), set in `tsconfig.json`:
   - `"noEmit": false`
   - `"outDir": "dist/js"`
   Then point your HTML or build at `dist/js` instead of `js/`.

## Notes

- Minified/vendor files (`*.min.js`) are excluded from type-checking.  
- NW.js and browser globals (e.g. `window`, `localStorage`) are available via `"lib": ["DOM", ...]`.  
- For Node-only code (e.g. in `nw-app.js`), add `"@types/node"` if you need Node types.

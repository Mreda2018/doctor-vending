# Doctor Vending — Operations Console

A single-file web app (PWA) to manage inventory, refills, collections and profit
for the Doctor Vending business. Built on **Supabase** (database + login) and
deployed on **Vercel** — the same stack as your OMNIA system.

---

## 1. Create the database (Supabase)

1. Go to **supabase.com** → **New project**. Pick a name and a strong database password.
2. Open **SQL Editor → New query**, paste the whole contents of **`schema.sql`**, and press **Run**.
   This creates every table, indexes, security rules, and seeds your 3 warehouses
   (Dubai, Umm Al Quwain, Abu Dhabi) plus a starter set of categories.
3. Go to **Authentication → Users → Add user**. Enter your email and a password,
   and tick **Auto Confirm User** so you can log in immediately. This is your admin login.
4. *(Optional)* To explore with realistic sample data, open **SQL Editor** again, paste
   **`seed-demo.sql`**, and **Run**. It adds suppliers, employees, 12 products, 6 machines,
   6 months of refills and collections, a transfer, expiry alerts and waste — so every page
   is populated. It skips itself if products already exist, so it won't duplicate.
   When you're ready to go live, clear it with `truncate` (see the note at the top of that file)
   or just start a fresh Supabase project and run only `schema.sql`.

## 2. Connect the app to your database

1. In Supabase, open **Project Settings → API**.
2. Copy the **Project URL** and the **anon public** key.
3. Open **`index.html`**, and at the very top of the first `<script>` block edit the `CONFIG`:

   ```js
   const CONFIG = {
     SUPABASE_URL: "https://xxxxxxxx.supabase.co",
     SUPABASE_ANON_KEY: "eyJhbGciOi...your anon key..."
   };
   ```

   The anon key is safe to ship in the browser — your data is protected by
   Row Level Security, so nothing is readable until you sign in.

## 3. Deploy (Vercel)

Any static host works. Easiest options:

- **Drag & drop:** zip the folder and drop it on **vercel.com/new**, or use the Vercel dashboard's "deploy static folder".
- **CLI:** `npm i -g vercel` then run `vercel` inside this folder.
- **GitHub:** push the folder to a repo and import it in Vercel (framework preset: **Other**).

No build step is needed — it's plain HTML/CSS/JS.

## 4. Install on your phone (PWA)

Open the deployed URL in Chrome (Android) or Safari (iPhone) →
**Add to Home Screen**. It launches full-screen like a native app and keeps
working offline for viewing (writes need a connection).

---

## How it works

**Stock is tracked in batches.** Every purchase line becomes a batch with its own
**expiry date** and **cost price**. When you refill a machine or transfer between
warehouses, stock is pulled **earliest-expiry-first (FEFO)** automatically, and the
real cost of those exact batches is what feeds your profit numbers.

**Two ways to read profit** (both shown side by side on the Profit page):

1. **Refill profit** — stock loaded into a machine is treated as sold at its sale price,
   minus the FEFO cost of that stock. Good for a fast, per-product/per-machine read.
2. **Collections profit** — the real cash you collected from machines, minus the same
   refill cost. This is your ground-truth cash profit.

The **Gap** figure (collections − refill value) is a shrinkage check: a large or growing
gap means product is sitting unsold in machines, or there's loss/theft to look into.

**Reports** is one filterable movement ledger across purchases, refills, transfers and
waste. Filter by date range, type, location, product, category, machine, employee or
supplier — e.g. "everything employee X took from Umm Al Quwain last month" — and export to CSV.

**Deleting is safe.** Deleting a refill or transfer restores the exact batch quantities
it consumed (stored per movement). Purchases/transfers can't be deleted once their stock
has been used downstream. Catalog records (products, machines, etc.) with history can't be
hard-deleted — mark them **inactive** instead.

---

## Files

| File | What it is |
|------|------------|
| `index.html` | The entire app — UI, logic, everything. Edit `CONFIG` here. |
| `schema.sql` | Run once in Supabase to build the database. |
| `manifest.json`, `sw.js` | PWA config + offline service worker. |
| `logo.png`, `icon-*.png`, `apple-touch-icon.png` | App icons, generated from your logo. |

Your data lives in **your** Supabase project. Back it up anytime from the Supabase dashboard.

# RadioV2 — App Features

## Theme & Accent Color

- **Theme:** Dark mode (WPF-UI Fluent Dark)
- **Accent color:** Teal-blue — `#0097B2`
  - Used on: active play button, now-playing station label, selected nav item highlight, volume/progress slider thumb
  - All other colors are semantic Fluent brushes (no hardcoded values elsewhere)

---

## Page 1 — Browse

Entry point for finding stations by typing a name.

**Features:**
- Search bar at the top — filters stations in real time as the user types
- Results list shows station name, genre tag, and station logo
- Tap a station to start playing immediately
- Now-playing station is highlighted with the accent color in the list
- Favourite button on each row to save/unsave without leaving the page

---

## Page 2 — Discover

Browse all stations organised into categories and groups.

**Features:**
- 11 top-level categories (Rock & Metal, Electronic & Dance, Pop Charts & Decades, Urban & Latin, Jazz Chill & Instrumental, News Talk & Sports, Specialty & Mood, Global & Cultural, Asia Pacific & Africa, Americas, Europe)
- Each category is a horizontal scrollable carousel row
- Each group card shows the genre/country image (`Images/Groups/`) and the station count below it
- Tapping a group opens a full station list for that group
- Station list shows featured stations at the top, then all others
- Search bar filters across genres and countries
- Smooth scroll with sticky category headers

---

## Page 3 — Favourites

Personal list of saved stations.

**Features:**
- Shows all stations the user has marked as favourite, in the order they were added
- Each row has the station logo, name, and genre tag
- Play button on each row starts playback immediately
- Heart/unfavourite button to remove from the list
- Empty state message when no favourites have been saved yet
- Persisted locally — survives app restarts

---

## Mini Player (persistent bottom bar — all pages)

Always visible at the bottom of the screen while a station is playing.

**Features:**
- Station logo, name, and now-playing metadata (`Artist — Song Title`)
- Previous / Play-Pause / Next controls
- Volume slider
- Favourite toggle button
- Reconnects automatically on network drop or wake-from-sleep

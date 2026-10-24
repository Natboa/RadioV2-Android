# RadioV2
<!-- impeccable:product-schema 1 -->

## Platform
android

## Purpose and flows
Flutter internet radio app: search and recently visited stations, genre/category discovery, paginated groups, saved favourites, background live playback and media controls. Settings currently supports M3U import/export; preserve those existing capabilities.

## Confirmed constraints
Primary brand seed #E81C9B matches desktop identity. Derive accessible light and dark roles, default system appearance with runtime choice. Neutral surfaces, foreground-coloured favourite hearts, unchanged square genre artwork displayed fully. Preserve startup responsiveness, lazy lists, pagination, stable item identity, caching and appropriately sized decoding. No decorative idle motion. Reduced motion, large text, Android insets and different screen sizes are requirements. Offline stations are routine recoverable events. Android system media/notification behaviour must remain intact.

## Scope boundaries
Android app under lib/ only; radiov2_tv is a separate app and outside this redesign. No commit, push or release without a subsequent explicit request. Existing database and audio architecture remain authoritative.

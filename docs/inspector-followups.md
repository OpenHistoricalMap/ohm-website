# OHM Inspector — open follow-ups

This file tracks `inspector`-labeled issues from
<https://github.com/OpenHistoricalMap/issues> that the #1058 PR did **not**
resolve, with a brief reason for each. Read-only on the issues repo: nothing
in this list has been commented on upstream.

## Resolved by this PR

| Issue | Resolution |
|---|---|
| [#584](https://github.com/OpenHistoricalMap/issues/issues/584) — Discover Wikipedia article through Wikidata | The new pipeline drives the Wikipedia excerpt + link **solely** from the `wikidata` QID via the Wikidata sitelinks API in the user's preferred language. |
| [#747](https://github.com/OpenHistoricalMap/issues/issues/747) — `1000001 BCE` and `1000000 CE` ignored | The new server-side `DateRange` path has no special-casing of those years; helper test asserts they render. |
| [#583](https://github.com/OpenHistoricalMap/issues/issues/583) — Verify URLs are images | Server-side `ohm_inspector_image_url_safe?` accepts only known image extensions. |
| [#585](https://github.com/OpenHistoricalMap/issues/issues/585) — Whitelist image domains | Same helper enforces a project-defined `IMAGE_DOMAIN_ALLOWLIST`. **The list is currently stubbed empty** — until the OHM team agrees on which hosts are trusted, no third-party images render through the `image:N` path. The `wikimedia_commons=File:…` route is unaffected because the partial constructs the URL itself. |
| [#581](https://github.com/OpenHistoricalMap/issues/issues/581) — Wikimedia Commons images | `wikimedia_commons=File:…` is rendered via the Commons `Special:FilePath` redirector. The `Category:` form is left for a follow-up (no obvious image to embed). |
| [#1323](https://github.com/OpenHistoricalMap/issues/issues/1323) — Click `start_date`/`end_date` to jump | The `.ohm-inspector-dates` paragraph is now clickable and calls `map.timeslider.setDate(...)`. |

## Resolved by session direction (no action needed)

| Issue | Reason |
|---|---|
| [#859](https://github.com/OpenHistoricalMap/issues/issues/859) — Non-English Wikipedia article fails | The session direction was to drive the Wikipedia/Wikidata block "solely from the wikidata QID". The buggy `wikipedia` tag handling no longer exists, so this can be closed once the PR ships. |

## Deferred — needs separate effort or design input

### Chronologies (cluster)

- **[#1352](https://github.com/OpenHistoricalMap/issues/issues/1352) — Improve chronology display in the inspector.** Needs the chronology relation lookup landed first (#748). Then the inspector should fetch the parent chronology relation(s) of a feature and render members in date order, near the top of the panel.
- **[#748](https://github.com/OpenHistoricalMap/issues/issues/748) — "Followed by" via chronology relation.** Replaces the `followed_by:name` / `followed_by` tag pattern (deliberately not ported in #1058 because it's effectively unused). Implementation: query OHM API for relations where the feature is a member with role chronology, render previous/next members.
- **[#601](https://github.com/OpenHistoricalMap/issues/issues/601) — Visualize chronology on the map.** Map-layer work; out of inspector-panel scope.

### Other open issues

- **[#1334](https://github.com/OpenHistoricalMap/issues/issues/1334) — Open iD with a `source:N:tiles` URL as custom basemap.** Requires building an iD URL with the right query string for a custom raster tile layer. Worth doing but separate from the inspector refactor.
- **[#1270](https://github.com/OpenHistoricalMap/issues/issues/1270) — Inspector misses objects during their end year.** Per @1ec5's comment on the issue, this is a bug in `app/assets/javascripts/index/query.js`'s end-date comparison, not in the inspector partial. Fix belongs in a separate PR.
- **[#1058](https://github.com/OpenHistoricalMap/issues/issues/1058) — This PR.** Will be closed when merged.
- **[#552](https://github.com/OpenHistoricalMap/issues/issues/552) — Research spike: highlight features that have pictures on the map.** Research-only; no implementation expected.
- **[#351](https://github.com/OpenHistoricalMap/issues/issues/351) — Highlight features with extra info when the inspector tool is selected.** Map-layer work; same scope as #552 / #601, not the inspector panel.
- **[#322](https://github.com/OpenHistoricalMap/issues/issues/322) — Named-prefix telephone number formatting.** Lives in upstream `format_value` / `_tag.html.erb`, not the inspector partial.
- **[#750](https://github.com/OpenHistoricalMap/issues/issues/750) — IIIF image slideshow.** Significant feature; would replace SimpleLightbox with an IIIF viewer. Separate effort.
- **[#749](https://github.com/OpenHistoricalMap/issues/issues/749) — Click image → source page (license).** Conflicts with SimpleLightbox: a slide's `<a href>` is what SimpleLightbox uses for the lightbox image. Possible designs: (a) put a small "(source)" link in the slide caption; (b) configure SimpleLightbox to render a "view source" caption link in its lightbox. Pick a UX direction before implementing.
- **[#751](https://github.com/OpenHistoricalMap/issues/issues/751) — Plan for content-poor views.** Design question: when there are no images / Wikipedia / etc., should the panel show a "Add images / Add Wikipedia" call-to-action with tagging help? Awaiting a design decision.

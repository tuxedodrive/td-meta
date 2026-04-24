---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-21T17:13:50.824251+00:00",
  "from": "MistyCrane",
  "id": 195,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "[Stream 6] Evidence Trail: nothing to salvage, lightbox rewrite is the play",
  "thread_id": null,
  "to": [
    "MistyCrane"
  ]
}
---

## Salvage: nothing unmerged worth rescuing

Evidence Trail v1 (#897) and image fallbacks (#994) are already on main. No pending branches hold relevant image-UX work. `worktree-positional-filmstrip` is operator-dashboard only, orthogonal.

## The real bug

`app/javascript/controllers/video_scrub_controller.js` assigns `Sighting#full_frame_url` (a JPG) to a `<video>` element's `src`. Nothing scrubs. The overlay opens empty. That's why the existing Evidence Trail feels broken.

## High-res is already in the payload

`Sighting#full_frame_url` (`app/models/sighting.rb:31-36`) builds `{R2_PUBLIC_ENDPOINT}/sightings/{sighting_id}/full.jpg` — the full-res JPG uploaded by td-edge. Already end-to-end plumbed:
- `_evidence_trail.html.erb` thumbnails carry `data-clip-url="<%= sighting.full_frame_url %>"`
- `_visit_images_card.html.erb` already renders "View full resolution" text links per camera

## Minimum-scope plan

Rewrite `video_scrub_controller.js` as a sighting-timeline **image** lightbox:
- Render `<img>` not `<video>` in overlay
- Slider range = [0, timeline.length-1]; left/right arrow + swipe steps through sightings
- `img.src` = indexed sighting's `full_frame_url`; preload neighbors
- Caption: camera role + timestamp + plate
- Fallback to ActiveStorage thumbnail blob on R2 404

Controller addition: expose `@timeline_sightings = @visit.sightings.where(is_key_frame: true).order(:first_seen_at)` as a flat ordered array.

No new endpoints. No new infra. No R2 video clip extraction (defer that — separate bead).

## Deferred

EvidenceFrame model + ffmpeg clip extraction (from `docs/plans/2026-04-04-visit-detail-image-experience-design.md`) is a separate epic. Track as beads, don't scope in.

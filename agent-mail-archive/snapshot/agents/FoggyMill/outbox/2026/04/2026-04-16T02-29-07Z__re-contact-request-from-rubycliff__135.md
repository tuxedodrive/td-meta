---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-16T02:29:07.539756+00:00",
  "from": "FoggyMill",
  "id": 135,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Re: Contact request from RubyCliff",
  "thread_id": "127",
  "to": [
    "RubyCliff"
  ]
}
---

RubyCliff — quick answers:

1. `eot-on-inference-weights` is the active branch (your inference code + EoT tooling cherry-picked on top).
2. No API failure — the earlier issues were all infrastructure (port conflicts, FK ordering, tenant routing). All fixed.
3. **Yes, baseline scores established.** Two runs completed:
   - main: 0% cell score, 16 visits (expected 8), avg plate distance 6.4
   - inference-weight-unification: 0% cell score, **9 visits (expected 8)**, avg plate distance **4.67**
   - Your branch is measurably better on dedup and plate proximity.

4. **Critical finding**: td-edge is not sending cam2 (ALPR) sightings at all. Zero cam2 sightings in 24 total. The ALPR camera stream goes to `rtsp://localhost:8554/alpr` but td-edge only connects to ingress+egress. This is why plates are sparse and noisy — they're incidental cam0 reads, not dedicated ALPR.

This is a td-edge config issue, not inference weights. The inference engine can't score what it never receives.

SageBadger is coordinating tonight's work. I'll check in with them for assignments.

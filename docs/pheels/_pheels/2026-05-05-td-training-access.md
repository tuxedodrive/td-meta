---
layout: post
title: "TD-Training (Label Studio) Access"
date: '2026-05-05'
category: ops
tags: [tooling, label-studio, td-training, render]
llm-relevance: medium
---

# TD-Training (Label Studio) Access

## URLs

- Custom domain (canonical): https://blemish.tuxedodrive.dev
- Render-assigned URL: https://label-studio-vnfs.onrender.com
- Render dashboard: https://dashboard.render.com/web/srv-d66ktva4d50c73bs2erg

## Service Facts

- Render service: `label-studio` (id `srv-d66ktva4d50c73bs2erg`)
- Plan: Starter ($7/mo). No Render Shell, no SSH session (both Standard+).
- Image: `docker.io/heartexlabs/label-studio:latest` (running the public image directly, not a build from `td-training/deploy/label-studio/Dockerfile`)
- Last deploy: 2026-02-12 (stable, untouched since)
- Persistent disk: `label-studio-data` mounted at `/label-studio/data`, 10 GB
- Health check: `/health` (returns 200)

## Env Vars Actually Set on the Service

```
CSRF_TRUSTED_ORIGINS = https://blemish.tuxedodrive.dev,https://label-studio-vnfs.onrender.com
LABEL_STUDIO_HOST    = https://blemish.tuxedodrive.dev
LABEL_STUDIO_PASSWORD = my-first-job
```

Note: `LABEL_STUDIO_USERNAME` is NOT set. Label Studio only auto-bootstraps an admin when BOTH USERNAME and PASSWORD are set. So `my-first-job` is dead config — it was never wired into a real admin account. The actual admin must have been created via the open signup flow on first visit.

## Credentials Status (2026-05-05)

Tried logging in with `LABEL_STUDIO_PASSWORD` (`my-first-job`) against five reasonable email candidates; all failed:

- admin@tuxedodrive.com (the value `render.yaml` would have set if the blueprint had been used)
- admin@labelstud.io
- jpb@tuxedodrive.com
- jon@discovery.works
- elias@tuxedodrive.com

Conclusion: the actual admin email + password were chosen interactively at first signup and are not in repo, env vars, or auto-discoverable. Elias's account was almost certainly created from inside that admin session.

## Recovery Paths (cheapest first)

### Option A: JPB checks 1Password / personal notes

If JPB recorded the admin email + password (or Elias's) in 1Password or a sticky note, that's the fastest path. Look for entries tagged `label-studio`, `td-training`, or `blemish.tuxedodrive.dev`.

### Option B: Temporarily upgrade Render plan to access Shell

1. Render dashboard - service `label-studio` - Settings - change plan to **Standard** (~$25/mo prorated; will be a few cents for an hour).
2. Wait for redeploy (~2 min).
3. Open the **Shell** tab.
4. Run:
   ```
   label-studio reset_password --username admin@<whatever> --password <newpass>
   ```
   If the email isn't known, list users from SQLite first:
   ```
   sqlite3 /label-studio/data/label_studio.sqlite3 "select email, is_superuser from users_user;"
   ```
5. Downgrade back to Starter.

### Option C: Create a new admin via signup, manipulate SQLite

Open signup is enabled at https://blemish.tuxedodrive.dev/user/signup/. New signups are regular users (not admin) and join the existing org. To make a new signup an admin you'd need to flip `is_superuser=1` in SQLite — same Shell access requirement as Option B, so this collapses into Option B.

### Option D: Nuke and repave (last resort)

If no annotations are worth preserving (check via Option B first), set `LABEL_STUDIO_USERNAME` + a fresh `LABEL_STUDIO_PASSWORD` in env, blow away `/label-studio/data/label_studio.sqlite3`, redeploy. Cleanest but loses any existing label work.

## Recommended Next Step

Option A (JPB checks 1Password). If nothing there, Option B — the Standard upgrade for one hour costs roughly nothing and gives a real recovery surface.

## Operational Notes

- TD-Training Steward agent (see kickoff brief) should own subsequent ops: dataset upload, R2 storage wiring (currently NOT configured — `AWS_ACCESS_KEY_ID` etc. are absent from env vars), labeling progress with Elias and Em.
- Once admin is recovered, the steward should rotate the password into 1Password under `td-training / Label Studio admin` and create individual annotator accounts for Elias and Em (so their progress is attributable).
- The custom domain `blemish.tuxedodrive.dev` is the canonical URL; share that, not the `*.onrender.com` URL.

# Festival Programme Sync — Take-Home

**Role:** Senior Rails / Hotwire Developer · **Time box:** 4 hours
**Stack:** Rails 8, Hotwire, PostgreSQL, Sidekiq, Tailwind (all in Docker)

## Context

You're joining a team that maintains a film festival's public website. It's a
Rails monolith that also acts as the editorial CMS, and it pulls programming data
from an external festival-management system over an API.

That external system is the source of truth for films, venues and screenings. Our
database holds a local copy so the site renders fast and stays up under load.
Today that copy is refreshed by a nightly script a colleague wrote in a hurry, and
it's been causing problems.

**Your job is to replace it.**

## What we've given you

A working Rails 8 app with `Film`, `Venue` and `Screening` models, a mock external
API at `/mock_api` that behaves like the real one including its failure modes, an
existing `VenueSync` service and its tests, a screenings index with a filter form,
and seed data.

### Running it

Everything runs in Docker. One step:

```bash
docker compose up --build
```

That starts Postgres, Redis, the Rails web server, a Tailwind watcher and Sidekiq,
and creates/migrates/seeds the database on first boot.

- App: <http://localhost:3000>
- Sidekiq dashboard: <http://localhost:3000/sidekiq>
- Postgres is exposed on host port **5544** (non-standard, so it won't collide)

Handy commands (see the `Makefile`):

```bash
make console   # rails console inside the web container
make test      # run the RSpec suite
make sh        # a shell in the web container
```

## What we'd like you to build

1. **A programme sync.** Pull screenings from `GET /mock_api/screenings` into our
   database. It's paginated, returns nested film and venue data, and behaves like a
   real third-party API: sometimes slow, sometimes failing partway through, and its
   records change between runs.

   Running it twice must not create duplicates. Running it after upstream data
   changes must update the local copy. If the API fails partway, records already
   retrieved shouldn't be lost. It should run on a schedule as a background job, and
   we should be able to tell afterwards whether a run succeeded and what it did.

2. **A filtered screenings list.** The index at `/screenings` has a filter form that
   reloads the whole page. Make it update just the results. Filters are date, venue,
   and a text search across titles. Keep it server-rendered; we're a Hotwire shop and
   aren't looking for a client-side rendering layer.

3. **A short README.** Half a page. What you'd do differently with more time, anything
   in the existing code you'd change and why, and any assumptions you made.

## Testing the mock API

| Parameter      | Effect                                                                                                     |
| -------------- | ---------------------------------------------------------------------------------------------------------- |
| `?page=2`      | Pagination, 25 records per page                                                                            |
| `?generation=2`| The dataset after upstream changes. Screenings have moved venue, some are cancelled, a film has been retitled, two screenings are new. |
| `?fail_after=8`| Returns 8 records, then a 500                                                                              |
| `?slow=true`   | Six-second delay                                                                                           |

Sync `generation=1`, then `generation=2`, and check the database is right. Then try
`generation=1&fail_after=8` and check nothing was lost.

## What we care about

- **Correctness under failure, ahead of feature completeness.** If you run short, a
  sync that handles the edge cases and a filter that doesn't quite work beats the
  reverse.
- Tests are expected — at least for the sync and the models. Tests for the view
  layer aren't. We're looking at how you test, not just that you did, so write
  your own; the repo doesn't hand you a test plan.

## Submitting

A private git repo with your commits. Please don't squash.

## Implementation notes

The programme sync treats upstream external IDs as the identity of films, venues
and screenings. Each API page is processed by an independent Sidekiq job, and
each screening is persisted in its own transaction so a later failure does not
roll back records already committed. Unique database indexes are the final
protection against duplicates. Films and venues repeated within a page are
cached only for the lifetime of that page to avoid redundant database work.
HTTP failures are allowed to reach Sidekiq so the failed page can be retried
without rolling back pages that have already completed. Invalid individual
records are isolated, persisted as failed `SyncLog` entries and returned as
structured failures, allowing later records on the same page to continue. The
HTTP client uses a two-second connection timeout and a ten-second response
timeout, which accommodates the known six-second slow response. Connection,
timeout and server failures retry up to five times with polynomial backoff.

`sidekiq-cron` starts `ProgrammeSyncJob` at the beginning of every hour. This
coordinator creates a `SyncRun` and enqueues page 1; the first page discovers the
total page count and fans the remaining pages out to independent jobs. A partial
unique index allows only one running sync, so another scheduled invocation exits
without creating an overlapping run. Completed pages are recorded idempotently,
and exhausting transient-error retries marks the run as failed and releases the
slot for a future execution.

`SyncRun` stores the aggregate execution lifecycle and timestamps. Structured
`SyncLog` entries support job and record events, including status, action, page,
attempt, external identity, timing, errors and JSON metadata. Record events
distinguish created, updated and unchanged data; run-level helpers expose created,
updated and error counts. A run that finishes all pages with logged failures is
marked `completed_with_errors`.

The screenings index applies date, venue and title filters and eager loads films
and venues, removing the inherited N+1. Its GET form targets the results Turbo
Frame, so filtering remains server-rendered while replacing only the list. A
small Stimulus controller submits title searches after a 300 ms debounce.

The original supplied `VenueSync` matched venues by name. Since names can change
upstream, that could attempt to create a duplicate external ID instead of updating the
existing venue. I changed this inherited service to match by stable external ID
and added a regression test for upstream renames. This was kept as a focused,
documented correction rather than silently copying or broadly rewriting the
inherited implementation. Invalid venue entries are now isolated and returned as
structured failures so later entries in the same batch still run.

The brief does not define what a missing upstream screening means. It could be a
deletion, an archival event or a temporary omission. The chosen policy is to
delete local screenings that are absent upstream because this database is a
replaceable local copy of the source of truth. Reconciliation must run only after
every page completes successfully; a partial API run must never trigger deletion.
This policy should be revisited if screenings later own editorial or transactional
history that must be retained.

With more time, I would add an operational dashboard and alert delivery, define
a retention policy for sync logs, and use an upstream snapshot/version token so
concurrently processed pages are guaranteed to represent the same dataset.

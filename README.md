# Daily Commit Bot

A small, transparent GitHub Actions bot that records one entry in
[`ACTIVITY.md`](ACTIVITY.md) every day. It is inspired by
[theshteves/commit-bot](https://github.com/theshteves/commit-bot), but runs in
GitHub's cloud instead of relying on a laptop and local cron.

## What it does

- Produces **1-5 commits every day** in **America/Toronto**.
- Selects a different subset of seven irregular time slots for each date.
- Produces 4-5 commits on roughly one quarter of days.
- Commits directly to the default branch using the repository owner's
  GitHub-provided no-reply address.
- Creates an additional commit when run on demand from
  **Actions > Daily activity > Run workflow**.
- Uses the built-in `GITHUB_TOKEN`; no personal access token or repository
  secret is required.

Cron schedules themselves cannot choose a new random clock time every day, so
the workflow uses seven irregular opportunities and a date-seeded hash to pick
which ones commit. The result changes each day but remains reproducible and
guarantees at least one daily commit. Scheduled jobs can still be delayed
occasionally by GitHub Actions.

## Why the contribution is attributed to the owner

GitHub counts a commit on a profile when its author email belongs to that
account, it is in a standalone repository, and it lands on the default branch
(or `gh-pages`). The workflow builds the repository owner's ID-based no-reply
address from GitHub's workflow context, so a personal email is not published.

This setup is intended for a repository owned by a personal GitHub account. If
you transfer it to an organization, change `COMMIT_NAME` and `COMMIT_EMAIL` in
`.github/workflows/daily-activity.yml` to an email associated with the person
who should receive contribution credit.

## Security and reliability

The workflow grants only `contents: write`, the permission needed to push the
daily entries. The update script is idempotent per scheduled slot and workflow
run, so retrying a job does not create a duplicate commit.

GitHub may disable schedules in a public repository after 60 days without any
repository activity. Successful daily commits keep this repository active, but
if the workflow ever remains broken for that long, re-enable it from the
Actions tab.

## Test locally

```bash
./tests/test-update-activity.sh
```

## Change the schedule

Edit the `cron` and `timezone` values in
`.github/workflows/daily-activity.yml`. GitHub uses POSIX cron syntax.

## Stop the bot

Disable **Daily activity** in the repository's Actions tab, or remove the
`schedule` trigger from `.github/workflows/daily-activity.yml`.

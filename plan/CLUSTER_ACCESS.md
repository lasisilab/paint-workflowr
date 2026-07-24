# SEPIA — cluster access (the SSH tunnel) & Claude's rules

How Claude reaches Great Lakes, why the shared connection broke, and the **rules Claude follows** so it doesn't break again.

## What the "tunnel" is (SSH connection multiplexing)
Claude runs on Tina's laptop, in a sandbox. It cannot log in to Great Lakes itself (UMich requires a Kerberos password + Duo/Okta, which Claude must never handle). The only way Claude runs a cluster command is by **borrowing an SSH connection Tina has already authenticated** — a feature called **connection multiplexing** (`ControlMaster`):

- Tina's `~/.ssh/config` has, for `Host greatlakes`: `ControlMaster auto` + a `ControlPath` (a socket file, e.g. `~/.ssh/sockets/…`) + `ControlPersist`.
- The **first** `ssh greatlakes` authenticates once (password + Duo) and leaves an authenticated **master** connection running in the background; the socket file is its "door."
- **Every later** `ssh greatlakes` on the laptop — Tina's *and Claude's* — walks through that door and **reuses the master**: no re-authentication, no Duo. That is how Claude's commands run silently.

Two consequences that matter:
1. **The master is pinned to one login node.** All multiplexed traffic goes to whichever node the master first authenticated to.
2. **If the master dies but its socket file lingers,** new `ssh greatlakes` attempts keep diving into the dead tunnel and bounce straight back (`Shared connection … closed`) — and can't escape to a healthy node.

## Why it broke (2026-07-23)
- The pinned login node (gl-login1) got **overloaded** and started refusing/killing sessions ("Unable to create login session — heavy load").
- The stale socket lingered, so both Tina's and Claude's `ssh greatlakes` kept reusing a dead/overloaded master and closing instantly.
- **Claude made it worse:** it fired *many* rapid `ssh greatlakes` commands (piling channels onto the master + adding load), ran non-trivial work on the login node (conda, scans over ~1 GB files), which likely tripped a **connection-rate limit** — which is when the Duo pushes started.
- Fix was to kill the master (`ssh -O exit greatlakes`) and reconnect cleanly.

## Robust config (prevents silent death)
Add these to the `Host greatlakes` block in `~/.ssh/config` (keeps the master alive across blips, cleans up, detects dead links):
```
Host greatlakes
    HostName greatlakes.arc-ts.umich.edu
    User tlasisi
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 30m
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
```
(`mkdir -p ~/.ssh/sockets` once.) `ServerAliveInterval/CountMax` make SSH notice a dead master within ~3 min instead of hanging; `ControlPersist 30m` keeps the master for reuse but not forever.

## Re-establishing the tunnel
1. (Optional but recommended) add the config above; `mkdir -p ~/.ssh/sockets`.
2. Tina reconnects with **plain** `ssh greatlakes` (no `ControlPath=none`) → creates the master (one Duo). Keep the terminal open.
3. Tina tells Claude "connected." Claude runs `ssh -O check greatlakes` (local socket check, no auth) to confirm the master, then one tiny command to verify — and follows the rules below.

## Claude's rules for cluster access (binding)
1. **Never handle credentials.** Claude never types the password or Duo/Okta. If a command would trigger authentication (no master present), Claude STOPS and asks Tina to (re)connect — it never initiates a login itself.
2. **Check before use.** Start any cluster work with `ssh -O check greatlakes`. If no master, stop and ask Tina to reconnect (don't run `ssh` that would auth).
3. **One connection, batched.** Never fire many separate `ssh` calls. Put multiple commands in ONE invocation (`ssh greatlakes 'bash -s' < script`). **Serialize — never run cluster commands in parallel.**
4. **Login node = orchestration only.** Only tiny, read-only commands there (`ls`, `wc`, `grep -m1`, submit `sbatch`, `tail` a log). **All real work — conda solves, scans over large files, genotype calling, ANGSD, mapDamage, downloads of many files — goes through `sbatch`** on compute nodes.
5. **Keep commands short (< ~30 s).** Anything longer → `sbatch`.
6. **Text-only.** Never `cat`/`head`/`less` a binary (`.bam`/`.bcf`/`.vcf.gz`); use `samtools view -H` / `bcftools view -H` / counts. (Dumping binaries once scrambled the terminal.)
7. **No auto-retry.** On any `connection closed` / timeout / auth prompt, STOP and report — never loop retries (that worsens load and triggers Duo).
8. **Read-mostly; confirm writes.** Output goes to a dedicated `rebuild/` workspace; never overwrite existing data without confirming.
9. **Back off under load.** If the cluster is slow/refusing, pause — don't hammer.
10. **Prefer the log.** After an `sbatch` job, read its log file rather than re-running things interactively.

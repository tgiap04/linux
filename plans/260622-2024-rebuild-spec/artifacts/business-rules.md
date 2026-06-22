# Business Rules

**Project**: KMA OS / sys-cli / package-hiding
**Generated**: 2026-06-22

## Authentication

- **BR001**: The web dashboard issues a one-time sudo token (30-second TTL) after verifying the sudo password via `/api/sudo/verify`. The token is required for SSE streams (`/api/packages/update/stream`) because EventSource cannot set custom headers.
- **BR002**: All write and administrative API routes require the `X-Sudo-Password` header on every request. The one-time token supplements (not replaces) the header for SSE.

## Firewall

- **BR003**: The `enabled` sysfs attribute acts as a master gate — when set to `0`, no packet filtering occurs regardless of `drop_icmp` or `reject_ports` values.
- **BR004**: `drop_icmp` operates independently of `reject_ports`. Setting `drop_icmp=1` drops all ICMP regardless of port rules.
- **BR005**: Port values in `reject_ports` must each be in the range 1–65535. The API validates each port before writing to sysfs.

## VFS Guard

- **BR006**: Protected paths are indexed by inode number and device ID at the time `add_path` is written to sysfs. File renames do not bypass protection because the inode hash remains valid.
- **BR007**: The VFS guard blocks `unlink`, `rmdir`, and `rename` on any inode in the protected set. Root user is also subject to this restriction (LSM hooks run before DAC checks are bypassed).

## Cron

- **BR008**: Adding a cron job is idempotent — if the full crontab entry string already exists, the API returns `{ok: true, added: false, reason: "already exists"}` without duplicating the entry.
- **BR009**: Cron job indices are 1-based and are recomputed on each `crontab -l` read. An index becomes invalid if another job is deleted between list and delete operations.

## Covert Channel

- **BR010**: The TCP covert channel embeds one byte per packet in the low 8 bits of the TCP Initial Sequence Number (ISN). IP and TCP checksums are recalculated after embedding.
- **BR011**: The UDP covert channel embeds one byte per packet in the low 8 bits of the IP Identification field. Only the IP checksum is recalculated; UDP checksum is unaffected.
- **BR012**: The framing state machine manages multi-byte message transmission. A message is split across multiple packets; the receiver reassembles bytes in order using the same framing protocol.

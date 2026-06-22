# API Map

**Project**: sys-cli web dashboard
**Generated**: 2026-06-22

## Endpoints by Domain

### Auth

| Method | Path | Handler BL### | Auth |
|--------|------|---------------|------|
| POST | /api/sudo/verify | BL015 | None (issues one-time token) |

### Files

| Method | Path | Handler BL### | Auth |
|--------|------|---------------|------|
| GET | /api/files/tree | BL020 | None |
| GET | /api/files/large | BL020 | None |
| POST | /api/files/delete | BL020 | None |
| POST | /api/files/delete-path | BL020 | X-Sudo-Password |
| POST | /api/files/rename | BL020 | X-Sudo-Password |
| POST | /api/files/create | BL020 | X-Sudo-Password |

### Cron

| Method | Path | Handler BL### | Auth |
|--------|------|---------------|------|
| GET | /api/cron/now | BL019 | None |
| GET | /api/cron/list | BL019 | None |
| POST | /api/cron/add | BL019 | None |
| DELETE | /api/cron/:index | BL019 | None |

### Time

| Method | Path | Handler BL### | Auth |
|--------|------|---------------|------|
| GET | /api/time/status | BL022 | None |
| GET | /api/time/timezones | BL022 | None |
| POST | /api/time/timezone | BL022 | X-Sudo-Password |
| POST | /api/time/ntp | BL022 | X-Sudo-Password |
| GET | /api/time/ntp-status | BL022 | None |

### Packages

| Method | Path | Handler BL### | Auth |
|--------|------|---------------|------|
| GET | /api/packages/detect | BL021 | None |
| GET | /api/packages/list | BL021 | None |
| POST | /api/packages/install | BL021 | X-Sudo-Password |
| POST | /api/packages/remove | BL021 | X-Sudo-Password |
| GET | /api/packages/update/stream | BL021 | X-Sudo-Password + _sudo_token |
| POST | /api/packages/autoremove | BL021 | X-Sudo-Password |

### Processes

| Method | Path | Handler BL### | Auth |
|--------|------|---------------|------|
| GET | /api/processes/list | BL017 | None |
| POST | /api/processes/kill | BL017 | X-Sudo-Password |
| GET | /api/processes/port/:port | BL017 | None |

### Network

| Method | Path | Handler BL### | Auth |
|--------|------|---------------|------|
| GET | /api/network/sockets | BL018 | None |
| GET | /api/network/interfaces | BL018 | None |
| GET | /api/network/routes | BL018 | None |
| POST | /api/network/ping | BL018 | None |
| POST | /api/network/dns | BL018 | None |

### Firewall

| Method | Path | Handler BL### | Auth |
|--------|------|---------------|------|
| GET | /api/firewall/status | BL016, BL013 | X-Sudo-Password |
| GET | /api/firewall/logs | BL016, BL013 | X-Sudo-Password |
| POST | /api/firewall/toggle | BL016, BL013 | X-Sudo-Password |
| POST | /api/firewall/ports | BL016, BL013 | X-Sudo-Password |
| POST | /api/firewall/ports/clear | BL016, BL013 | X-Sudo-Password |

## Background Jobs

_(none found)_

## Webhooks

_(none found)_

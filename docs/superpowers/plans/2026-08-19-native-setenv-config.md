# Native SetEnv Configuration Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow `SetEnv` in `~/.assh.yml`, including under `defaults`, to be parsed, inherited by hosts, and emitted by `assh config build` as an OpenSSH `SetEnv` directive.

**Architecture:** Extend `pkg/config.Host` with the same `composeyaml.Stringorslice` representation used by `SendEnv`. Thread the field through option listing, default application/environment expansion, and SSH config generation so the native build path handles it without hooks. Keep hook execution and command behavior unchanged, and verify the full path with focused model and configuration tests.

**Tech Stack:** Go 1.14, `flexyaml`, `composeyaml.Stringorslice`, GoConvey, `gofmt`, `go test`.

---

## Implementation Tasks

- [x] Add failing coverage for native `SetEnv` support.
  - In `pkg/config/host_test.go`, extend the default-application coverage to assert that a host with no explicit `SetEnv` receives the defaults value.
  - Add focused assertions that `Host.Options()` exposes each `SetEnv` entry and that `Host.WriteSSHConfigTo` emits `SetEnv TERM=xterm-256color`.
  - In `pkg/config/config_test.go`, load YAML containing `defaults.SetEnv`, resolve a host, assert the inherited model value, and assert that `Config.WriteSSHConfigTo` contains the generated global `Host *` directive.
  - Run `go test ./pkg/config`; these tests should fail before the model/generator implementation exists.

- [x] Add `SetEnv` to the configuration model and generation pipeline.
  - In `pkg/config/host.go`, add `SetEnv composeyaml.Stringorslice` beside `SendEnv` with YAML key `setenv` and JSON key `SetEnv`.
  - Add the field to `Host.Options()` using one `Option{Name: "SetEnv", Value: entry}` per entry.
  - Add the same empty-host fallback and `utils.ExpandSliceField` call used by `SendEnv` in `Host.ApplyDefaults`.
  - Emit one `SetEnv <value>` line per entry from `Host.WriteSSHConfigTo`.
  - Do not modify hook execution or `assh config build`; the existing build path will consume the modeled field.

- [x] Document the concise user-facing configuration.
  - In the main configuration example in `README.md`, show:
    ```yaml
    defaults:
      SetEnv:
      - TERM=xterm-256color
    ```
  - State that this is written into generated `~/.ssh/config` by the normal `assh config build` flow.

- [x] Format, test, and self-review.
  - Run `gofmt` on the changed Go files.
  - Run `go test ./pkg/config` and then `go test ./...`.
  - Review the diff to confirm the change is limited to the model, generation, tests, and documentation; verify no hook behavior or generated-file post-processing was introduced.

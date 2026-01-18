# DEFENCE

DOS-era copy-protection toolkit (Turbo Pascal + x86 assembly) that binds a
target EXE/COM to a machine via a ROM-derived key. It ships a Turbo Vision
front-end plus small DOS utilities that perform unpacking, encryption, and
stub injection. This repo is primarily historical/archival and targets 16-bit
DOS environments.

## Components

- `DEFENCE.PAS` - Turbo Vision UI that orchestrates the protection pipeline.
- `ENCRYPT.ASM` -> `encrypt.com` - encrypts the target using a ROM-derived key.
- `TAIL.ASM` / `tail.org` -> `tail.com` - runtime stub appended to the target.
- `COM2END.ASM` -> `com2end.com` - appends a COM stub to an EXE/COM.
- `DCRYPT.ASM` -> `dcrypt.com` - post-processing step used in the pipeline.
- `TRACE.ASM` -> `trace.com` - optional patcher for `CALL offset16` sequences.
- `CHECK.ASM` -> `check.com` - sanity check for EXE header/size.
- Turbo Vision units: `dialogs.pas`, `views.pas`, `stddlg.pas`, etc.

## Build

You need a DOS environment (or DOSBox) with Turbo Pascal 7.0 and
Turbo Assembler/TLINK.

Example (DOS):

```bat
tasm encrypt.asm
tlink /t encrypt.obj
```

`M.BAT` is a local helper script for TASM/TLINK; adjust paths to your setup.

## Usage

The GUI (`DEFENCE.EXE`) drives the same pipeline as `MAKE.BAT`. The batch
script can be used directly:

```bat
MAKE.BAT <target.exe>
```

Pipeline (simplified):
1. Backup the target and copy it to `asd.exe`.
2. Unpack with `unp` (external; not included).
3. Prepare the tail stub (`tail.org` -> `tail.com`).
4. Optionally patch calls with `trace.com`.
5. Encrypt with `encrypt.com`.
6. Append the stub with `com2end`.
7. Finalize with `dcrypt.com` and replace the original file.

## Notes

- 16-bit DOS only. The tooling accesses ROM/BIOS data directly and will not
  run on modern OSes without emulation.
- `unp` is referenced but not included in this repo.
- MIT License. See `LICENSE`.

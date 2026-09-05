# Retain the server CPU-compatible login shell after retiring Hermes.
{
  lib,
  pkgs,
  ...
}: {
  # rush 0.1.0 SIGILLs on this host's CPU (store-path crash reproduced
  # directly, exit 132, 2026-08-25) — with rush as login shell, every SSH
  # session died at exec and the gateway's ssh workspace was unreachable.
  # bashInteractive until rush is rebuilt for this host or swapped out.
  # common.nix keeps rush as an mkDefault so other hosts are unaffected.
  users.users.y0usaf.shell = lib.mkForce "${pkgs.bashInteractive}/bin/bash";
}

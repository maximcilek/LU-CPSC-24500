#!/usr/bin/env bash
set -euo pipefail

PRIMARY_CTX="$(mktemp /run/step-primary.XXXXXX.ctx)"
SEALED_CTX="$(mktemp /run/step-sealed.XXXXXX.ctx)"

tpm2_startauthsession --policy-session -S "$SEALED_CTX"

tpm2_pcrread sha256:0,1,2,3 \
  > pcrs.bin

tpm2_policypcr -S "$SEALED_CTX" -l sha256:0,1,2,3

tpm2_unseal \
  -c 0x81010001 \
  -S "$SEALED_CTX"

tpm2_flushcontext "$SEALED_CTX"
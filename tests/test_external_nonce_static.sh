#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
main_cpp="$repo_root/src/main.cpp"
header="$repo_root/src/futurerestore.hpp"
impl="$repo_root/src/futurerestore.cpp"

require_contains() {
    local file="$1"
    local needle="$2"
    local message="$3"
    if ! grep -Fq -- "$needle" "$file"; then
        echo "FAIL: $message"
        echo "missing: $needle"
        exit 1
    fi
}

require_order() {
    local file="$1"
    local first="$2"
    local second="$3"
    local message="$4"
    local first_line
    local second_line
    first_line="$(grep -nF -- "$first" "$file" | head -n1 | cut -d: -f1 || true)"
    second_line="$(grep -nF -- "$second" "$file" | head -n1 | cut -d: -f1 || true)"
    if [ -z "$first_line" ] || [ -z "$second_line" ] || [ "$first_line" -ge "$second_line" ]; then
        echo "FAIL: $message"
        exit 1
    fi
}

require_contains "$main_cpp" '"external-nonce"' "long option --external-nonce must be registered"
require_contains "$main_cpp" "FLAG_EXTERNAL_NONCE" "main.cpp must define an external nonce flag"
require_contains "$main_cpp" "--external-nonce requires --use-pwndfu" "external nonce must be limited to pwnDFU"
require_contains "$main_cpp" "client.useExternalNonce();" "main.cpp must pass external nonce mode to futurerestore"
require_contains "$header" "bool _externalNonce" "futurerestore must track external nonce mode"
require_contains "$header" "void useExternalNonce()" "futurerestore must expose an external nonce setter"
require_contains "$impl" "External nonce mode enabled" "futurerestore must log the external nonce path"
require_contains "$impl" "img4tool::getValFromIM4M({_im4ms[0].first, _im4ms[0].second}, 'BNCH')" "external nonce path must read BNCH from the APTicket IM4M"
require_contains "$impl" "skip internal ApNonce hax" "external nonce path must skip futurerestore nonce hax"
require_order "$impl" "External nonce mode enabled" "recovery_enter_restore" "external nonce must be established before entering restore mode"

echo "PASS: external nonce static checks"

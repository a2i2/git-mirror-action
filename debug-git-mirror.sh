#!/bin/sh

set -e

SOURCE_REPO=$1
DESTINATION_REPO=$2
SOURCE_DIR=$(basename "$SOURCE_REPO")
DRY_RUN=$3

GIT_SSH_COMMAND="ssh -v"

echo "=== DEBUG: Initial Environment ==="
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "LD_PRELOAD: $LD_PRELOAD"
echo "Git SSL/crypto library dependencies:"
ldd /usr/bin/git | grep -E "(ssl|crypto)" || echo "No SSL/crypto deps found"
echo "libcurl SSL/crypto dependencies:"
ldd /usr/lib/libcurl.so.4 | grep -E "(ssl|crypto)" || echo "No SSL/crypto deps found"
echo "OpenSSL libraries in container:"
find /usr -name "*ssl*" -type f 2>/dev/null | head -5
echo "=================================="

echo "SOURCE=$SOURCE_REPO"
echo "DESTINATION=$DESTINATION_REPO"
echo "DRY RUN=$DRY_RUN"

echo "=== DEBUG: Before git clone ==="
echo "Testing basic git functionality:"
git --version
echo "Testing OpenSSL/SSL functionality:"
echo | openssl s_client -connect github.com:443 -quiet 2>&1 | head -3 || echo "OpenSSL test failed"
echo "==============================="

echo "=== DEBUG: git clone with tracing ==="
GIT_CURL_VERBOSE=1 GIT_TRACE=2 GIT_SSH_COMMAND="ssh -v" git clone --mirror "$SOURCE_REPO" "$SOURCE_DIR" 2>&1 | tee /tmp/git-debug.log
echo "====================================="

echo "=== DEBUG: After git clone ==="
if [ -f /tmp/git-debug.log ]; then
    echo "Checking debug log for OpenSSL errors:"
    grep -i "openssl\|ssl.*version\|mismatch" /tmp/git-debug.log || echo "No OpenSSL errors found in log"
fi
echo "==============================="

cd "$SOURCE_DIR"
git remote set-url --push origin "$DESTINATION_REPO"

echo "=== DEBUG: Before git fetch ==="
echo "About to run: git fetch -p origin"
echo "==============================="

GIT_CURL_VERBOSE=1 GIT_TRACE=2 git fetch -p origin 2>&1 | tee -a /tmp/git-debug.log

# Exclude refs created by GitHub for pull request.
git for-each-ref --format 'delete %(refname)' refs/pull | git update-ref --stdin

if [ "$DRY_RUN" = "true" ]
then
    echo "INFO: Dry Run, no data is pushed"
    echo "=== DEBUG: Before dry-run push ==="
    GIT_CURL_VERBOSE=1 GIT_TRACE=2 git push --mirror --dry-run 2>&1 | tee -a /tmp/git-debug.log
else
    echo "=== DEBUG: Before actual push ==="
    GIT_CURL_VERBOSE=1 GIT_TRACE=2 git push --mirror 2>&1 | tee -a /tmp/git-debug.log
fi

echo "=== DEBUG: Final debug log analysis ==="
if [ -f /tmp/git-debug.log ]; then
    echo "Complete git operations log:"
    cat /tmp/git-debug.log
fi
echo "======================================="

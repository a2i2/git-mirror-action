#!/bin/sh
echo "=== Container Environment ==="
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "LD_PRELOAD: $LD_PRELOAD"
ldd /usr/lib/libssl.so.3
echo "OpenSSL libraries found:"
find /usr -name "*ssl*" 2>/dev/null | head -10
echo "=========================="

# Run the original entrypoint
exec /entrypoint.sh "$@"

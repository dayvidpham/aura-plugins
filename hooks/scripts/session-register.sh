#!/usr/bin/env bash
# Called on SessionStart. Session registration moved out of the retired Python
# aura-msg path and belongs to the Pasture hook integration. Keep this hook as a
# non-blocking no-op so old hook configs do not fail user sessions.
exit 0

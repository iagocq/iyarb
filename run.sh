#!/bin/sh

qemu-system-i386 -drive file=test.img,format=raw $@ &
PID=$!

if [ -n "$TIMEOUT" ]; then
    (sleep $TIMEOUT && command kill -9 $PID 2> /dev/null && exit 10) &
else
    sleep 365d &
fi

wait $PID
CODE=$?

if ps -p $! > /dev/null; then
    # no timeout
    if [ "$CODE" = 33 -o "$CODE" = 0 ]; then
        # success exit code = 33
        exit 0
    else
        exit 1
    fi
else
    # timeout
    exit 1
fi

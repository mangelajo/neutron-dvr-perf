#!/bin/sh

CMD="ping $1 -c 2 -i 3.5"
FUNCTION="SyS_sendmsg"

cd /sys/kernel/debug/tracing

echo $FUNCTION > set_graph_function
echo > set_ftrace_filter
echo 100 > max_graph_depth
echo function_graph > current_tracer
cat /dev/null > trace
$CMD &
echo $! > set_ftrace_pid
echo 1 > tracing_on
sleep 4
echo 0 > tracing_on
cat trace


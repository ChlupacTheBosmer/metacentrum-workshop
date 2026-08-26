#!/usr/bin/env bash
#
# ============================================================
#  04_jobs/check_jobs.sh
#  Watching your jobs
# ============================================================
#
#  Four commands do almost everything. This script shows the
#  first three. The fourth deletes a job, so we only print it
#  rather than running it.
#
#      bash 04_jobs/check_jobs.sh
#
# ============================================================


echo "============================================"
echo "1. Your jobs right now"
echo "============================================"
echo ""
echo "Command:  qstat -u $USER"
echo ""

# qstat lists jobs. "-u" limits it to one user, otherwise you
# would see every job in the whole of MetaCentrum.
qstat -u "$USER"

echo ""
echo "The letter in the S column is the state:"
echo "    Q   queued, waiting for a free machine"
echo "    R   running now"
echo "    F   finished"
echo "    E   exiting, almost done"
echo ""


echo "============================================"
echo "2. Including jobs that already finished"
echo "============================================"
echo ""
echo "Command:  qstat -x -u $USER"
echo ""

# Without -x, finished jobs disappear from the list. With -x you
# can still see them for a while afterwards.
qstat -x -u "$USER"

echo ""


echo "============================================"
echo "3. Deleting a job"
echo "============================================"
echo ""
echo "If a job is wrong, or stuck, remove it:"
echo ""
echo "    qdel 23130368"
echo ""
echo "For a job array, keep the square brackets:"
echo ""
echo "    qdel '23130368[]'"
echo ""


# ============================================================
#  A WEB VERSION OF ALL THIS
#
#      https://my.metacentrum.cz
#
#  It shows your jobs, the queues, the machines, and how full
#  your storage is. Easier to read than qstat when you are
#  starting out.
#
#  There is also a tool that writes qsub commands for you:
#      https://my.metacentrum.cz/qsub-assembler
# ============================================================

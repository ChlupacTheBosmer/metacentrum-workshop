#!/usr/bin/env bash
#
# ============================================================
#  06_interactive_job/interactive.sh
#  Borrowing a machine for a while
# ============================================================
#
#  THE DIFFERENCE
#
#  A normal job runs a script and you read the output afterwards.
#  An interactive job gives you a terminal ON a compute node, and
#  you type into it yourself.
#
#  It is the right tool when you want to:
#      - try commands out before writing them into a script
#      - copy a lot of files (not allowed on the frontend)
#      - install or compile something
#      - run R by hand on something bigger than a laptop
#
#  This script does not run the job for you. It prints the command
#  and explains the parts, because you will type it by hand often.
#
#      bash 06_interactive_job/interactive.sh
#
# ============================================================

# We build the request out of named pieces, so that each one can
# be explained separately. Change any of them and re-read.

CORES=4          # processor cores
MEMORY="8gb"     # memory
SCRATCH="10gb"   # temporary local disk on that machine
HOURS="02:00:00" # how long you want the machine for

echo "============================================"
echo "The command"
echo "============================================"
echo ""
echo "    qsub -I -l select=1:ncpus=${CORES}:mem=${MEMORY}:scratch_local=${SCRATCH} -l walltime=${HOURS}"
echo ""

echo "============================================"
echo "What each part means"
echo "============================================"
echo ""
echo "    qsub              send a request to the scheduler"
echo "    -I                interactive: give me a terminal"
echo "    select=1          one machine"
echo "    ncpus=${CORES}          ${CORES} processor cores on it"
echo "    mem=${MEMORY}          ${MEMORY} of memory"
echo "    scratch_local=${SCRATCH}  ${SCRATCH} of fast temporary disk"
echo "    walltime=${HOURS}   keep it for ${HOURS}"
echo ""

echo "============================================"
echo "What happens next"
echo "============================================"
echo ""
echo "The prompt will hang. That is the queue: the scheduler is"
echo "looking for a machine that matches. It can take seconds or"
echo "minutes."
echo ""
echo "When it finds one, your prompt comes back and the machine"
echo "name has changed, for example from zenith to zenon23."
echo "You are now on a compute node."
echo ""
echo "Type  exit  to give the machine back. Do that as soon as"
echo "you are finished, so somebody else can use it."
echo ""

echo "============================================"
echo "While you are in there"
echo "============================================"
echo ""
echo "    hostname          check which machine you got"
echo "    echo \$SCRATCHDIR  your private fast directory"
echo "    nproc             how many cores you actually have"
echo ""


# ============================================================
#  DOCUMENTATION
#      https://docs.metacentrum.cz/en/docs/computing/run-basic-job
#      https://docs.metacentrum.cz/en/docs/computing/advanced
# ============================================================

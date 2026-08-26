#!/usr/bin/env bash
#
# ============================================================
#  12_containers/build_image.sh
#  Building your own container
# ============================================================
#
#  WHY BOTHER
#
#  You have already hit the problem twice today:
#
#      the plain R module has no packages at all
#      the RStudio image has some, but no Stan
#
#  And there is a third reason we did not plan for. The language
#  model this workshop was built on DISAPPEARED from the service
#  two days before the workshop. One day it answered, the next it
#  returned "Model is blocked".
#
#  Software you do not control changes underneath you. A container
#  is one file that holds R and every package at fixed versions.
#  It runs the same today, next year, and on somebody else's
#  machine.
#
#  BEFORE YOU START
#
#  Building needs a special machine, builder.metacentrum.cz, and
#  membership of a group called "builders". Most accounts have it
#  already. If yours does not, send one email:
#
#      meta@cesnet.cz
#      "Please add me to the builders group."
#
#  This script only prints the steps. Building takes 20 minutes
#  and you should watch it, not run it blind.
#
# ============================================================

DEFINITION_FILE="workshop-r.def"
IMAGE_FILE="workshop-r.sif"


echo "============================================"
echo "STEP 1. Get onto the build machine"
echo "============================================"
echo ""
echo "    ssh ${USER}@builder.metacentrum.cz"
echo ""


echo "============================================"
echo "STEP 2. Put temporary files on a local disk"
echo "============================================"
echo ""
echo "    export SINGULARITY_TMPDIR=/scratch/\$USER/tmp"
echo "    mkdir -p \$SINGULARITY_TMPDIR"
echo ""
echo "This matters more than it looks."
echo ""
echo "Building a container means unpacking millions of small"
echo "files. On a network disk that is painfully slow. Our first"
echo "attempt unpacked 770 MB in 20 minutes before we gave up."
echo "On the local disk the same step took 2 minutes."
echo ""
echo "A network disk also cannot do everything the build needs."
echo "Pointing the temporary folder at /storage fails with"
echo "'failed to Lchown', because a network filesystem will not"
echo "let the build set file ownership."
echo ""


echo "============================================"
echo "STEP 3. Build into a folder first"
echo "============================================"
echo ""
echo "    singularity build --fakeroot --sandbox mydir/ ${DEFINITION_FILE}"
echo ""
echo "A sandbox is an ordinary folder you can look inside and fix."
echo ""
echo "Build straight to a .sif file and a failure in the last step"
echo "throws away everything. That happened to us twice, each time"
echo "after the 20 minute part had already succeeded."
echo ""


echo "============================================"
echo "STEP 4. Pack it into one file"
echo "============================================"
echo ""
echo "    singularity build --fakeroot ${IMAGE_FILE} mydir/"
echo ""


echo "============================================"
echo "STEP 5. Use it anywhere"
echo "============================================"
echo ""
echo "    singularity exec -B /storage ${IMAGE_FILE} Rscript my_analysis.R"
echo ""
echo "-B /storage lets the container see the shared filesystem."
echo "Leave it out and your job will insist your data does not exist."
echo ""


# ============================================================
#  DOCUMENTATION
#      https://docs.metacentrum.cz/en/docs/software/containers
#
#  Ready made images, including the RStudio one:
#      /cvmfs/singularity.metacentrum.cz/
# ============================================================

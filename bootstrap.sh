#!/usr/bin/env bash
#
# ============================================================
#  bootstrap.sh
#  Sets up the workshop repository in your own space
# ============================================================
#
#  WHAT IT DOES
#
#  Downloads the workshop files into one fixed place:
#
#      /storage/plzen1/home/YOUR_USERNAME/metacentrum-workshop
#
#  Everybody uses the same place, so every path shown on a slide
#  works on everybody's screen. The only part that differs
#  between people is your own username.
#
#  HOW TO RUN IT
#
#  Either in a terminal after logging in with ssh, or in the
#  terminal inside OnDemand (Clusters, then Shell Access).
#
#  Copy and paste this one line:
#
#      curl -sL https://raw.githubusercontent.com/ChlupacTheBosmer/metacentrum-workshop/main/bootstrap.sh | bash
#
#  Or, if you already have the file:
#
#      bash bootstrap.sh
#
#  It is safe to run more than once. If the files are already
#  there it just updates them.
#
# ============================================================

set -u


# ------------------------------------------------------------
# STEP 1. Work out where things go
# ------------------------------------------------------------
#
# $USER is your username. The system sets it when you log in.
# We build the path from it so this script works for everybody
# without being edited.

VOLUME="plzen1"
REPO_URL="https://github.com/ChlupacTheBosmer/metacentrum-workshop.git"
TARGET="/storage/${VOLUME}/home/${USER}/metacentrum-workshop"

echo "============================================"
echo "MetaCentrum workshop setup"
echo "============================================"
echo ""
echo "  username : ${USER}"
echo "  going to : ${TARGET}"
echo ""


# ------------------------------------------------------------
# STEP 2. Check we are actually on MetaCentrum
# ------------------------------------------------------------
#
# If /storage/plzen1 does not exist, this is not a MetaCentrum
# machine, and continuing would only produce a confusing error.

if [ ! -d "/storage/${VOLUME}" ]; then
    echo "Cannot find /storage/${VOLUME}."
    echo ""
    echo "This script is meant to be run on MetaCentrum, either after"
    echo "logging in with ssh, or in the terminal inside OnDemand."
    exit 1
fi


# ------------------------------------------------------------
# STEP 3. Check you have a home on this volume
# ------------------------------------------------------------

HOME_ON_VOLUME="/storage/${VOLUME}/home/${USER}"

if [ ! -d "$HOME_ON_VOLUME" ]; then
    echo "Cannot find your home directory at:"
    echo "    ${HOME_ON_VOLUME}"
    echo ""
    echo "Normally every account has one on every volume. If this is"
    echo "missing, email meta@cesnet.cz and say which volume."
    exit 1
fi


# ------------------------------------------------------------
# STEP 4. Get the files
# ------------------------------------------------------------
#
# Two cases. Either the folder is not there yet, so we download
# it fresh. Or it is already there, so we just pull the latest
# changes instead of downloading everything again.

if [ -d "${TARGET}/.git" ]; then

    echo "Already downloaded. Updating instead."
    echo ""
    cd "$TARGET"
    git pull --ff-only

else

    echo "Downloading. This takes a few seconds."
    echo ""
    git clone "$REPO_URL" "$TARGET"

fi


# ------------------------------------------------------------
# STEP 5. Make a place for your own results
# ------------------------------------------------------------
#
# Your results go inside your own copy, so that nobody writes
# over anybody else's.

mkdir -p "${TARGET}/results"
mkdir -p "${TARGET}/logs"


# ------------------------------------------------------------
# STEP 6. Tell you what to do next
# ------------------------------------------------------------

echo ""
echo "============================================"
echo "Done"
echo "============================================"
echo ""
echo "The workshop files are in:"
echo ""
echo "    ${TARGET}"
echo ""
echo "To go there in a terminal:"
echo ""
echo "    cd ${TARGET}"
echo ""
echo "In OnDemand, open Files, then Change directory, and paste"
echo "that same path."
echo ""
echo "In RStudio, set it as the working directory:"
echo ""
echo "    setwd(\"${TARGET}\")"
echo ""
echo "Then start with the folder 01_login."
echo ""

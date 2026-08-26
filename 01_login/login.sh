#!/usr/bin/env bash
#
# ============================================================
#  01_login/login.sh
#  Logging in to MetaCentrum from a terminal
# ============================================================
#
#  WHAT THIS FILE IS FOR
#
#  MetaCentrum is a set of computers somewhere else. To use them,
#  you connect to one of them over the network and get a text
#  terminal on it. The program that does this is called "ssh".
#
#  You can just type the ssh command by hand. This script exists so
#  you can see exactly what the command looks like, with the parts
#  that change written out clearly.
#
#  HOW TO USE IT
#
#      bash 01_login/login.sh
#
#  It will ask for your username, then run ssh for you.
#
# ============================================================


# ------------------------------------------------------------
# STEP 1. Which computer do we connect to?
# ------------------------------------------------------------
#
# MetaCentrum has several "frontend" machines. A frontend is the
# computer you land on when you log in. They are all equivalent.
# Pick the one closest to you so the connection feels faster.
#
#     zenith.metacentrum.cz     Brno
#     skirit.metacentrum.cz     Brno
#     perian.metacentrum.cz     Brno
#     tarkil.metacentrum.cz     Praha
#     elmo.metacentrum.cz       Praha
#     nympha.metacentrum.cz     Plzen
#     charon.metacentrum.cz     Liberec
#     tilia.metacentrum.cz      Pruhonice
#
# We put the name in a variable so it is easy to change.

FRONTEND="zenith.metacentrum.cz"


# ------------------------------------------------------------
# STEP 2. Who are you?
# ------------------------------------------------------------
#
# Your MetaCentrum username. It is usually not the same as your
# university login.
#
# "read -p" prints a question and waits for you to type an answer.
# The answer is stored in the variable USERNAME.

read -p "MetaCentrum username: " USERNAME


# ------------------------------------------------------------
# STEP 3. Check that the user typed something
# ------------------------------------------------------------
#
# If USERNAME is empty there is no point continuing. We stop here
# with a clear message instead of showing a confusing ssh error.
#
# -z means "the text is empty".

if [ -z "$USERNAME" ]; then
    echo "No username given. Nothing to do."
    exit 1
fi


# ------------------------------------------------------------
# STEP 4. Show the command before running it
# ------------------------------------------------------------
#
# This is the whole point of the script. The command below is what
# you would normally type by hand. Look at it, then remember it.

echo ""
echo "The command we are about to run is:"
echo ""
echo "    ssh ${USERNAME}@${FRONTEND}"
echo ""
echo "You will be asked for your password."
echo "Nothing appears on screen while you type it. That is normal."
echo ""


# ------------------------------------------------------------
# STEP 5. Connect
# ------------------------------------------------------------
#
# "exec" replaces this script with ssh. That is slightly tidier
# than running ssh as a child process, because when you type
# "exit" on the server you come straight back to your own shell.

exec ssh "${USERNAME}@${FRONTEND}"


# ============================================================
#  IF THE PASSWORD IS REFUSED
#
#  The MetaCentrum password is the "e-INFRA" password.
#  For most people it is not the university password.
#
#  Set or reset it here:
#      https://profile.e-infra.cz
#      -> Authentication -> Change password
#
#  Accounts also expire once a year, on 2 February.
#  Check the state of yours here:
#      https://perun.e-infra.cz
# ============================================================

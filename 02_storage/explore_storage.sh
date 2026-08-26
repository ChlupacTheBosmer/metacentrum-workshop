#!/usr/bin/env bash
#
# ============================================================
#  02_storage/explore_storage.sh
#  Finding your way around the storage volumes
# ============================================================
#
#  THE IDEA
#
#  On your laptop you have one home directory. On MetaCentrum you
#  have SEVERAL. One on each storage volume. They are separate
#  disks in separate buildings in different cities.
#
#  A volume is named after the city it lives in:
#      brno2, plzen1, praha2-natur, budejovice1, ...
#
#  Your home directory on a volume always has the same shape:
#
#      /storage/<volume>/home/<username>
#
#  for example:
#
#      /storage/plzen1/home/novak
#
#  Each one has its own size limit (its "quota"). They are not
#  copies of each other. A file you put on plzen1 is not on brno2.
#
#  Run this script on a frontend to look at yours.
#
#      bash 02_storage/explore_storage.sh
#
# ============================================================


# ------------------------------------------------------------
# STEP 1. Where does the system put you by default?
# ------------------------------------------------------------
#
# $HOME is a variable the system sets for you. It holds the path
# of the home directory you start in when you log in.

echo "============================================"
echo "1. Your default home directory"
echo "============================================"
echo ""
echo "\$HOME is: $HOME"
echo ""
echo "That is one of your homes. It is not the only one."
echo ""


# ------------------------------------------------------------
# STEP 2. Which volumes exist?
# ------------------------------------------------------------
#
# All the volumes are visible under /storage. Listing that
# directory shows every volume in MetaCentrum, not only yours.
#
# "ls -1" means "list, one name per line".

echo "============================================"
echo "2. All storage volumes that exist"
echo "============================================"
echo ""
ls -1 /storage
echo ""


# ------------------------------------------------------------
# STEP 3. Which of them do you have a home on?
# ------------------------------------------------------------
#
# Usually you have a home on every volume, created for you in
# advance. Let us check, one volume at a time.
#
# We could do this with one clever line, but a loop is easier to
# read and easier to change later.
#
# $USER is another variable the system sets. It is your username.

echo "============================================"
echo "3. Your home directory on each volume"
echo "============================================"
echo ""

for VOLUME in brno2 brno12-cerit plzen1 praha1 praha2-natur budejovice1; do

    # Build the path we want to test.
    CANDIDATE="/storage/${VOLUME}/home/${USER}"

    # "-d" asks: does this exist and is it a directory?
    if [ -d "$CANDIDATE" ]; then
        echo "  yes   $CANDIDATE"
    else
        echo "  no    $CANDIDATE"
    fi

done

echo ""


# ------------------------------------------------------------
# STEP 4. How full is the one you are standing in?
# ------------------------------------------------------------
#
# "du" means "disk usage". It adds up the size of everything
# inside a directory.
#
#   -s   summarise: give one total, not one line per file
#   -h   human readable: print "4.2G" instead of 4404019
#
# On a large home this takes a while, because it has to look at
# every single file.

echo "============================================"
echo "4. How much space you are using here"
echo "============================================"
echo ""
echo "Measuring $HOME ..."
du -sh "$HOME"
echo ""


# ------------------------------------------------------------
# STEP 5. Where to see all your quotas at once
# ------------------------------------------------------------
#
# Two easy ways, both better than measuring by hand:
#
#   a) Log out and log in again. The welcome text printed at
#      login lists every volume, its quota, and how much you use.
#
#   b) Open the web overview:
#         https://my.metacentrum.cz
#      Look at "Storage Spaces".

echo "============================================"
echo "5. Checking all your quotas"
echo "============================================"
echo ""
echo "  a) log in again and read the welcome text"
echo "  b) https://my.metacentrum.cz  ->  Storage Spaces"
echo ""


# ============================================================
#  MOVING AROUND
#
#  These are the only commands you need at first:
#
#      pwd                     where am I now
#      ls                      what is here
#      ls -l                   the same, with sizes and dates
#      cd /storage/plzen1/home/$USER      go to a specific place
#      cd ..                   go up one level
#      cd                      go back to your default home
#
#  DOCUMENTATION
#      https://docs.metacentrum.cz/en/docs/data/types-of-storage
#      https://docs.metacentrum.cz/en/docs/data/quotas
# ============================================================

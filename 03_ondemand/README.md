# 3. OnDemand

**Goal:** do the same things in a browser, without a terminal.

There is no code in this section. It is all done in the web interface.

<https://ondemand.metacentrum.cz>

Log in with the e-INFRA account, the same one as for `ssh`.

## What is on the dashboard

| menu | what it does |
|---|---|
| Files | browse and edit the storage volumes |
| Jobs | see running jobs, or build one |
| Clusters | a terminal in the browser |
| Interactive Apps | RStudio, Jupyter, Matlab, desktops |
| My Interactive Sessions | what is running now |

A red quota warning appears at the top when a volume is filling up.

## The file browser

This is the part worth the most.

1. **Files**, then **Change directory**
2. Paste a path, for example `/storage/plzen1/home/YOURNAME`
3. Click through it like any file manager

It is the same directory that `cd` reaches in the terminal. Two ways of
looking at one filesystem.

From here you can:

- upload and download by dragging
- edit text files in the browser
- copy files between storage volumes
- rename, delete, make directories

## Terminal in the browser

**Clusters**, then a shell entry. Gives a frontend shell with no `ssh`
client needed. Useful from a machine where you cannot install one.

## Try this

1. Open the file browser at your home directory
2. Find the same place in the terminal with `cd` and `ls`
3. Confirm both show the same files

## Links

- <https://ondemand.metacentrum.cz>
- <https://docs.metacentrum.cz/en/docs/graphical/ondemand>
- <https://docs.metacentrum.cz/en/docs/software/graphical-access>

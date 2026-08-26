# 2. Storage

**Goal:** know where files live and how to move between the volumes.

## Run

```bash
bash 02_storage/explore_storage.sh
```

It prints your default home, lists every storage volume, checks which
ones you have a home on, and measures how much space you use.

## The idea

A laptop has one home directory. MetaCentrum gives you one **per storage
volume**, each on a different disk in a different city:

```
/storage/<volume>/home/<username>
```

They are separate. A file on `plzen1` is not on `brno2`.

## Moving around

```bash
pwd                                 where am I
ls -l                               what is here
cd /storage/plzen1/home/$USER       go somewhere
cd ..                               up one level
cd                                  back to the default home
du -sh .                            how big is this directory
```

## Checking quotas

- The text printed at login lists every volume and its quota
- Or <https://my.metacentrum.cz>, section Storage Spaces

## Moving large amounts of data

Not on a frontend. Send it as a job instead:

```bash
qsub 02_storage/copy_large_data.pbs
```

Edit the two paths at the bottom of that file first.

## Links

- <https://docs.metacentrum.cz/en/docs/data/types-of-storage>
- <https://docs.metacentrum.cz/en/docs/data/quotas>
- <https://docs.metacentrum.cz/en/docs/data/large-data>

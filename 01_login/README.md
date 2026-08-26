# 1. Login

**Goal:** reach a MetaCentrum machine from a terminal.

## Run

```bash
bash 01_login/login.sh
```

It asks for your username, shows the `ssh` command, then runs it.

## Or type it yourself

```bash
ssh username@zenith.metacentrum.cz
```

Nothing appears while typing the password. That is normal.
`exit` logs out.

## If the password is refused

It is the **e-INFRA** password, usually not the university one.
Reset at <https://profile.e-infra.cz>, section Authentication.

## Done when

`hostname` prints something like `zenith.cerit-sc.cz`.

## Links

- <https://docs.metacentrum.cz/en/docs/access/log-in>
- <https://docs.metacentrum.cz/en/docs/access/account>

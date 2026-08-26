# Before the workshop

Please do this the day before, not on the morning. Accounts take time.

If anything fails, say so rather than fighting it alone.

---

## 1. A MetaCentrum account

Register at <https://metavo.metacentrum.cz/en/application/form>

Approval is manual and takes a few working days, so do this first.

Note: accounts expire every year on **2 February**. A reminder arrives by
email in January.

## 2. Check the login works

Open <https://ondemand.metacentrum.cz> and log in.

The dashboard should show a top bar reading Files, Jobs, Clusters,
Interactive Apps, My Interactive Sessions, and a grid of application tiles.

**Send the presenter a screenshot of that page.** It takes ten seconds and
proves everything works.

> The password is probably not the one expected. MetaCentrum uses the
> **e-INFRA** password, which for most people is not the university
> password. Set or reset it at <https://profile.e-infra.cz>, section
> Authentication, Change password.

## 3. Get an AI API key

1. Open <https://chat.ai.e-infra.cz> and log in with e-INFRA
2. Ask it something, just to see it work
3. Settings, Account, API keys, generate
4. Keep it somewhere safe for the workshop

Do not paste the key into a shared document.

## 4. Nothing to install

No R on the laptop, no packages, no SSH client. Everything runs in a
browser or on the cluster.

---

## The day

| section | topic |
|---|---|
| 1 | Login from a terminal |
| 2 | Storage |
| 3 | OnDemand |
| 4 | Jobs |
| 5 | RStudio |
| 6 | Interactive job |
| 7 | AI services |
| 8 | Embeddings |
| 9 | The model |
| 10 | One machine, many cores |
| 11 | Job arrays |
| 12 | Containers |

Each section is a numbered folder in the repository with its own README.
The slides name the file being used at the top of every slide.

---

## If something goes wrong

| symptom | fix |
|---|---|
| Login rejected | e-INFRA password, not the university one: <https://profile.e-infra.cz> |
| Account expired | Accounts lapse each 2 February: <https://perun.e-infra.cz> |
| Login page loops | Private window, stale cookies |
| No API keys menu | Log in to the chat page once first |

Support: meta@cesnet.cz. They answer, and they take requests for software.

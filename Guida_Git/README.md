# Guida a Git per il gruppo di lavoro

Questa è la guida di riferimento a Git per chiunque lavori sul progetto. È pensata per accompagnare sia chi non ha mai usato Git, partendo dalle basi, sia chi lo usa già e cerca un riferimento puntuale su un comando o su un flusso di lavoro. L'obiettivo è che nessuno debba improvvisare: qui trovi cosa è Git, come installarlo e configurarlo, come si lavora giorno per giorno, la strategia di branching che adottiamo, gli strumenti visuali e un glossario dei termini.

## Come è organizzata

La guida è divisa in pagine tematiche numerate. Se parti da zero, leggile in ordine: costruiscono i concetti uno sull'altro. Se cerchi qualcosa di specifico, vai direttamente alla pagina che ti serve.

1. [Introduzione: cos'è Git](01_introduzione.md) — concetti fondamentali, come Git ragiona, Git rispetto a GitHub.
2. [Installazione e configurazione](02_installazione_e_configurazione.md) — installare Git su Windows, macOS e Linux, e configurarlo la prima volta.
3. [Chiavi SSH e autenticazione](03_chiavi_ssh_e_autenticazione.md) — come autenticarsi verso GitHub, via SSH o HTTPS con token.
4. [Creare o clonare un repository](04_creare_o_clonare_un_repository.md) — iniziare un repository nuovo o agganciarsi a uno esistente, e il file `.gitignore`.
5. [Il ciclo base: add, commit, log](05_ciclo_base_add_commit_log.md) — l'area di staging, salvare le modifiche, leggere la storia.
6. [Branch e merge](06_branch_e_merge.md) — lavorare in parallelo su rami e unirli.
7. [Lavorare con i remote: push, pull, fetch](07_lavorare_con_i_remote.md) — sincronizzarsi con il repository remoto.
8. [Rebase](08_rebase.md) — riscrivere la storia in modo pulito, e quando non farlo.
9. [Annullare e recuperare](09_annullare_e_recuperare.md) — restore, reset, revert, stash, reflog: uscire dai guai.
10. [Tag e release](10_tag_e_release.md) — marcare le versioni e il legame con i rilasci.
11. [Gestione dei conflitti](11_gestione_dei_conflitti.md) — capire e risolvere i conflitti di merge.
12. [La strategia di branching del progetto](12_strategia_di_branching.md) — come lavoriamo noi: GitHub Flow, tag e hotfix.
13. [Pull Request su GitHub](13_pull_request_su_github.md) — proporre, revisionare e integrare le modifiche.
14. [Strumenti visuali: TortoiseGit e altri](14_strumenti_visuali_tortoisegit.md) — usare Git senza riga di comando.
15. [Buone pratiche](15_buone_pratiche.md) — le abitudini che tengono la storia pulita e il team sereno.
16. [Risoluzione dei problemi comuni](16_troubleshooting.md) — gli errori che capitano più spesso e come uscirne.
17. [Glossario dei termini Git](17_glossario.md) — il vocabolario del "mondo Git".

## Convenzioni di questa guida

I comandi sono mostrati in blocchi di codice, pensati per essere eseguiti nel terminale (Git Bash su Windows, il terminale su macOS e Linux). Le parti tra parentesi angolari, come `<nome-branch>`, sono segnaposto da sostituire con il valore reale. Dove un concetto è delicato, la spiegazione precede il comando: capire *cosa* fa un comando conta più che ricordarne la sintassi a memoria.

## Documentazione di riferimento

- Documentazione ufficiale di Git: https://git-scm.com/doc
- Libro *Pro Git* (gratuito, in italiano): https://git-scm.com/book/it/v2
- Documentazione di GitHub: https://docs.github.com

# Installation de la base pour les projets

## Windows

---

Installation de la base de projet

Pour installer la base de projet depuis un repository Bitbucket, veuillez suivre les étapes suivantes :

1. Télécharger la branch `installation` en cliquant sur le bouton "..." en haut à droite puis sur "Download repository"
2. Dézipper le fichier ou vous le souhaitez
3. Ouvrez une session **PowerShell** en tant qu'**administrateur** (ou appuyez sur la touche WINDOWS+X puis A)
4. Modifiez l'ExecutionPolicy de **PowerShell** en utilisant la commande suivante :

```powershell
Set-ExecutionPolicy Unrestricted
```

5. Rendez-vous dans le dossier ou vous le fichier zip à était dézipper
6. Lancez la commande **PowerShell** suivante pour lancer le processus d'installation de WSL & Ubuntu avec la pré-configuration:

```powershell
.\windows_install.ps1
```

---

Notez que vous devez **impérativement** modifier l'ExecutionPolicy de **PowerShell** en "Unrestricted" pour pouvoir **exécuter le script**.

## Linux

---

Installation de la base de projet (installation de la base recommandé à la racine du disque dur [~/])

```bash
git clone git@bitbucket.org:wyzproject1/wyz-setup-projects.git wyz --recurse-submodules -j 8
```

Avoir `jq` d'installé sur votre machine (pour les scripts taskfile)

```bash
sudo apt install jq
```


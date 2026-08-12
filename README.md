<p align="center">
   <img src="./front/src/favicon.png" width="192px" />
</p>

# MicroCRM (P7 - Développeur Full-Stack - Java et Angular - Mettez en œuvre l'intégration et le déploiement continu d'une application Full-Stack)

MicroCRM est une application de démonstration basique ayant pour être objectif de servir de socle pour le module "P7 - Développeur Full-Stack".

L'application MicroCRM est une implémentation simplifiée d'un ["CRM" (Customer Relationship Management)](https://fr.wikipedia.org/wiki/Gestion_de_la_relation_client). Les fonctionnalités sont limitées à la création, édition et la visualisations des individus liés à des organisations.

![Page d'accueil](./misc/screenshots/screenshot_1.png)
![Édition de la fiche d'un individu](./misc/screenshots/screenshot_2.png)

## Code source

### Organisation

Ce [monorepo](https://en.wikipedia.org/wiki/Monorepo) contient les 2 composantes du projet "MicroCRM":

- La partie serveur (ou "backend"), en Java SpringBoot 3;
- La partie cliente (ou "frontend"), en Angular 17.

### Démarrage rapide

#### Avec Docker

Lancez le front et le back

- avec docker compose
   ```sh
   # lancer le front et le back avec docker compose
   docker compose up --build
   # arreter les containers avec docker compose
   docker compose down
   ```
- OU séparément
   ```sh
   # build l'image back
   docker build --target back -t orion-microcrm-back:latest .
   # execute l'image
   docker run -it --rm -p 8080:8080 orion-microcrm-back:latest

   # build l'image front
   docker build --target front -t orion-microcrm-front:latest .
   # execute l'image
   docker run -it --rm -p 80:80 -p 443:443 orion-microcrm-front:latest
   ```
- OU la version standalone
   ```sh
   docker build --target standalone -t orion-microcrm-standalone:latest .
   docker run -it --rm -p 8080:8080 -p 80:80 -p 443:443 orion-microcrm-standalone:latest
   ```

Dans tous les cas :

- L'application sera disponible sur https://localhost.
- L'API sera disponible sur http://localhost:8080.

##### Remarques

Le Dockerfile 

- réalise un build multi-étapes qui permet de minimiser la taille de l'image finale
- utilise des images spécifiques pour chaque step
   - node:24-alpine : distribution officielle LTS
   - gradle:8.7-jdk17 : distribution officielle avec JDK17 pour build et gradle 8.7 utilisé dans le projet
   - caddy:2.11.4-alpine : distribution officielle avec caddy2
   - eclipse-temurin:17-jre-alpine : distribution officielle avec JRE17 uniquement pour exécuté le jar

Le fichier `docker-compose` 

- démarre les deux containers à partir du Dockerfile
- utilise les ports "standards" 80, 442 pour le front et 8080 pour le back



#### Sans Docker

##### Dépendances

- [OpenJDK >= 17](https://openjdk.org/)
- [NPM >= 10.2.4](https://www.npmjs.com/)

##### Back

```sh
# accéder au dossier back
cd back
# build l'application
# Sur Linux
./gradlew build
# Sur Windows
gradlew.bat build
# lancer l'application
java -jar build/libs/microcrm-0.0.1-SNAPSHOT.jar
```

Puis ouvrir l'URL http://localhost:8080 dans votre navigateur.

##### Client

```sh
# accéder au dossier front
cd front
# installer les dépendances
npm install
# lancer l'application
npm start
```

Puis ouvrir l'URL http://localhost:4200 dans votre navigateur.

### Exécution des tests

#### Client

**Dépendances**

- Google Chrome ou Chromium

```shell
# tests front
cd front
ng test --code-coverage --browsers=ChromeHeadlessNoSandbox
# tests back + code coverage
cd back
./gradlew test
```

## CI / CD


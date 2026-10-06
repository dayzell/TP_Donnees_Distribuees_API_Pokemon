# TP Données Distribuées — API Pokémon et Apache Cassandra

<p align="center">
  <img src="https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExcjV0bnJoemw0Y3hncjhtaDhwNzhhYWxvamh5M2N0MnpzOWxycDRlaSZlcD12MV9naWZzX3NlYXJjaCZjdD1n/vnGlErQHuF9BK/giphy.gif" alt="Pokémon" width="400">
</p>

M2 Big Data & IA — Données distribuées

Ce projet récupère des données depuis la PokeAPI, les stocke dans Apache Cassandra et les exploite à l'aide de requêtes CQL orientées métier.

```text
PokeAPI  ->  script Python  ->  Cassandra (keyspace pokemon)  ->  requêtes CQL
```

## Sujet

Constituer une base de données des Pokémon de la **1re génération** (n° 1 à 151) afin de pouvoir consulter la fiche d'un Pokémon, rechercher par nom et lister les Pokémon d'un type classés par expérience.

## API utilisée

[PokeAPI](https://pokeapi.co/) — API REST publique, sans authentification.

| Endpoint | Rôle |
|---|---|
| `GET /api/v2/pokemon?limit=151` | Liste paginée : renvoie uniquement `name` et `url` de chaque Pokémon |
| `GET /api/v2/pokemon/{id ou nom}` | Détail complet d'un Pokémon |

L'import se fait donc en deux temps : récupération de la liste, puis appel du détail de chaque Pokémon.

## Données récupérées

| Champ API | Type JSON | Transformation | Type Cassandra |
|---|---|---|---|
| `id` | int | — | `int` |
| `name` | string | — | `text` |
| `height` | int | en décimètres | `int` |
| `weight` | int | en hectogrammes | `int` |
| `base_experience` | int | `null` remplacé par 0 | `int` |
| `types` | liste d'objets | on garde `type.name` | `list<text>` |
| `abilities` | liste d'objets | on garde `ability.name` | `list<text>` |
| `stats` | liste d'objets | `stat.name` -> `base_stat` | `map<text, int>` |
| `sprites` | objet | on garde `front_default` (URL de l'image) | `text` |

Les champs volumineux et non utilisés (`moves`, `game_indices`, `held_items`...) ne sont pas importés.

## Modèle Cassandra

Keyspace : `pokemon` (`SimpleStrategy`, `replication_factor = 1`, un seul nœud).

Le modèle suit le principe de Cassandra : **une table par requête**. Les données sont volontairement dupliquées (dénormalisation) pour que chaque requête ne lise qu'une seule partition.

| Table | Clé de partition | Clé de clustering | Requête servie |
|---|---|---|---|
| `pokemon_by_id` | `id` | — | Fiche complète d'un Pokémon par son numéro |
| `pokemon_by_name` | `name` | — | Recherche d'un Pokémon par son nom |
| `pokemon_by_type` | `type` | `base_experience DESC, id ASC` | Pokémon d'un type, du plus expérimenté au moins expérimenté |

Remarques :

- Un Pokémon à deux types (ex. bulbasaur : `grass` et `poison`) est inséré dans deux partitions de `pokemon_by_type`. Cette table contient donc plus de lignes que `pokemon_by_id`.
- `id` est ajouté à la clé de clustering de `pokemon_by_type` pour garantir l'unicité : sans lui, deux Pokémon de même type et de même expérience s'écraseraient (un `INSERT` sur une clé existante remplace la ligne).

Le schéma complet est dans [`queries/00_schema.cql`](queries/00_schema.cql).

## Requêtes métier

Exemples de besoins couverts par le modèle, sans `ALLOW FILTERING` :

```sql
-- Fiche du Pokémon n° 25
SELECT * FROM pokemon_by_id WHERE id = 25;

-- Recherche par nom
SELECT * FROM pokemon_by_name WHERE name = 'pikachu';

-- Les 5 Pokémon de type feu les plus expérimentés
SELECT name, base_experience FROM pokemon_by_type WHERE type = 'fire' LIMIT 5;

-- Pokémon de type eau ayant au moins 150 d'expérience
SELECT name, base_experience FROM pokemon_by_type WHERE type = 'water' AND base_experience >= 150;

-- Nombre de Pokémon et attaque moyenne d'un type
SELECT COUNT(*), AVG(attack) FROM pokemon_by_type WHERE type = 'grass';
```

## Structure du dépôt

```text
.
├── README.md
├── docker-compose.yml        # Cassandra 4.1, un nœud
├── requirements.txt
├── queries/
│   └── 00_schema.cql         # keyspace et tables
└── script/
    ├── explore_api.py        # exploration de la structure JSON de l'API
    └── getapi.py             # import des 151 Pokémon dans Cassandra
```

## Installation et lancement

Prérequis : Docker, Python 3.

```bash
# 1. Démarrer Cassandra (attendre environ une minute que le nœud soit prêt)
docker compose up -d
docker exec cassandra nodetool status

# 2. Créer le keyspace et les tables
docker exec -i cassandra cqlsh < queries/00_schema.cql

# 3. Environnement Python
python -m venv venv
source venv/Scripts/activate      # Windows (Git Bash) ; sous Linux : source venv/bin/activate
pip install -r requirements.txt

# 4. Importer les données
python script/getapi.py

# 5. Vérifier
docker exec cassandra cqlsh -k pokemon -e "SELECT COUNT(*) FROM pokemon_by_id;"
```

`pyasyncore` est nécessaire avec Python 3.12 et plus : le module `asyncore`, utilisé par `cassandra-driver`, a été retiré de la bibliothèque standard.

## Explorer l'API

Le script `explore_api.py` affiche les champs d'une réponse et permet de descendre dans le JSON :

```bash
python script/explore_api.py                    # champs de pikachu
python script/explore_api.py bulbasaur types    # détail d'un champ
python script/explore_api.py pikachu stats.0    # premier élément d'une liste
python script/explore_api.py "?limit=5" results # endpoint de liste
```

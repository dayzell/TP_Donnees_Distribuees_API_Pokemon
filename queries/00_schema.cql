CREATE KEYSPACE IF NOT EXISTS pokemon
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE pokemon;

-- Fiche complète d'un Pokémon, accès par son numéro de Pokédex
CREATE TABLE IF NOT EXISTS pokemon_by_id (
  id int PRIMARY KEY,
  name text,
  height int,
  weight int,
  base_experience int,
  types list<text>,
  abilities list<text>,
  stats map<text, int>,
  sprite text
);

-- Recherche d'un Pokémon par son nom
CREATE TABLE IF NOT EXISTS pokemon_by_name (
  name text PRIMARY KEY,
  id int,
  types list<text>,
  base_experience int
);

-- Pokémon d'un type, triés du plus expérimenté au moins expérimenté
-- (un Pokémon à 2 types apparaît dans 2 partitions)
CREATE TABLE IF NOT EXISTS pokemon_by_type (
  type text,
  base_experience int,
  id int,
  name text,
  hp int,
  attack int,
  defense int,
  speed int,
  PRIMARY KEY ((type), base_experience, id)
) WITH CLUSTERING ORDER BY (base_experience DESC, id ASC);

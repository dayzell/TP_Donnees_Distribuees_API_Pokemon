-- Vérification de l'import des données de la PokeAPI
USE pokemon;

-- 1. Nombre de lignes par table
--    pokemon_by_id   : 151 attendus (génération 1)
--    pokemon_by_type : plus de 151, un Pokémon à 2 types est présent dans 2 partitions
SELECT COUNT(*) FROM pokemon_by_id;
SELECT COUNT(*) FROM pokemon_by_name;
SELECT COUNT(*) FROM pokemon_by_type;

-- 2. Aperçu des données
SELECT id, name, types, base_experience FROM pokemon_by_id LIMIT 10;

-- 3. Premier et dernier Pokémon de la génération 1
SELECT id, name FROM pokemon_by_id WHERE id IN (1, 151);

-- 4. Un même Pokémon (bulbasaur, types grass et poison) retrouvé dans les 3 tables
SELECT * FROM pokemon_by_id WHERE id = 1;
SELECT * FROM pokemon_by_name WHERE name = 'bulbasaur';
SELECT type, name, base_experience FROM pokemon_by_type WHERE type = 'grass' AND base_experience = 64 AND id = 1;
SELECT type, name, base_experience FROM pokemon_by_type WHERE type = 'poison' AND base_experience = 64 AND id = 1;

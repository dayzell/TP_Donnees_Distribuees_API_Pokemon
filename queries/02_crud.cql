-- CRUD sur un Pokémon fictif : cherfennecif (id 1001)
USE pokemon;

-- =====================================================================
-- CREATE
-- Le Pokémon est inséré dans les 3 tables pour qu'elles restent cohérentes.
-- Le BATCH garantit que les 4 INSERT sont appliqués ensemble.
-- =====================================================================
BEGIN BATCH
  INSERT INTO pokemon_by_id (id, name, height, weight, base_experience, types, abilities, stats)
  VALUES (1001, 'cherfennecif', 5, 80, 26, ['chacal', 'fire'], ['flash-fire'],
          {'hp': 40, 'attack': 55, 'defense': 35, 'speed': 70});

  INSERT INTO pokemon_by_name (name, id, types, base_experience)
  VALUES ('cherfennecif', 1001, ['chacal', 'fire'], 26);

  INSERT INTO pokemon_by_type (type, base_experience, id, name, hp, attack, defense, speed)
  VALUES ('chacal', 26, 1001, 'cherfennecif', 40, 55, 35, 70);

  INSERT INTO pokemon_by_type (type, base_experience, id, name, hp, attack, defense, speed)
  VALUES ('fire', 26, 1001, 'cherfennecif', 40, 55, 35, 70);
APPLY BATCH;

-- =====================================================================
-- READ
-- =====================================================================
SELECT * FROM pokemon_by_id WHERE id = 1001;
SELECT * FROM pokemon_by_name WHERE name = 'cherfennecif';
SELECT name, base_experience, hp FROM pokemon_by_type WHERE type = 'fire';

-- =====================================================================
-- UPDATE
-- =====================================================================
-- Colonne simple
UPDATE pokemon_by_id SET weight = 95 WHERE id = 1001;

-- Ajout d'un élément dans une liste
UPDATE pokemon_by_id SET abilities = abilities + ['blaze'] WHERE id = 1001;

-- Modification d'une clé dans une map, répercutée dans les autres tables
BEGIN BATCH
  UPDATE pokemon_by_id   SET stats['hp'] = 50 WHERE id = 1001;
  UPDATE pokemon_by_type SET hp = 50 WHERE type = 'chacal' AND base_experience = 26 AND id = 1001;
  UPDATE pokemon_by_type SET hp = 50 WHERE type = 'fire'   AND base_experience = 26 AND id = 1001;
APPLY BATCH;

SELECT id, name, weight, abilities, stats FROM pokemon_by_id WHERE id = 1001;
SELECT name, hp FROM pokemon_by_type WHERE type = 'chacal';

-- Remarque : base_experience fait partie de la clé primaire de pokemon_by_type,
-- elle ne peut pas être modifiée par un UPDATE. Il faut supprimer la ligne puis la réinsérer.

-- =====================================================================
-- DELETE
-- =====================================================================
-- Suppression d'une seule colonne
DELETE abilities FROM pokemon_by_id WHERE id = 1001;
SELECT id, name, abilities FROM pokemon_by_id WHERE id = 1001;

-- Suppression complète du Pokémon dans les 3 tables
BEGIN BATCH
  DELETE FROM pokemon_by_id   WHERE id = 1001;
  DELETE FROM pokemon_by_name WHERE name = 'cherfennecif';
  DELETE FROM pokemon_by_type WHERE type = 'chacal' AND base_experience = 26 AND id = 1001;
  DELETE FROM pokemon_by_type WHERE type = 'fire'   AND base_experience = 26 AND id = 1001;
APPLY BATCH;

-- Doit renvoyer 0 ligne
SELECT * FROM pokemon_by_id WHERE id = 1001;
SELECT * FROM pokemon_by_name WHERE name = 'cherfennecif';

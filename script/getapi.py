import requests
from cassandra.cluster import Cluster

API = "https://pokeapi.co/api/v2/pokemon"
LIMIT = 151  # 1re génération

# La liste ne donne que {name, url} : on appelle ensuite le détail de chaque Pokémon
pokemons = requests.get(API, params={"limit": LIMIT}, timeout=30).json()["results"]

session = Cluster(["127.0.0.1"]).connect("pokemon")

ins_id = session.prepare(
    "INSERT INTO pokemon_by_id (id, name, height, weight, base_experience, types, abilities, stats, sprite) "
    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")
ins_name = session.prepare(
    "INSERT INTO pokemon_by_name (name, id, types, base_experience) VALUES (?, ?, ?, ?)")
ins_type = session.prepare(
    "INSERT INTO pokemon_by_type (type, base_experience, id, name, hp, attack, defense, speed) "
    "VALUES (?, ?, ?, ?, ?, ?, ?, ?)")

for p in pokemons:
    d = requests.get(p["url"], timeout=30).json()

    types = [t["type"]["name"] for t in d["types"]]
    abilities = [a["ability"]["name"] for a in d["abilities"]]
    stats = {s["stat"]["name"]: s["base_stat"] for s in d["stats"]}
    xp = d["base_experience"] or 0  # peut être null dans l'API, interdit dans une clé de clustering

    session.execute(ins_id, (d["id"], d["name"], d["height"], d["weight"], xp,
                             types, abilities, stats, d["sprites"]["front_default"]))
    session.execute(ins_name, (d["name"], d["id"], types, xp))
    for t in types:
        session.execute(ins_type, (t, xp, d["id"], d["name"], stats.get("hp"),
                                   stats.get("attack"), stats.get("defense"), stats.get("speed")))

print(len(pokemons), "pokémons insérés")

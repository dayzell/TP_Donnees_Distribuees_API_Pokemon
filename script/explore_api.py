"""Explorer la réponse JSON de la PokeAPI avant de créer les tables Cassandra.

Utilisation :
    python script/explore_api.py                     -> champs de pikachu
    python script/explore_api.py bulbasaur           -> champs d'un autre Pokémon (nom ou numéro)
    python script/explore_api.py pikachu stats       -> détail d'un champ
    python script/explore_api.py pikachu stats.0     -> 1er élément de la liste "stats"
    python script/explore_api.py pikachu stats.0.stat
"""
import json
import sys

import requests

API = "https://pokeapi.co/api/v2/pokemon/"


def apercu(valeur):
    """Résumé court d'une valeur : sa taille pour une liste/un objet, sinon la valeur elle-même."""
    if isinstance(valeur, list):
        return f"{len(valeur)} élément(s)"
    if isinstance(valeur, dict):
        return f"clés : {', '.join(valeur.keys())}"
    return repr(valeur)[:60]


pokemon = sys.argv[1] if len(sys.argv) > 1 else "pikachu"
chemin = sys.argv[2] if len(sys.argv) > 2 else ""

data = requests.get(API + pokemon, timeout=30).json()

# Descendre dans le JSON en suivant le chemin, ex. "stats.0.stat"
for cle in filter(None, chemin.split(".")):
    data = data[int(cle)] if isinstance(data, list) else data[cle]

print(f"=== {API}{pokemon}  {chemin or '(racine)'} ===\n")

if isinstance(data, dict):
    for cle, valeur in data.items():
        print(f"{cle:28} {type(valeur).__name__:6} {apercu(valeur)}")
elif isinstance(data, list):
    print(f"Liste de {len(data)} élément(s). Premier élément :\n")
    print(json.dumps(data[0], indent=2, ensure_ascii=False) if data else "(vide)")
else:
    print(f"{type(data).__name__} : {data!r}")

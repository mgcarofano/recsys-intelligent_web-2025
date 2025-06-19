# Knowledge-Based Movie Recommender System

---

## Group

| # | First name | Last name | Email |
| --- | --- | --- | --- |
| 1 | Mario Gabriele | Carofano | [*m.carofano@studenti.unina.it*](mailto:m.carofano@studenti.unina.it) |
| 2 | Oleksandr | Sosovskyy | [*alessandrososovskyy@gmail.com*](mailto:alessandrososovskyy@gmail.com) |

---

## About the project
This work is the final homework for the subject Intelligent Web at "Università degli Studi di Napoli - Federico II", academic year 2024-2025. It implements a knowledge-based recommender system for movies, combining a **Python back-end** (semantic querying and ranking) with a **Flutter front-end** (cross-platform user interface).

---

## Background
...

---

## Datasets
...

---

### Requirements
To install all necessary dependencies, make sure you have both Python and Flutter set up. For the back-end, navigate to the `recsys_backend` directory and run:

```
bash

pip install -r requirements.txt

```

This will install all Python packages required for querying DBpedia and running the recommendation logic.

Similarly, for the front-end go to the `recsys_app` directory and run:

```
bash

flutter pub get

```

This command will fetch all necessary Dart packages defined in the `pubspec.yaml` file.

After installing both sets of dependencies, the system will be ready to run.

---

### References
- [MovieLens Small Dataset](https://grouplens.org/datasets/movielens/)
- [DBpedia SPARQL Endpoint](https://dbpedia.org/sparql)

---
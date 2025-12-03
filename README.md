# A Movie-Lens-Small Application: Knowledge-based Recommender System

## Group

| # | First name | Last name | Email |
| --- | --- | --- | --- |
| 1 | Mario Gabriele | Carofano | [*m.carofano@studenti.unina.it*](mailto:m.carofano@studenti.unina.it) |
| 2 | Oleksandr | Sosovskyy | [*alessandrososovskyy@gmail.com*](mailto:alessandrososovskyy@gmail.com) |

## About the project
This work is the final homework for the subject Intelligent Web at "Università degli Studi di Napoli - Federico II", academic year 2024-2025. It implements a knowledge-based recommender system for movies, combining a **Python back-end** (semantic querying and ranking) with a **Flutter front-end** (cross-platform user interface).

The recommender system leverages the [MovieLens Small Dataset](https://grouplens.org/datasets/movielens/) for user ratings and movie metadata. It enriches this data by querying [DBpedia](https://dbpedia.org/sparql) (with SPARQL) to extract additional semantic information about movies, such as genres, directors, actors, and release years. The system uses this enriched data to provide personalized movie recommendations based on user preferences.

## Requirements
To install all necessary dependencies, make sure you have both Python and Flutter set up.

For the back-end, navigate to the `recsys_backend/` directory and run:

```

pip install -r requirements.txt

```

This will install all Python packages required for querying DBpedia and running the recommendation logic.

Similarly, for the front-end go to the `recsys_app/` directory and run:

```

flutter pub get

```

This command will fetch all necessary Dart packages defined in the `pubspec.yaml` file.

## Documentation
More detailed documentation about the system architecture, design decisions, and implementation details can be found in the `Documentazione.pdf` file included in this repository.

## Running the Application
To run the application, follow these steps:
1. **Start the Back-end**:
    - Navigate to the `recsys_backend/` directory.
    - Run the back-end server using:
        ```

        python http_server.py

        ```
    - The back-end will start listening for requests at the address `http://localhost:8000`.
2. **Start the Front-end**:
    - Navigate to the `recsys_app/` directory.
    - Run the Flutter application using:
        ```

        flutter run

        ```
    - This will launch the app to test the recommender system interface.
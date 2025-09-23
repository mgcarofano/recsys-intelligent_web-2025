/*

	recsys_carousel.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	...

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:knowledge_recsys/model/carousel_model.dart';
import 'package:knowledge_recsys/model/movie_model.dart';
import 'package:knowledge_recsys/recsys_main.dart';
import 'package:knowledge_recsys/view/widgets/recsys_loading_dialog.dart';
import 'package:knowledge_recsys/view/widgets/recsys_movie_card.dart';

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

//	############################################################################
//	CLASSI e ROUTE

class RecSysCarousel extends StatefulWidget {
  final Carousel carousel;
  final double height;
  final int columns;

  const RecSysCarousel({
    required this.carousel,
    required this.height,
    required this.columns,
    super.key,
  });

  @override
  State<RecSysCarousel> createState() => _RecSysCarouselState();
}

class _RecSysCarouselState extends State<RecSysCarousel> {
  late List<Movie> displayedMovies;

  final List<Movie> initialMovies = List<Movie>.empty(growable: true);
  final List<Movie> moreMovies = List<Movie>.empty(growable: true);

  bool expanded = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    initialMovies.clear();
    initialMovies.addAll(widget.carousel.movies);
    displayedMovies = initialMovies;
  }

  Future<void> _loadAllMovies() async {
    if (loading || expanded) return;

    setState(() => loading = true);

    if (moreMovies.isEmpty) {
      moreMovies.clear();
      moreMovies.addAll(await fetchMoviesFromIds(widget.carousel.allIds));
    }

    setState(() {
      displayedMovies = moreMovies;
      expanded = true;
      loading = false;
    });
  }

  void _collapse() {
    setState(() {
      displayedMovies = initialMovies;
      expanded = false;
    });
  }

  String _buildCategoryTitle({
    required String category,
    required List<String> params,
  }) {
    switch (category) {
      case "actors":
        return "Ti è piaciuto '${params[0]}'? Scopri altri ${params[1]} film in cui è protagonista";
      case "composers":
        return "Hai amato la colonna sonora di '${params[0]}'? Lasciati guidare da questi altri ${params[1]} capolavori";
      case "directors":
        return "${params[1]} film diretti dalla mano visionaria di '${params[0]}'";
      case "genres":
        return "Scopri altri ${params[1]} titoli '${params[0]}'";
      case "producers":
        return "Se '${params[0]}' ti ha convinto, lasciati stupire dalle sue ${params[1]} produzioni";
      case "production_companies":
        return "Per te che ami '${params[0]}', ecco altri ${params[1]} film che non puoi perdere";
      case "subjects":
        return "Se '${params[0]}' ti ha appassionato, ecco ${params[1]} nuovi film";
      case "writers":
        return "Hai apprezzato la sceneggiatura di '${params[0]}'? Scopri queste altre ${params[1]} storie";
      default:
        return "${params[1]} film";
    }
  }

  Widget _buildCarouselHeader(Carousel c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _buildCategoryTitle(
              category: c.category,
              params: [c.featureName, c.allIds.length.toString()],
            ),
            style: Theme.of(context).textTheme.headlineMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (c.allIds.length > maxColumns)
          TextButton.icon(
            onPressed: expanded ? _collapse : _loadAllMovies,
            icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            label: Text(
              expanded ? "Mostra meno" : "Mostra tutto",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
      ],
    );
  }

  Widget _buildCarouselMoviesList(Carousel c, double h, int columns) {
    if (!expanded)
      return SizedBox(
        height: h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: min(c.movies.length, maxColumns),
          separatorBuilder: (_, __) => const SizedBox(width: 32),
          itemBuilder: (context, i) => RecSysMovieCard(movie: c.movies[i]),
        ),
      );
    else
      return GridView.builder(
        itemCount: c.movies.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 32,
          crossAxisSpacing: 32,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, i) => RecSysMovieCard(movie: c.movies[i]),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10.0,
      children: [
        _buildCarouselHeader(widget.carousel),
        if (loading)
          const RecSysLoadingDialog(alertMessage: 'Caricamento...')
        else
          _buildCarouselMoviesList(
            widget.carousel.copyWith(movies: displayedMovies),
            widget.height,
            widget.columns,
          ),
        const Divider(),
      ],
    );
  }
}

//	############################################################################
//	RIFERIMENTI

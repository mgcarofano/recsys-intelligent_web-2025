/*

	recsys_carousel.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	La classe RecSysCarousel crea un widget personalizzato per visualizzare una lista orizzontale di film raccomandati, con un titolo che fornisce la caratteristica principale per cui sono stati selezionati e una serie di card per ognuno di essi. Il widget supporta il caricamento asincrono di ulteriori film e la navigazione verso una pagina dedicata alla caratteristica selezionata.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:knowledge_recsys/model/carousel_model.dart';
import 'package:knowledge_recsys/model/movie_model.dart';
import 'package:knowledge_recsys/view/widgets/recsys_alert_dialog.dart';
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

  const RecSysCarousel({
    required this.carousel,
    required this.height,
    super.key,
  });

  @override
  State<RecSysCarousel> createState() => _RecSysCarouselState();
}

class _RecSysCarouselState extends State<RecSysCarousel> {
  late List<Movie> recommendedMovies;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    recommendedMovies = widget.carousel.movies;
  }

  Future<void> _loadAllMovies() async {
    final feature = widget.carousel.feature;

    if (!mounted) return;
    context.push(
      '/feature/${feature.featureId}',
      extra: {
        'feature': feature,
        'recommendedIds': {
          for (var m in recommendedMovies) m.idMovie: m.softmaxProb,
        },
      },
    );
  }

  void _showFeatureInfo() {
    final feature = widget.carousel.feature;
    showDialog(
      context: context,
      builder: (context) => RecSysAlertDialog(
        topIcon: Icons.query_stats,
        alertTitle: 'Statistiche per nerd',
        alertContent: feature.toTable(),
      ),
    );
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
    final carouselTitle = _buildCategoryTitle(
      category: c.feature.category,
      params: [c.feature.name, c.allIds.length.toString()],
    );

    return Row(
      spacing: 8.0,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Tooltip(
            message: carouselTitle,
            child: Text(
              carouselTitle,
              style: Theme.of(context).textTheme.headlineMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _loadAllMovies,
          icon: Icon(Icons.add_to_queue),
          label: Text(
            "Mostra tutto",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        TextButton.icon(
          onPressed: _showFeatureInfo,
          icon: Icon(Icons.info_outline),
          label: Text(
            "Altre info",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselMoviesList(Carousel c, double h) {
    return SizedBox(
      height: h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: c.movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 32),
        itemBuilder: (context, i) {
          final m = c.movies[i];
          return RecSysMovieCard(movie: m, recommendedChip: false);
        },
      ),
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
            widget.carousel.copyWith(movies: recommendedMovies),
            widget.height,
          ),
        const Divider(),
      ],
    );
  }
}

//	############################################################################
//	RIFERIMENTI

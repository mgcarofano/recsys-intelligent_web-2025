#!/bin/bash
python tree_print.py . \
.git .vscode _altro _documentazione _old \
recsys_backend/vector_extractor.py recsys_backend/requirements.txt recsys_backend/template.txt \
recsys_backend/__pycache__ recsys_backend/evaluation_results \
recsys_backend/data/ml-latest-small/README.txt \
recsys_backend/data/movie_posters recsys_backend/data/ratings_complemented \
recsys_backend/data_collection/test_main.py \
recsys_app/README.md recsys_app/analysis_options.yaml recsys_app/knowledge_recsys.iml recsys_app/lib/main.dart recsys_app/lib/template.txt recsys_app/material-theme.zip recsys_app/pubspec.lock \
recsys_app/android recsys_app/build recsys_app/ios recsys_app/lib/cache recsys_app/linux recsys_app/macos recsys_app/test recsys_app/web recsys_app/windows \
.DS_Store .gitignore flutter_tutorial.txt output.txt README.md tree_print.py tree_print.sh \
> _documentazione/architettura_scheletro.txt
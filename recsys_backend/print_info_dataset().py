excluded_features = set()

def print_info_dataset():

	features_d = []
	features_no = []
	features_m = []

	#	####################################################################	#
	#	ANALISI DEL DATASET

	print("\n\n--- DATASET ---\n\n")

	# Calcolo features uniche dal dataset
	for cat in CATEGORIES:
		filepath = CSV_PATH_MAPPING[cat]
		with open(filepath, newline='', encoding='utf-8') as f:
			next(f)  # salta intestazione
			reader = csv.DictReader(f, fieldnames=['movieId', 'value'])
			# raccogliamo tutte le feature uniche in un set
			f = {row['value'] for row in reader if row['value']}
			features_d.append(len(f))
			print(f"{cat}: {len(f)}")
	
	print("\n\n")

	# Calcolo totale features dal dataset
	total_features = sum(features_d)
	print("Numero totale di feature:", total_features)

	#	####################################################################	#
	#	ANALISI DEL MAPPING (features escluse)

	print("\n\n--- MAPPING (features escluse) ---\n\n")
	print("Numero totale di feature:", len(excluded_features), "\n")

	#	####################################################################	#
	#	ANALISI DEL MAPPING (non filtrato)

	print("\n\n--- MAPPING (non filtrato) ---\n\n")

	# Calcolo features uniche dal mapping
	for cat, f in movies_features_map_no_filter.items():
		features_no.append(len(f))
		print(f"{cat}: {len(f)}")

	print("\n\n")

	# Calcolo totale features dal mapping
	total_features = sum(features_no)
	print("Numero totale di feature:", total_features, "\n")

	#	####################################################################	#
	#	ANALISI DEL MAPPING (minimo 5 film per categoria)

	print("\n\n--- MAPPING ---\n\n")

	# Calcolo features uniche dal mapping
	for cat, f in movies_features_map.items():
		features_m.append(len(f))
		print(f"{cat}: {len(f)}")

	print("\n\n")

	# Calcolo totale features dal mapping
	total_features = sum(features_m)
	print("Numero totale di feature:", total_features, "\n")

	# end
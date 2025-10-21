"""

	tree_print.py \n
	by MARIO GABRIELE CAROFANO

	Questo script permette di stampare la struttura ad albero
	di una directory, escludendo file o cartelle specifiche
	e mostrando opzionalmente i file nascosti.

"""

#	########################################################################	#
#	LIBRERIE

import os
import sys

#	########################################################################	#
#	FUNZIONE PRINCIPALE

def print_tree(
		startpath : str,
		exclude: list | None = None,
		show_hidden : bool = False,
		prefix: str = ""
	) -> None:
	"""Stampa la struttura ad albero di una directory.

	Args:
		startpath (str): Il percorso della directory da stampare.
		exclude (list | None, optional): Un elenco di file o directory da escludere. Defaults to None.
		show_hidden (bool, optional): Se True, mostra anche i file e le directory nascosti. Defaults to False.
		prefix (str, optional): Un prefisso da utilizzare per la stampa. Defaults to "".
	
	Returns:
		None
	"""

	#	####################################################################	#
	#	VERIFICA DEGLI ARGOMENTI
	
	if exclude is None:
		exclude = []

	#	####################################################################	#
	#	RECUPERO E FILTRO DEGLI ELEMENTI DA STAMPARE

	# Ordina la lista degli elementi nella directory.
	items = sorted(os.listdir(startpath))

	# Filtra gli elementi nascosti se show_hidden = False
	if not show_hidden:
		items = [i for i in items if not i.startswith('.')]
	
	# Filtra gli elementi presenti in exclude.
	items = [i for i in items if os.path.relpath(os.path.join(startpath, i)) not in exclude]

	count = len(items)

	#	####################################################################	#
	#	STAMPA RICORSIVA DEGLI ELEMENTI

	for i, item in enumerate(items):
		path = os.path.join(startpath, item)
		connector = "└── " if i == count - 1 else "├── "
		print(prefix + connector + item)

		if os.path.isdir(path):
			new_prefix = prefix + ("    " if i == count - 1 else "│   ")
			print_tree(path, exclude, show_hidden, new_prefix)
	
	# end

#	########################################################################	 #
#	ENTRY POINT

if __name__ == "__main__":

	# Controlla se il numero di argomenti è sufficiente.
	if len(sys.argv) < 2:
		print("Non è stato fornito il numero corretto di argomenti.")
		sys.exit(1)

	start_dir = sys.argv[1]

	# Controlla se il flag --show-hidden è presente.
	show_hidden = False
	args = sys.argv[2:]
	if "--show-hidden" in args:
		show_hidden = True
		args.remove("--show-hidden")

	# Normalizza tutti i percorsi da escludere.
	excludes = [os.path.normpath(path) for path in args] if args else []

	# Stampa la root.
	root_name = os.path.basename(os.path.abspath(start_dir))
	print(f"{root_name}")

	# Avvia la stampa ricorsiva dell'albero.
	print_tree(start_dir, exclude=excludes, show_hidden=show_hidden)

	# end

#	########################################################################### #
#	ESEMPIO DI UTILIZZO

"""
python tree_print.py <directory> [--show-hidden] [file_o_cartelle_da_escludere...]
"""
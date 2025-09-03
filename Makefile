all: simple compare

simple:
	./fragmentation_visualizer.py data/fragmentation_data_simple.json

compare:
	./fragmentation_visualizer.py data/fragmentation_data_simple.json --compare data/fragmentation_data_load.json --labels "A" "B"

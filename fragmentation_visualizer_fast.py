#!/usr/bin/env python3
"""
Fast fragmentation visualizer - optimized for large files.
Processes data efficiently by sampling when needed.
"""
import json
import sys
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import matplotlib.patches as mpatches
from matplotlib.patches import Rectangle
from datetime import datetime
import argparse
from collections import defaultdict

# Import all the visualization functions from the original
from fragmentation_visualizer import (
    get_dot_size, build_counts, get_migrate_type_color,
    get_migration_severity, get_severity_color,
    create_overlaid_compaction_graph, create_overlaid_extfrag_timeline,
    create_combined_migration_heatmap, create_comparison_statistics_table,
    create_single_dashboard, create_single_migration_heatmap,
    create_comparison_dashboard
)

def load_data_fast(filename, max_events=None):
    """Load JSON data quickly, with optional event limiting."""
    print(f"Loading {filename}...")

    try:
        with open(filename, 'r') as f:
            data = json.load(f)

        events = data.get("events", [])
        original_count = len(events)

        # If too many events, sample them
        if max_events and len(events) > max_events:
            print(f"Sampling {max_events} events from {original_count} total...")
            # Take evenly distributed samples
            indices = np.linspace(0, len(events) - 1, max_events, dtype=int)
            events = [events[i] for i in indices]
            data["events"] = events
            data["metadata"]["sampled"] = True
            data["metadata"]["original_count"] = original_count
        else:
            print(f"Processing {original_count} events...")

        return data
    except Exception as e:
        print(f"Error loading {filename}: {e}")
        return {"events": []}

def main():
    parser = argparse.ArgumentParser(
        description="Fast fragmentation analysis with optional comparison"
    )
    parser.add_argument("input_file", help="Primary JSON file")
    parser.add_argument(
        "--compare", help="Secondary JSON file for A/B comparison (optional)"
    )
    parser.add_argument("-o", "--output", help="Output filename")
    parser.add_argument(
        "--labels",
        nargs=2,
        default=["Light Load", "Heavy Load"],
        help="Labels for the two datasets in comparison mode",
    )
    parser.add_argument(
        "--bin", type=float, default=0.5, help="Bin size for event counts"
    )
    parser.add_argument(
        "--max-events", type=int, default=50000,
        help="Maximum events to process (default: 50000, 0 = no limit)"
    )
    args = parser.parse_args()

    # Set max_events
    max_events = args.max_events if args.max_events > 0 else None

    try:
        data_a = load_data_fast(args.input_file, max_events)
        if not data_a.get("events"):
            print(f"Warning: No events found in {args.input_file}")
            if not args.compare:
                print("Cannot create visualization without any events")
                sys.exit(1)
    except Exception as e:
        print(f"Error loading primary data: {e}")
        sys.exit(1)

    if args.compare:
        # Comparison mode
        try:
            data_b = load_data_fast(args.compare, max_events)
            if not data_b.get("events"):
                print(f"Warning: No events found in {args.compare}")
        except Exception as e:
            print(f"Error loading comparison data: {e}")
            sys.exit(1)

        # Only proceed if at least one dataset has events
        if data_a.get("events") or data_b.get("events"):
            out = create_comparison_dashboard(
                data_a,
                data_b,
                args.labels,
                args.output,
                input_files=[args.input_file, args.compare],
            )
            print(f"Comparison saved: {out}")
        else:
            print("Error: No valid events found in either dataset")
            sys.exit(1)
    else:
        # Single file mode
        if data_a.get("events"):
            out = create_single_dashboard(
                data_a, args.output, args.bin, input_filename=args.input_file
            )
            print(f"Analysis saved: {out}")
        else:
            print("Error: No valid events to visualize")
            sys.exit(1)


if __name__ == "__main__":
    main()
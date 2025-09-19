#!/usr/bin/env python3
"""Test if visualizer can load files quickly"""
import sys
import json
import time

def test_load(filename):
    print(f"Loading {filename}...")
    start = time.time()

    try:
        with open(filename, 'r') as f:
            # Just read first 1000 chars to test
            data = f.read(1000)
            print(f"First 100 chars: {data[:100]}")

        # Now try full JSON load
        with open(filename, 'r') as f:
            full_data = json.load(f)
            events = full_data.get('events', [])
            print(f"Loaded in {time.time() - start:.2f}s")
            print(f"Total events: {len(events)}")

            # Just process first 100 events as a test
            if len(events) > 100:
                print("Limiting to first 100 events for testing...")
                full_data['events'] = events[:100]

            return full_data
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    if len(sys.argv) > 1:
        data = test_load(sys.argv[1])
        if data:
            print("Success! File can be loaded.")
    else:
        print("Usage: test_visualizer.py <json_file>")
"""Sum one numeric column of a CSV file."""
import argparse
import csv
import sys


def column_total(rows, column):
    total = 0.0
    for row in rows:
        value = row.get(column, "").strip()
        if value:
            total += float(value)
    return total


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path")
    parser.add_argument("column")
    args = parser.parse_args(argv)
    with open(args.path, newline="") as handle:
        total = column_total(csv.DictReader(handle), args.column)
    print(f"{args.column}: {total:.2f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

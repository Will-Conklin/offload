#!/bin/bash
# Coverage Threshold Enforcement Script for iOS
# Usage: check_coverage.sh <coverage_file> <threshold_percentage>

set -e

COVERAGE_FILE=$1
THRESHOLD=$2

if [ -z "$COVERAGE_FILE" ] || [ -z "$THRESHOLD" ]; then
    echo "Usage: $0 <coverage_file> <threshold_percentage>"
    exit 1
fi

if [ ! -f "$COVERAGE_FILE" ]; then
    echo "❌ Coverage file not found: $COVERAGE_FILE"
    exit 1
fi

# Extract the total coverage percentage from xccov output
# Expected format: "Offload.app -> 75.00%"
COVERAGE=$(grep -E "\.app.*->" "$COVERAGE_FILE" | grep -oE "[0-9]+\.[0-9]+" | head -1)

if [ -z "$COVERAGE" ]; then
    echo "❌ Could not extract coverage percentage from $COVERAGE_FILE"
    echo "File contents:"
    cat "$COVERAGE_FILE"
    exit 1
fi

echo "📊 Code Coverage: ${COVERAGE}%"
echo "🎯 Threshold: ${THRESHOLD}%"

# Use bc for floating point comparison
MEETS_THRESHOLD=$(echo "$COVERAGE >= $THRESHOLD" | bc -l)

if [ "$MEETS_THRESHOLD" -eq 1 ]; then
    echo "✅ Coverage check passed!"
    exit 0
else
    echo "❌ Coverage check failed!"
    echo "Current coverage (${COVERAGE}%) is below the required threshold (${THRESHOLD}%)"
    exit 1
fi

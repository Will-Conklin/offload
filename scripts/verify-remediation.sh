#!/bin/bash
# Remediation Verification Script
# Checks for issues identified in the adversarial review

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Offload Remediation Verification Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

ISSUES_FOUND=0
CRITICAL_ISSUES=0
HIGH_ISSUES=0
MEDIUM_ISSUES=0

# Function to report issue
report_issue() {
    local severity=$1
    local title=$2
    local count=$3

    case $severity in
        CRITICAL)
            echo -e "${RED}⚠️  CRITICAL: $title${NC}"
            ((CRITICAL_ISSUES++))
            ;;
        HIGH)
            echo -e "${YELLOW}⚠  HIGH: $title${NC}"
            ((HIGH_ISSUES++))
            ;;
        MEDIUM)
            echo -e "${YELLOW}•  MEDIUM: $title${NC}"
            ((MEDIUM_ISSUES++))
            ;;
    esac

    if [ -n "$count" ]; then
        echo -e "   Found: ${count} instances"
    fi
    ((ISSUES_FOUND++))
    echo ""
}

# Function to report success
report_success() {
    local title=$1
    echo -e "${GREEN}✓ $title${NC}"
}

echo -e "${BLUE}## PHASE 1: CRITICAL ISSUES${NC}"
echo ""

# Check 1: Silent Error Suppression (try?)
echo "Checking for silent error suppression (try?)..."
TRY_OPTIONAL_COUNT=$(grep -r "try?" ios/Offload --include="*.swift" 2>/dev/null | grep -v "Tests" | wc -l)
if [ "$TRY_OPTIONAL_COUNT" -gt 0 ]; then
    report_issue "CRITICAL" "Silent error suppression with try?" "$TRY_OPTIONAL_COUNT"
    echo "   Files affected:"
    grep -r "try?" ios/Offload --include="*.swift" 2>/dev/null | grep -v "Tests" | cut -d: -f1 | sort -u | sed 's/^/   - /'
    echo ""
else
    report_success "No silent error suppression found"
fi

# Check 2: Force Unwraps on URL
echo "Checking for force unwraps on URL construction..."
URL_FORCE_UNWRAP_COUNT=$(grep -r "URL(string:.*!)\\|URL(string.*!)\\|url!" ios/Offload --include="*.swift" 2>/dev/null | grep -v "Tests" | wc -l)
if [ "$URL_FORCE_UNWRAP_COUNT" -gt 0 ]; then
    report_issue "CRITICAL" "Force unwraps on URL construction" "$URL_FORCE_UNWRAP_COUNT"
    echo "   Files affected:"
    grep -r "URL(string:.*!)\\|URL(string.*!)" ios/Offload --include="*.swift" 2>/dev/null | grep -v "Tests" | cut -d: -f1 | sort -u | sed 's/^/   - /'
    echo ""
else
    report_success "No force unwraps on URL construction"
fi

# Check 3: N+1 Query Pattern
echo "Checking for N+1 query pattern (fetchAll then filter)..."
N_PLUS_ONE_COUNT=$(grep -r "fetchAll()" ios/Offload/Data/Repositories --include="*.swift" 2>/dev/null | wc -l)
if [ "$N_PLUS_ONE_COUNT" -gt 5 ]; then
    report_issue "CRITICAL" "Potential N+1 query pattern" "$N_PLUS_ONE_COUNT uses of fetchAll()"
    echo "   Repository files:"
    grep -r "fetchAll()" ios/Offload/Data/Repositories --include="*.swift" 2>/dev/null | cut -d: -f1 | sort -u | sed 's/^/   - /'
    echo ""
else
    report_success "Limited use of fetchAll() pattern"
fi

# Check 4: Race condition in InboxView (specific pattern)
echo "Checking for concurrent Task creation in loops..."
CONCURRENT_TASK_PATTERN=$(grep -A 5 "for.*in.*offsets\\|for.*in.*indices" ios/Offload/Features --include="*.swift" 2>/dev/null | grep "_Concurrency.Task\\|Task {" | wc -l)
if [ "$CONCURRENT_TASK_PATTERN" -gt 0 ]; then
    report_issue "CRITICAL" "Potential concurrent Task creation in loops" "$CONCURRENT_TASK_PATTERN"
    echo "   Check these files manually:"
    grep -r "for.*in.*offsets\\|for.*in.*indices" ios/Offload/Features --include="*.swift" 2>/dev/null | cut -d: -f1 | sort -u | sed 's/^/   - /'
    echo ""
else
    report_success "No obvious concurrent Task patterns in loops"
fi

# Check 5: Task.isCancelled static usage
echo "Checking for incorrect Task.isCancelled usage..."
TASK_CANCELLED_STATIC=$(grep -r "_Concurrency.Task.isCancelled\\|Task.isCancelled" ios/Offload --include="*.swift" 2>/dev/null | grep -v "guard !Task.isCancelled" | wc -l)
if [ "$TASK_CANCELLED_STATIC" -gt 0 ]; then
    report_issue "HIGH" "Potential incorrect Task.isCancelled usage" "$TASK_CANCELLED_STATIC"
    grep -r "_Concurrency.Task.isCancelled\\|Task.isCancelled" ios/Offload --include="*.swift" 2>/dev/null | sed 's/^/   /'
    echo ""
else
    report_success "Task.isCancelled used correctly"
fi

# Check 6: orphaned UUID fields (acceptedSuggestionId)
echo "Checking for orphaned UUID foreign keys..."
ORPHANED_ID_COUNT=$(grep -r "SuggestionId: UUID\\|suggestionId: UUID\\|CategoryId: UUID" ios/Offload/Domain/Models --include="*.swift" 2>/dev/null | grep -v "@Relationship" | wc -l)
if [ "$ORPHANED_ID_COUNT" -gt 0 ]; then
    report_issue "CRITICAL" "Orphaned UUID foreign keys (not @Relationship)" "$ORPHANED_ID_COUNT"
    grep -r "SuggestionId: UUID\\|suggestionId: UUID" ios/Offload/Domain/Models --include="*.swift" 2>/dev/null | sed 's/^/   /'
    echo ""
else
    report_success "No orphaned UUID foreign keys found"
fi

# Check 7: Missing @Environment(\.colorScheme) in views using Theme.Colors
echo "Checking for Theme.Colors usage without colorScheme..."
THEME_COLOR_FILES=$(grep -r "Theme\.Colors\." ios/Offload/Features ios/Offload/DesignSystem --include="*.swift" 2>/dev/null | cut -d: -f1 | sort -u)
MISSING_COLORSCHEME=0
for file in $THEME_COLOR_FILES; do
    if ! grep -q "@Environment(\\.colorScheme)" "$file"; then
        if [ $MISSING_COLORSCHEME -eq 0 ]; then
            echo -e "${YELLOW}Files using Theme.Colors without @Environment(\.colorScheme):${NC}"
        fi
        echo "   - $file"
        ((MISSING_COLORSCHEME++))
    fi
done

if [ "$MISSING_COLORSCHEME" -gt 0 ]; then
    report_issue "HIGH" "Views using Theme.Colors without colorScheme environment" "$MISSING_COLORSCHEME files"
else
    report_success "All Theme.Colors usages have colorScheme environment"
fi

echo ""
echo -e "${BLUE}## PHASE 2: HIGH PRIORITY ISSUES${NC}"
echo ""

# Check 8: Relationships without @Relationship annotation
echo "Checking for potential relationships without @Relationship..."
POTENTIAL_RELATIONSHIPS=$(grep -r "var category: Category\\|var plan: Plan\\|var list: List" ios/Offload/Domain/Models --include="*.swift" 2>/dev/null | grep -v "@Relationship" | wc -l)
if [ "$POTENTIAL_RELATIONSHIPS" -gt 0 ]; then
    report_issue "HIGH" "Potential relationships without @Relationship" "$POTENTIAL_RELATIONSHIPS"
    grep -r "var category: Category\\|var plan: Plan\\|var list: List" ios/Offload/Domain/Models --include="*.swift" 2>/dev/null | grep -v "@Relationship" | sed 's/^/   /'
    echo ""
else
    report_success "All relationships properly annotated"
fi

# Check 9: Index access on computed properties
echo "Checking for index access on computed properties..."
COMPUTED_INDEX_ACCESS=$(grep -A 3 "var.*:.*\[.*\] {" ios/Offload/Features --include="*.swift" 2>/dev/null | grep "\[index\]" | wc -l)
if [ "$COMPUTED_INDEX_ACCESS" -gt 0 ]; then
    report_issue "HIGH" "Potential index access on computed properties" "Found pattern"
    echo "   Review these files manually for array[index] on computed properties"
else
    report_success "No obvious index access on computed properties"
fi

# Check 10: Debug print statements in production code
echo "Checking for debug print statements..."
PRINT_STATEMENTS=$(grep -r "print(" ios/Offload --include="*.swift" 2>/dev/null | grep -v "Tests\\|//.*print(" | wc -l)
if [ "$PRINT_STATEMENTS" -gt 0 ]; then
    report_issue "MEDIUM" "Debug print statements in production code" "$PRINT_STATEMENTS"
    echo "   Files affected:"
    grep -r "print(" ios/Offload --include="*.swift" 2>/dev/null | grep -v "Tests\\|//.*print(" | cut -d: -f1 | sort -u | sed 's/^/   - /'
    echo ""
else
    report_success "No debug print statements found"
fi

echo ""
echo -e "${BLUE}## CODE QUALITY CHECKS${NC}"
echo ""

# Check 11: TODO count
echo "Checking TODO count..."
TODO_COUNT=$(grep -r "TODO\\|FIXME\\|HACK" ios/Offload --include="*.swift" 2>/dev/null | wc -l)
if [ "$TODO_COUNT" -gt 20 ]; then
    report_issue "MEDIUM" "High number of TODOs/FIXMEs" "$TODO_COUNT"
else
    echo -e "${GREEN}✓ TODO count acceptable: $TODO_COUNT${NC}"
fi

# Check 12: Magic strings for URLs
echo "Checking for hardcoded URL strings..."
HARDCODED_URLS=$(grep -r '"https://\\|"http://' ios/Offload --include="*.swift" 2>/dev/null | grep -v "Tests\\|//" | wc -l)
if [ "$HARDCODED_URLS" -gt 0 ]; then
    report_issue "MEDIUM" "Hardcoded URL strings (should be constants)" "$HARDCODED_URLS"
else
    report_success "No hardcoded URL strings found"
fi

# Check 13: Input validation presence
echo "Checking for input validation patterns..."
VALIDATION_COUNT=$(grep -r "guard.*isEmpty\\|guard.*count\\|guard.*URL(" ios/Offload/Features --include="*.swift" 2>/dev/null | wc -l)
echo -e "${BLUE}ℹ  Found $VALIDATION_COUNT validation patterns (informational)${NC}"

# Check 14: Force unwraps in general
echo "Checking for force unwraps in general..."
FORCE_UNWRAP_COUNT=$(grep -r "!" ios/Offload --include="*.swift" 2>/dev/null | grep -v "Tests\\|!=\\|//\\|import" | grep -v "optional" | wc -l)
if [ "$FORCE_UNWRAP_COUNT" -gt 50 ]; then
    echo -e "${YELLOW}⚠  Found $FORCE_UNWRAP_COUNT potential force unwraps (review manually)${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "$CRITICAL_ISSUES" -eq 0 ] && [ "$HIGH_ISSUES" -eq 0 ]; then
    echo -e "${GREEN}✓ No critical or high priority issues found!${NC}"
    echo ""
    if [ "$MEDIUM_ISSUES" -gt 0 ]; then
        echo -e "${YELLOW}Medium priority issues: $MEDIUM_ISSUES${NC}"
    fi
    echo ""
    echo -e "${GREEN}Production readiness: IMPROVED${NC}"
    exit 0
else
    echo -e "${RED}Issues found:${NC}"
    echo -e "  ${RED}Critical: $CRITICAL_ISSUES${NC}"
    echo -e "  ${YELLOW}High: $HIGH_ISSUES${NC}"
    echo -e "  ${YELLOW}Medium: $MEDIUM_ISSUES${NC}"
    echo ""
    echo -e "${RED}Production readiness: NOT READY${NC}"
    echo ""
    echo "Review the remediation plan at: docs/plans/remediation-plan.md"
    echo "Track progress at: docs/plans/remediation-tracking.md"
    exit 1
fi

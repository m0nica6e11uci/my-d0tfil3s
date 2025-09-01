for f in *.txt; do
    cat "$f"
    echo ""
done > wordlistall.txt
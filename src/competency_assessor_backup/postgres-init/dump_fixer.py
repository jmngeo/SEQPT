import sys

def filter_sql_file(input_file, output_file):
    # List of patterns that, if a line ends with any of them, the line is skipped.
    patterns_to_remove = [
        "OWNER TO adminderik;",
        "TO azure_pg_admin;"
    ]
    
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', encoding='utf-8') as outfile:
        for line in infile:
            # Remove trailing whitespace for accurate comparison
            stripped_line = line.rstrip()
            if any(stripped_line.endswith(pattern) for pattern in patterns_to_remove):
                continue  # Skip lines that match any unwanted pattern
            outfile.write(line)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python filter_sql.py <input_sql_file> <output_sql_file>")
        sys.exit(1)
        
    input_sql = sys.argv[1]
    output_sql = sys.argv[2]
    filter_sql_file(input_sql, output_sql)
    print(f"Filtered SQL file has been saved as {output_sql}")

import json
import re

# Load the JSON file
with open("job_description_systems_engineer_sampled.json", "r", encoding="utf-8") as file:
    data = json.load(file)

# Clean the "description" field
if "description" in data:
    # Decode Unicode and remove special characters
    clean_text = re.sub(r'[^\x20-\x7E]', '', data["description"])
    data["description"] = clean_text

# Save the cleaned JSON back
with open("job_description_systems_engineer_sampled.json_cleaned_file.json", "w", encoding="utf-8") as file:
    json.dump(data, file, ensure_ascii=False, indent=4)
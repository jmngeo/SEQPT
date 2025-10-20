from app import create_app

app = create_app()

print("=== All registered routes ===")
for rule in app.url_map.iter_rules():
    print(f"{rule.endpoint}: {rule.rule} [{', '.join(rule.methods)}]")

print("\n=== Searching for register routes ===")
for rule in app.url_map.iter_rules():
    if 'register' in rule.rule:
        print(f"FOUND: {rule.endpoint}: {rule.rule} [{', '.join(rule.methods - {'HEAD', 'OPTIONS'})}]")

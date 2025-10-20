from app import create_app

app = create_app()

print("\nAll registered routes:")
print("=" * 80)
for rule in app.url_map.iter_rules():
    methods = ','.join(sorted(rule.methods - {'HEAD', 'OPTIONS'}))
    print(f"{rule.endpoint:40s} {rule.rule:40s} [{methods}]")
print("=" * 80)

print("\nRoutes containing 'register':")
for rule in app.url_map.iter_rules():
    if 'register' in rule.rule.lower():
        methods = ','.join(sorted(rule.methods - {'HEAD', 'OPTIONS'}))
        print(f"{rule.endpoint:40s} {rule.rule:40s} [{methods}]")

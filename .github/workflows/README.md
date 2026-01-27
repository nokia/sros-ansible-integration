# Testing

## Test Matrix

Edit `../test-matrix.yml` to control which versions are tested:

```yaml
test_matrix:
  python_versions: ['3.13', '3.14']
  sros_versions: ['25.7.R2', '25.10.R1']
  ansible_versions: ['2.17', '2.18']
```

All combinations are tested automatically (2 × 2 × 2 = 8 jobs).

## GitHub Actions

The `ci.yml` workflow:
1. Reads `test-matrix.yml`
2. Generates all version combinations
3. Runs tests in parallel with containerlab
4. Reports results in PR checks

## External CI

External CI systems (like GitLab) also read `test-matrix.yml` for consistency. One test matrix, multiple CI systems.

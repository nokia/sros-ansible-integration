# Testing Infrastructure

This directory contains the test automation for the SR OS Ansible Collection.

## Test Files

- `ci.yml` - GitHub Actions workflow
- `../test-matrix.yml` - Test matrix configuration (single source of truth)

## Test Matrix Configuration

The `test-matrix.yml` file defines which versions are tested. All combinations are automatically tested:
- Python versions (3.13, 3.14)
- SR OS versions (25.7.R2, 25.10.R1)  
- Ansible versions (2.17, 2.18)

To add or remove test versions, simply edit the lists in `../test-matrix.yml`. Both GitHub Actions and external CI systems read from this single source of truth.

## GitHub Actions Workflow

The `ci.yml` workflow:
1. Reads the test matrix from `test-matrix.yml`
2. Generates all version combinations automatically
3. Runs tests for each combination in parallel
4. Uses containerlab to deploy SR OS test topology
5. Reports results in PR checks

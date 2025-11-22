#!/usr/bin/env bash
set -euo pipefail

# tests/run-tests.sh
# Lightweight Terraform module test harness for the local `tests/testmodule` example.
#
# Behavior:
# - For each test case it runs `terraform init` and `terraform apply` in `tests/testmodule`
#   with the provided variables, then reads the module outputs and asserts expectations.
# - Exits with non-zero status if any test fails.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$ROOT_DIR/tests/testmodule"

TF_CMD=${TF_CMD:-terraform}

if ! command -v "$TF_CMD" >/dev/null 2>&1; then
	echo "Error: terraform not found in PATH. Install Terraform or set TF_CMD to the binary path." >&2
	exit 2
fi

# Helper: run terraform init once per test directory with backend disabled (local tests)
tf_init() {
	(cd "$TEST_DIR" && $TF_CMD init -input=false -backend=false)
}

# Helper: get terraform output as raw string. Prefers `terraform output -json` + jq if available,
# otherwise falls back to `terraform output -raw` or regular `terraform output` parsing.
get_tf_output() {
	local name=$1
	(cd "$TEST_DIR" && 
		if command -v jq >/dev/null 2>&1; then
			$TF_CMD output -json | jq -r ".${name}.value"
		else
			# try -raw (modern terraform) otherwise plain output and strip quotes
			if $TF_CMD output -help 2>&1 | grep -q -- "-raw"; then
				$TF_CMD output -raw "$name"
			else
				$TF_CMD output "$name" | sed -E 's/^\s*"?(.+)"?\s*$/\1/'
			fi
		fi
	)
}

TEST_CASES_FILE=${TEST_CASES_FILE:-"$ROOT_DIR/tests/test-cases.json"}

if ! command -v jq >/dev/null 2>&1; then
	echo "Error: jq is required to read $TEST_CASES_FILE. Install jq or set TEST_CASES_FILE to a different format." >&2
	exit 2
fi

if [[ ! -f "$TEST_CASES_FILE" ]]; then
	echo "Error: test cases file not found: $TEST_CASES_FILE" >&2
	exit 2
fi

total_tests=$(jq 'length' "$TEST_CASES_FILE")
pass_count=0
fail_count=0

echo "Running $total_tests terraform module tests from $TEST_CASES_FILE in $TEST_DIR"

while IFS= read -r case_json; do
	test_id=$(jq -r '.id // "unnamed"' <<<"$case_json")
	org=$(jq -r '.organization // empty' <<<"$case_json")
	env=$(jq -r '.environment // empty' <<<"$case_json")
	location=$(jq -r '.location // empty' <<<"$case_json")
	# support either expected.location_abbreviation or top-level expected string for compat
	expected=$(jq -r '.expected.location_abbreviation // .expected // empty' <<<"$case_json")

	echo ""
	echo "=== Test: $test_id ==="
	echo "vars: organization=$org, environment=$env, location=$location"

		# Prepare a temporary JSON var file containing only the variables defined in the test case.
		# We write a .tfvars.json file so Terraform can read typed values (lists/maps) directly.
		tfvars_file="$TEST_DIR/.auto_test_vars.tfvars.json"
		# Build a JSON object with only the allowed test variables if they exist in the case JSON.
		echo "$case_json" | jq -c '{organization: .organization, environment: .environment, location: .location, name_suffix: .name_suffix, location_abbreviations: .location_abbreviations} | with_entries(select(.value != null))' >"$tfvars_file"

	# Initialize (no backend) and apply. Capture logs so we can show errors on failure.
	log_file=$(mktemp -t tf-test-logs.XXXXXX)

	if ! (cd "$TEST_DIR" && $TF_CMD init -input=false -backend=false) >"$log_file" 2>&1; then
		echo "terraform init failed for test $test_id" >&2
		echo "--- terraform init output ---" >&2
		sed -n '1,200p' "$log_file" >&2 || true
		echo "--- end init output ---" >&2
		((fail_count++))
		rm -f "$tfvars_file" "$log_file"
		continue
	fi

	if ! (cd "$TEST_DIR" && $TF_CMD apply -input=false -auto-approve -var-file="$tfvars_file") >"$log_file" 2>&1; then
		echo "terraform apply failed for test $test_id" >&2
		echo "--- terraform apply output ---" >&2
		sed -n '1,200p' "$log_file" >&2 || true
		echo "--- end apply output ---" >&2
		((fail_count++))
		rm -f "$tfvars_file" "$log_file"
		continue
	fi

	# Evaluate expected assertions. Support multiple expected keys.
	# If .expected is an object, assert each key (the key should map to a terraform output name).
	# If .expected is a string (legacy), assert it against location_abbreviation.
	if jq -e '.expected | type == "object"' >/dev/null 2>&1 <<<"$case_json"; then
		expected_keys=$(jq -r '.expected | keys[]' <<<"$case_json")
	else
		# legacy: single expected string -> compare against location_abbreviation
		expected_keys="location_abbreviation"
		# normalize into an object for easier extraction below
		case_json=$(jq ". + {expected: {location_abbreviation: .expected}}" <<<"$case_json")
	fi

	test_ok=1
	for key in $expected_keys; do
			# expected value (raw string)
			expected_val=$(jq -r ".expected[\"$key\"]" <<<"$case_json")

			# Capture the helper output and its exit status so we can surface errors in CI logs
			actual_val=$(get_tf_output "$key" 2>&1)
			actual_status=$?

			if [[ $actual_status -ne 0 ]]; then
				# Show the helper error and the terraform apply log to help diagnostics in CI
				echo "FAIL: $key expected=$(jq -c ".expected[\"$key\"]" <<<"$case_json") but terraform output errored"
				echo "  terraform output error: $(printf '%s' "$actual_val")"
				echo "  --- terraform apply log (first 200 lines) ---"
				sed -n '1,200p' "$log_file" || true
				echo "  --- end apply log ---"
				echo "  (diagnose: cd $TEST_DIR && $TF_CMD output -json | jq .\"$key\")"
				test_ok=0
			else
				if [[ "$actual_val" == "$expected_val" ]]; then
					echo "PASS: $key == $expected_val"
				else
					echo "FAIL: $key expected=$(jq -c ".expected[\"$key\"]" <<<"$case_json") but got=$(printf '%s' \"$actual_val\")"
					echo "  (diagnose: cd $TEST_DIR && $TF_CMD output -json | jq .\"$key\")"
					# Also include the apply log to help CI debugging when outputs are empty
					echo "  --- terraform apply log (first 200 lines) ---"
					sed -n '1,200p' "$log_file" || true
					echo "  --- end apply log ---"
					test_ok=0
				fi
			fi
	done

	# Try to destroy any created resources to keep workspace clean (no-op in many modules)
	if (cd "$TEST_DIR" && $TF_CMD destroy -auto-approve -var-file="$tfvars_file") >"$log_file" 2>&1; then
		: # destroyed
	else
		# show destroy errors (non-fatal)
		echo "terraform destroy (cleanup) had errors for test $test_id" >&2
		echo "--- terraform destroy output ---" >&2
		sed -n '1,200p' "$log_file" >&2 || true
		echo "--- end destroy output ---" >&2
	fi

	# Cleanup tfvars and logs
	rm -f "$tfvars_file" "$log_file"

	if [[ $test_ok -eq 1 ]]; then
		((pass_count++))
	else
		((fail_count++))
	fi

done < <(jq -c '.[]' "$TEST_CASES_FILE")

echo ""
echo "Summary: $pass_count passed, $fail_count failed"

if [[ $fail_count -gt 0 ]]; then
	exit 1
fi

exit 0


import os
import subprocess
import argparse

TEST_DIR = "./tests/"
REFERENCE_DIR = "./tests/references/"

UPDATE_REFERENCES = False

def run_tests():
    for test_files in os.listdir(TEST_DIR):
        if test_files.endswith(".f90"):
            print(f"Running lexer on {test_files}...")
            result = subprocess.run(["./lexer", os.path.join(TEST_DIR, test_files)], capture_output=True, text=True)
            output = result.stdout
            reference_file = os.path.join(REFERENCE_DIR, test_files.replace(".f90", ".tokens"))
            if UPDATE_REFERENCES:
                with open(reference_file, "w") as ref:
                    ref.write(output)
                print(f"Reference output for {test_files} created/updated.")
            else:
                if os.path.exists(reference_file):
                    with open(reference_file, "r") as ref:
                        reference_output = ref.read()
                    if output == reference_output:
                        print(f"Test {test_files} passed!")
                    else:
                        print(f"Test {test_files} failed! Output does not match reference.")
                        # Throw an Exception and stop checking further tests
                        raise Exception(f"Test {test_files} failed! Output does not match reference.")
                else:
                    print(f"No reference output found for {test_files}. Please create {reference_file} with expected tokens.")
                    return

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run lexer tests and compare against reference outputs.")
    parser.add_argument("--update-references", action="store_true", help="Update reference outputs with current lexer results.")
    args = parser.parse_args()
    UPDATE_REFERENCES = args.update_references
    run_tests()
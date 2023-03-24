# Define the default target
.DEFAULT_GOAL := test

# Define variables
TEST_DIR := library
TEST_FILES := $(wildcard $(TEST_DIR)/*_test.sh)
BATS := bats

# Define the test target
test:
		@$(BATS) $(TEST_FILES)

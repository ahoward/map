# Feature Specification: Conditional Ordered Map Module

**Feature Branch**: `001-ordered-map-module`
**Created**: 2025-11-10
**Status**: Draft
**Input**: User description: "we want to support all features of map in newer rubies, which have ordered maps.  we wish to extact the 'ordered' parts of map as a module, and only include it in Map for older/non-hash-ordered, rubies.  we want a KISS way to test this."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Legacy Ruby Support (Priority: P1)

When developers use Map in Ruby 1.8.x (or other non-ordered hash implementations), they must receive the same ordered hash behavior that Map has always provided, with keys tracked in insertion order via the `@keys` array mechanism.

**Why this priority**: This is the core value proposition - maintaining backward compatibility for users on older Ruby versions without breaking existing functionality. Without this, Map would lose its "works in all rubies" promise.

**Independent Test**: Can be fully tested by running the existing test suite on Ruby 1.8.x or similar non-ordered hash implementations and verifying that all ordering-related tests pass.

**Acceptance Scenarios**:

1. **Given** Map running on Ruby 1.8.x, **When** a user creates a map with `Map[:a, 1, :b, 2, :c, 3]`, **Then** calling `keys` returns `['a', 'b', 'c']` in insertion order
2. **Given** Map running on Ruby 1.8.x, **When** a user iterates with `each`, **Then** key-value pairs are yielded in insertion order
3. **Given** Map running on Ruby 1.8.x, **When** a user calls `first` and `last`, **Then** they return the first and last inserted key-value pairs respectively

---

### User Story 2 - Modern Ruby Optimization (Priority: P2)

When developers use Map in Ruby 1.9+ (where Hash is ordered by default), they must benefit from native Hash ordering performance without the overhead of maintaining a redundant `@keys` array.

**Why this priority**: This improves performance and reduces memory overhead for the majority of current users, but doesn't break functionality since Ruby 1.9+ hashes are already ordered. This is secondary to maintaining backward compatibility.

**Independent Test**: Can be fully tested by running the test suite on Ruby 1.9+ and verifying that: (1) all tests pass, (2) no `@keys` instance variable is present in Map instances, and (3) ordering behavior matches expected results.

**Acceptance Scenarios**:

1. **Given** Map running on Ruby 1.9+, **When** a user creates a map with `Map[:a, 1, :b, 2, :c, 3]`, **Then** calling `keys` returns `['a', 'b', 'c']` in insertion order without using `@keys` array
2. **Given** Map running on Ruby 1.9+, **When** a user inspects a Map instance, **Then** no `@keys` instance variable is present
3. **Given** Map running on Ruby 1.9+, **When** a user calls ordering-dependent methods (`first`, `last`, `values`, `each`), **Then** they work correctly using native Hash ordering

---

### User Story 3 - Simple Cross-Version Testing (Priority: P3)

When developers or CI systems need to verify Map behavior across Ruby versions, they must have a simple, KISS (Keep It Simple, Stupid) way to run tests that validate both code paths (with and without the ordered module).

**Why this priority**: Testing is important but can be implemented after the core functionality works. It's a development/maintenance concern rather than end-user functionality.

**Independent Test**: Can be fully tested by running a test command that simulates both Ruby version scenarios and verifying that it produces clear pass/fail results for both paths.

**Acceptance Scenarios**:

1. **Given** a test runner configuration, **When** tests are executed, **Then** both "ordered module included" and "ordered module excluded" scenarios are tested
2. **Given** test results, **When** reviewing output, **Then** it's clear which tests ran under which configuration (ordered module on/off)
3. **Given** CI environment, **When** tests run, **Then** failures in either path are clearly reported with context about which Ruby version scenario failed

---

### Edge Cases

- What happens when the Ruby version detection is ambiguous (e.g., alternative Ruby implementations like JRuby, Rubinius)?
- How does the system handle Ruby versions with the ordering backport?
- What happens during Marshal load/dump of Maps created on different Ruby versions?
- How does the module inclusion affect class inheritance and subclassing of Map?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST extract all ordering-related code (using `@keys` array) into a separate module
- **FR-002**: System MUST conditionally include the ordering module only when Ruby Hash is not ordered by default (Ruby < 1.9)
- **FR-003**: System MUST detect Ruby version at load time to determine whether Hash is ordered
- **FR-004**: System MUST maintain identical external API behavior regardless of whether ordering module is included
- **FR-005**: System MUST preserve Marshal compatibility for existing Map instances
- **FR-006**: System MUST ensure all existing tests pass on both old and new Ruby versions without modification
- **FR-007**: System MUST provide ordering module methods that override default Hash methods when included (e.g., `keys`, `values`, `each`, `first`, `last`, `delete`, `[]=`)
- **FR-008**: Test framework MUST provide simple mechanism to test both code paths (with/without ordering module)
- **FR-009**: System MUST handle `@keys` array initialization in `allocate` method conditionally based on Ruby version

### Key Entities *(include if feature involves data)*

- **OrderingModule**: A module containing all `@keys` array-dependent methods that maintain insertion order manually
- **Map Class**: The main class that conditionally includes OrderingModule based on Ruby version detection
- **Ruby Version Detector**: Logic that determines if native Hash ordering is available

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All existing Map tests pass without modification on both Ruby 1.8.x and Ruby 1.9+ versions
- **SC-002**: Map instances on Ruby 1.9+ do not contain `@keys` instance variable (verified via instance_variables inspection)
- **SC-003**: Map maintains insertion order correctly in both Ruby version scenarios (100% of ordering-dependent operations return correct results)
- **SC-004**: Developers can run a single test command that validates both code paths with clear pass/fail output
- **SC-005**: Memory footprint per Map instance is reduced on Ruby 1.9+ due to absence of redundant `@keys` array
- **SC-006**: Test execution time remains similar or improves (no more than 5% regression) across both Ruby versions

### Assumptions

- Ruby 1.9.0 is the cutoff version where Hash became ordered by default
- The existing test suite adequately covers all ordering-dependent behavior
- Marshal serialization format compatibility is acceptable to break across Ruby versions (Map objects serialized on old Ruby may not deserialize correctly on new Ruby if format changes)
- Alternative Ruby implementations (JRuby, Rubinius, TruffleRuby) follow the same ordering behavior as MRI for their respective version numbers
- The KISS testing approach means a simple flag or environment variable to force inclusion/exclusion of the ordering module, rather than complex test matrix infrastructure

### Dependencies

- Access to multiple Ruby version environments for testing (Ruby 1.8.x and Ruby 1.9+)
- Existing test suite must be comprehensive enough to validate ordering behavior
- No breaking changes to public API (all existing Map users' code must continue to work)

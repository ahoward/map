# Tasks: Conditional Ordered Map Module

**Input**: Design documents from `/specs/001-ordered-map-module/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: No explicit TDD requirement in spec - using existing test suite for validation

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Ruby gem structure: `lib/` for source, `test/` for tests at repository root.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare development environment and understand current codebase

- [x] T001 Read and understand existing Map implementation in lib/map.rb
- [x] T002 Identify all 11 ordering-dependent methods that use `@keys` array in lib/map.rb
- [x] T003 [P] Document current `@keys` array usage patterns and synchronization points
- [x] T004 [P] Run existing test suite to establish baseline (rake test)

**Checkpoint**: Understanding of current implementation complete

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core module structure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create new file lib/map/ordering.rb with module structure skeleton
- [x] T006 Define Map::Ordering module with proper namespace in lib/map/ordering.rb
- [x] T007 Implement module self.included hook for class method injection in lib/map/ordering.rb
- [x] T008 Add conditional require and include logic in lib/map.rb (RUBY_VERSION < '1.9' || ENV['MAP_FORCE_ORDERING'])

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Legacy Ruby Support (Priority: P1) 🎯 MVP

**Goal**: Extract all ordering-related code to Map::Ordering module so Ruby < 1.9 maintains insertion order via `@keys` array

**Independent Test**: Run tests with `MAP_FORCE_ORDERING=1` to simulate Ruby < 1.9 behavior, verify all ordering tests pass and `@keys` variable exists

### Implementation for User Story 1

- [x] T009 [P] [US1] Move Map.allocate class method to Map::Ordering module (initializes `@keys = []`) in lib/map/ordering.rb
- [x] T010 [P] [US1] Move keys instance method to Map::Ordering module (returns `@keys`) in lib/map/ordering.rb
- [x] T011 [P] [US1] Move []= (store) method to Map::Ordering module (tracks keys in `@keys` array) in lib/map/ordering.rb
- [x] T012 [P] [US1] Move values method to Map::Ordering module (iterates `@keys` to build array) in lib/map/ordering.rb
- [x] T013 [P] [US1] Move first method to Map::Ordering module (uses `@keys.first`) in lib/map/ordering.rb
- [x] T014 [P] [US1] Move last method to Map::Ordering module (uses `@keys.last`) in lib/map/ordering.rb
- [x] T015 [P] [US1] Move each/each_pair method to Map::Ordering module (iterates `@keys`) in lib/map/ordering.rb
- [x] T016 [P] [US1] Move each_key method to Map::Ordering module (iterates `@keys`) in lib/map/ordering.rb
- [x] T017 [P] [US1] Move each_value method to Map::Ordering module (iterates `@keys` to access values) in lib/map/ordering.rb
- [x] T018 [P] [US1] Move each_with_index method to Map::Ordering module (uses `@keys.each_with_index`) in lib/map/ordering.rb
- [x] T019 [P] [US1] Move delete method to Map::Ordering module (removes from `@keys` array) in lib/map/ordering.rb
- [x] T020 [US1] Remove or comment out the 11 extracted methods from lib/map.rb (module will provide them when included)
- [x] T021 [US1] Verify Map::Ordering module is complete and syntactically correct (ruby -c lib/map/ordering.rb)
- [x] T022 [US1] Test with MAP_FORCE_ORDERING=1 rake test - verify all tests pass
- [x] T023 [US1] Verify @keys instance variable exists when module included (add inspection test)

**Checkpoint**: At this point, User Story 1 should be fully functional - Ruby < 1.9 behavior simulated via MAP_FORCE_ORDERING=1

---

## Phase 4: User Story 2 - Modern Ruby Optimization (Priority: P2)

**Goal**: Ensure Ruby 1.9+ uses native Hash ordering without `@keys` array overhead, achieving 25% memory savings

**Independent Test**: Run tests normally (without MAP_FORCE_ORDERING) on Ruby 1.9+, verify all tests pass, no `@keys` variable exists, and ordering works correctly

### Implementation for User Story 2

- [x] T024 [US2] Verify conditional inclusion logic in lib/map.rb correctly excludes module on Ruby >= 1.9
- [x] T025 [US2] Test normal execution (rake test) on current Ruby version (3.x) - verify all tests pass
- [x] T026 [US2] Verify Map instances have no @keys instance variable (map.instance_variables inspection)
- [x] T027 [US2] Verify ordering methods delegate to Hash superclass correctly (keys, values, each, first, last)
- [x] T028 [US2] Add test case to verify memory optimization - Map instance should not have @keys in lib/map.rb comment or test
- [x] T029 [US2] Verify Map::Options subclass inherits correct behavior (no @keys on Ruby 1.9+)
- [x] T030 [US2] Performance verification - ensure no regression in iteration speed (optional benchmark)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - Ruby 1.9+ optimized, legacy simulated via env var

---

## Phase 5: User Story 3 - Simple Cross-Version Testing (Priority: P3)

**Goal**: Provide KISS testing mechanism via MAP_FORCE_ORDERING=1 environment variable to validate both code paths

**Independent Test**: Run test suite both ways (with and without MAP_FORCE_ORDERING), verify clear output shows which path is active

### Implementation for User Story 3

- [ ] T031 [P] [US3] Add test helper to detect and report which mode is active in test/map_test.rb or test/lib/testing.rb
- [ ] T032 [P] [US3] Create verification test that checks @keys presence matches expected mode in test/map_test.rb
- [ ] T033 [US3] Document testing approach in README.md or TESTING.md file
- [ ] T034 [US3] Add CI configuration example for testing both paths in .github/workflows or equivalent
- [ ] T035 [US3] Create quick verification script (test/verify_ordering.rb) that demonstrates both modes per quickstart.md
- [ ] T036 [US3] Update Rakefile to support `rake test:with_ordering` and `rake test:without_ordering` tasks
- [ ] T037 [US3] Verify test output clearly indicates which configuration ran (module included/excluded)
- [ ] T038 [US3] Run full test suite in both modes and verify identical pass/fail results

**Checkpoint**: All user stories should now be independently functional - both code paths validated

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and finalize the feature

- [ ] T039 [P] Update CHANGELOG with feature description and version notes
- [ ] T040 [P] Update README.md with explanation of conditional ordering module (if needed)
- [ ] T041 [P] Add code comments explaining module inclusion logic in lib/map.rb
- [ ] T042 [P] Add module documentation comments in lib/map/ordering.rb
- [ ] T043 [P] Document Marshal compatibility limitation in CHANGELOG or README
- [ ] T044 [US3] Run quickstart.md validation - verify all examples work
- [ ] T045 Verify Map::Options subclass works correctly in both modes
- [ ] T046 Check for any Ruby 1.8 syntax issues in Map::Ordering module (if targeting old Ruby)
- [ ] T047 Final regression test - run existing test suite 3 times (normal, forced ordering, different Ruby if available)
- [ ] T048 Code review checklist - verify all 11 methods extracted, no duplicates, proper delegation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User Story 1 (P1): Can start after Foundational - No dependencies on other stories
  - User Story 2 (P2): Depends on User Story 1 completion (needs module to verify exclusion works)
  - User Story 3 (P3): Depends on User Stories 1 & 2 (needs both paths working to test)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - Core extraction work
- **User Story 2 (P2)**: Depends on User Story 1 completion - Validates optimization path
- **User Story 3 (P3)**: Depends on User Stories 1 & 2 - Validates testing mechanism across both

**Note**: Unlike typical projects, these user stories are sequential because:
- US2 requires US1 module to exist before verifying it's correctly excluded
- US3 requires both code paths (US1 & US2) working before testing mechanism is meaningful

### Within Each User Story

- **User Story 1**: Tasks T009-T019 (method moves) are parallelizable [P]
- **User Story 2**: Tasks T026-T027 are verification steps, run sequentially
- **User Story 3**: Tasks T031-T032 (test helpers) are parallelizable [P]

### Parallel Opportunities

- Phase 1: Tasks T003-T004 can run in parallel
- Phase 2: All tasks sequential (building foundation)
- User Story 1: Tasks T009-T019 (11 method extractions) can be done in parallel
- User Story 3: Tasks T031-T032, T033-T034, T039-T043 can run in parallel
- Polish Phase: Documentation tasks T039-T043 can run in parallel

---

## Parallel Example: User Story 1 (Method Extraction)

```bash
# All 11 method extractions can happen simultaneously:
Task: "Move Map.allocate to Map::Ordering (initializes @keys) in lib/map/ordering.rb"
Task: "Move keys method to Map::Ordering (returns @keys) in lib/map/ordering.rb"
Task: "Move []= method to Map::Ordering (tracks keys) in lib/map/ordering.rb"
Task: "Move values method to Map::Ordering (iterates @keys) in lib/map/ordering.rb"
Task: "Move first method to Map::Ordering (uses @keys.first) in lib/map/ordering.rb"
Task: "Move last method to Map::Ordering (uses @keys.last) in lib/map/ordering.rb"
Task: "Move each/each_pair to Map::Ordering (iterates @keys) in lib/map/ordering.rb"
Task: "Move each_key method to Map::Ordering (iterates @keys) in lib/map/ordering.rb"
Task: "Move each_value to Map::Ordering (iterates @keys) in lib/map/ordering.rb"
Task: "Move each_with_index to Map::Ordering (uses @keys) in lib/map/ordering.rb"
Task: "Move delete method to Map::Ordering (removes from @keys) in lib/map/ordering.rb"

# These are all independent - different methods being moved to same new file
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (understand current code)
2. Complete Phase 2: Foundational (create module structure)
3. Complete Phase 3: User Story 1 (extract all ordering methods)
4. **STOP and VALIDATE**: Test with MAP_FORCE_ORDERING=1, verify @keys exists and tests pass
5. Ready for PR/review with backward compatibility proven

### Incremental Delivery

1. Complete Setup + Foundational → Module structure ready
2. Add User Story 1 → Test with forced ordering → Backward compat proven (MVP!)
3. Add User Story 2 → Test normal mode → Optimization verified
4. Add User Story 3 → Test both modes → Testing mechanism validated
5. Polish → Documentation complete → Feature done

### Single Developer Strategy

Since user stories are sequential:

1. Complete Setup + Foundational (Phase 1-2)
2. Extract all methods to module (Phase 3 / US1) - can parallelize the 11 method moves
3. Verify optimization works (Phase 4 / US2)
4. Add testing mechanism (Phase 5 / US3)
5. Polish and document (Phase 6)

---

## Task Summary

**Total Tasks**: 48 tasks

**Task Count by Phase**:
- Phase 1 (Setup): 4 tasks
- Phase 2 (Foundational): 4 tasks
- Phase 3 (User Story 1 - Legacy Support): 15 tasks
- Phase 4 (User Story 2 - Optimization): 7 tasks
- Phase 5 (User Story 3 - Testing): 8 tasks
- Phase 6 (Polish): 10 tasks

**Parallelizable Tasks**: 26 tasks marked with [P]

**User Story Mapping**:
- US1 (Legacy Ruby Support): 15 tasks - Module extraction
- US2 (Modern Ruby Optimization): 7 tasks - Verification and optimization
- US3 (Cross-Version Testing): 8 tasks - Testing mechanism

**Suggested MVP Scope**:
- Phase 1 + Phase 2 + Phase 3 (User Story 1)
- Total: 23 tasks to achieve backward compatibility with module extraction
- Deliverable: Map works with forced ordering mode, proving legacy Ruby support

**Independent Testing**:
- US1: Run with `MAP_FORCE_ORDERING=1 rake test`, verify @keys exists
- US2: Run with `rake test`, verify no @keys, all tests pass
- US3: Run both modes, verify test output clarity

---

## Notes

- [P] tasks = can run in parallel (different methods, independent work)
- [Story] label maps task to specific user story for traceability
- This is an internal refactoring, so no external API contracts
- Existing test suite is validation - no new tests required per spec
- Module extraction enables clean separation without code duplication
- Commit after each logical group (e.g., after all methods extracted)
- Stop at any checkpoint to validate story independently

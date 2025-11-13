# Implementation Plan: Conditional Ordered Map Module

**Branch**: `001-ordered-map-module` | **Date**: 2025-11-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-ordered-map-module/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Extract ordering-related code (using `@keys` array) into a separate module and conditionally include it only in Ruby versions where Hash is not ordered by default (Ruby < 1.9). This maintains backward compatibility for legacy Ruby versions while optimizing memory and performance for modern Ruby versions that have native Hash ordering. The implementation must preserve API compatibility and provide a simple testing mechanism to validate both code paths.

## Technical Context

**Language/Version**: Ruby 3.0+ (current minimum per gemspec), must support Ruby 1.8.x through 3.x behavior
**Primary Dependencies**: None (map.rb is dependency-free per project philosophy)
**Storage**: N/A (in-memory data structure library)
**Testing**: Custom testing framework (test/lib/testing.rb) using `Testing` DSL
**Target Platform**: Cross-Ruby (MRI 1.8.x through 3.x, JRuby, Rubinius, TruffleRuby)
**Project Type**: Single Ruby gem library
**Performance Goals**: Zero performance regression on Ruby 1.9+, maintain current performance on Ruby 1.8.x
**Constraints**: No external dependencies, maintain existing test suite without modification, 100% backward API compatibility
**Scale/Scope**: Core library with ~800 lines of code, ~200 test cases, used in production for 14+ years

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: ✅ PASS - Constitution file is template-only, no specific project principles defined yet.

This refactoring:
- Maintains zero external dependencies (core map.rb principle)
- Preserves 100% API compatibility (no breaking changes)
- Uses existing test framework without modification
- Follows KISS principle for testing mechanism
- Improves code organization through modularization

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── map.rb                    # Main Map class (modified: conditional module inclusion)
├── map/
│   ├── _lib.rb              # Utility methods
│   ├── options.rb           # Map::Options subclass
│   └── ordering.rb          # NEW: OrderingModule for legacy Ruby support

test/
├── map_test.rb              # Existing test suite (no modifications)
├── lib/
│   └── testing.rb           # Custom testing framework
└── leak.rb                  # Memory leak tests
```

**Structure Decision**: Single gem library structure. The feature adds one new file (`lib/map/ordering.rb`) containing the extracted ordering module, and modifies the main `lib/map.rb` to conditionally include the module based on Ruby version detection. All existing files remain backward compatible.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

N/A - No constitution violations. This is a simplification refactoring that reduces code complexity by conditionally including only necessary functionality.

---

## Phase 0: Research Complete ✅

**Output**: [research.md](research.md)

**Key Decisions**:
- Ruby 1.9.0 version cutoff for conditional module inclusion
- Use RUBY_VERSION constant for detection
- Extract 11 ordering-dependent methods to Map::Ordering module
- KISS testing via `MAP_FORCE_ORDERING=1` environment variable
- Accept Marshal cross-version incompatibility as documented limitation

**Status**: All technical unknowns resolved, ready for Phase 1 design.

---

## Phase 1: Design & Contracts Complete ✅

### Artifacts Generated

1. **[data-model.md](data-model.md)**: Internal state model documentation
   - Two configurations: with/without `@keys` array
   - State transitions and invariants
   - Memory footprint analysis (25% savings on Ruby 1.9+)
   - API compatibility matrix

2. **contracts/**: N/A (internal refactoring, no external APIs)

3. **[quickstart.md](quickstart.md)**: Developer guide
   - Architecture diagrams
   - Testing both code paths
   - Code organization guidelines
   - Troubleshooting guide

### Constitution Check (Post-Phase 1) ✅

**Status**: ✅ PASS - All design decisions align with project principles

**Design Review**:
- ✅ Zero external dependencies maintained
- ✅ Backward compatibility preserved (100% API compatible)
- ✅ Testing approach is KISS (single environment variable)
- ✅ Code organization improved (separation of concerns via module)
- ✅ Memory optimization achieved without breaking changes
- ✅ Existing test suite requires no modifications

**No violations identified** - The design enhances the codebase while maintaining all core principles.

---

## Next Steps

The planning phase is complete. To proceed with implementation:

1. Run `/speckit.tasks` to generate the implementation task list (tasks.md)
2. Review and approve the generated tasks
3. Execute tasks sequentially to implement the feature

**Implementation will include**:
- Creating `lib/map/ordering.rb` with extracted methods
- Modifying `lib/map.rb` to conditionally include the module
- Adding tests to verify both code paths
- Updating documentation and CHANGELOG

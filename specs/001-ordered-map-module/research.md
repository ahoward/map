# Research: Conditional Ordered Map Module

**Date**: 2025-11-10
**Feature**: Conditional Ordered Map Module
**Phase**: 0 - Research & Technical Decisions

## Overview

This document captures research findings and technical decisions for extracting ordering-related code into a conditional module for the map.rb library.

## Key Research Areas

### 1. Ruby Hash Ordering History

**Decision**: Use Ruby version 1.9.0 as the cutoff for conditional module inclusion

**Rationale**:
- Ruby 1.8.x: Hash was **unordered** - iteration order was unpredictable and based on internal hash table structure
- Ruby 1.9.0+: Hash became **ordered by insertion** - maintains the order in which keys were added
- This change was formalized in Ruby 1.9 and has been maintained in all subsequent versions (2.x, 3.x)
- The change applies to all major Ruby implementations (MRI, JRuby, Rubinius, TruffleRuby) at their respective 1.9+ version equivalents

**Alternatives considered**:
- Using RUBY_VERSION string comparison: Rejected due to complexity with alternative Ruby implementations
- Using feature detection (checking if Hash preserves order): Rejected as overly complex for a well-known version boundary
- Using Ruby 2.0 as cutoff: Rejected as 1.9.x still had significant usage when map.rb was established

**References**:
- Ruby 1.9 release notes documented the Hash ordering change
- This is a well-established Ruby language feature with no ambiguity across implementations

### 2. Module Inclusion Strategy

**Decision**: Use conditional `include` at class definition time based on RUBY_VERSION constant

**Rationale**:
- Simple, explicit, and evaluated once at load time (zero runtime overhead)
- Ruby's RUBY_VERSION constant is available in all Ruby versions
- Module inclusion allows clean separation of ordering-specific methods
- Methods in the module override Hash superclass methods when included

**Implementation approach**:
```ruby
class Map < Hash
  # ... existing code ...

  # Conditionally include ordering module for Ruby < 1.9
  if RUBY_VERSION < '1.9'
    require_relative 'map/ordering'
    include Map::Ordering
  end
end
```

**Alternatives considered**:
- Runtime method checks: Rejected due to performance overhead on every method call
- Monkey-patching after class definition: Rejected as less maintainable and harder to test
- Separate Map class for each version: Rejected as it duplicates code and breaks the "single class" design

### 3. Methods to Extract into Ordering Module

**Decision**: Extract all methods that directly depend on the `@keys` instance variable

**Methods identified from lib/map.rb analysis**:
1. `Map.allocate` - Initializes `@keys = []`
2. `keys` - Returns `@keys` array
3. `[]=` (store) - Tracks key in `@keys.push(key)` on new insertions
4. `values` - Iterates over `@keys` to build values array
5. `first` - Returns `[keys.first, self[keys.first]]`
6. `last` - Returns `[keys.last, self[keys.last]]`
7. `each` (and `each_pair`) - Iterates over `@keys` array
8. `each_key` - Iterates over `@keys` array
9. `each_value` - Iterates over `@keys` to access values
10. `each_with_index` - Iterates over `@keys.each_with_index`
11. `delete` - Removes key from `@keys` array

**Rationale**:
- These methods explicitly use `@keys` for ordering guarantees
- In Ruby 1.9+, Hash superclass provides ordered versions of these methods
- Extracting to module allows clean fallback to Hash methods when module not included

**Alternatives considered**:
- Extracting only iterator methods: Rejected as incomplete - would still need `@keys` for `first`/`last`
- Keeping `@keys` for backward compatibility: Rejected as it defeats the memory optimization goal

### 4. Testing Strategy (KISS Approach)

**Decision**: Use environment variable `MAP_FORCE_ORDERING=1` to force inclusion of ordering module regardless of Ruby version

**Rationale**:
- Simple: Single environment variable toggle
- KISS: No complex test matrix infrastructure needed
- Effective: Allows testing both code paths on any Ruby version
- Non-invasive: Doesn't require test suite modifications

**Implementation**:
```ruby
# In lib/map.rb
if RUBY_VERSION < '1.9' || ENV['MAP_FORCE_ORDERING']
  require_relative 'map/ordering'
  include Map::Ordering
end
```

**Test execution**:
```bash
# Test normal path (Ruby 1.9+ without ordering module)
rake test

# Test ordering module path (forced inclusion)
MAP_FORCE_ORDERING=1 rake test
```

**Alternatives considered**:
- Separate test files for each path: Rejected as it duplicates test code
- Docker containers with multiple Ruby versions: Rejected as over-engineered for this simple need
- Rake tasks that modify source before testing: Rejected as fragile and error-prone
- RSpec shared examples: Rejected as map.rb uses custom testing framework, not RSpec

### 5. Marshal Compatibility Considerations

**Decision**: Accept potential Marshal incompatibility across Ruby versions as documented limitation

**Rationale**:
- Maps created on Ruby 1.8.x will have `@keys` instance variable
- Maps created on Ruby 1.9+ will NOT have `@keys` instance variable
- Marshal.load of cross-version dumps may produce Maps with inconsistent internal state
- This is acceptable because:
  - Marshal is typically used within same runtime environment
  - Cross-version Marshal compatibility is rarely needed in practice
  - Users can work around by converting to Hash, then back to Map if needed

**Mitigation**:
- Document this limitation in CHANGELOG and upgrade notes
- Provide helper method to normalize Maps if cross-version Marshal support is needed

**Alternatives considered**:
- Custom marshal_dump/marshal_load: Rejected as it adds complexity for an edge case
- Always including @keys for Marshal compatibility: Rejected as it defeats the optimization
- Raising error on cross-version load: Rejected as too defensive

### 6. Alternative Ruby Implementation Compatibility

**Decision**: Trust that alternative implementations (JRuby, Rubinius, TruffleRuby) follow MRI Hash ordering behavior at their version boundaries

**Rationale**:
- JRuby 1.9+ mode guarantees Hash ordering (matches MRI 1.9 behavior)
- Rubinius follows MRI compatibility at version equivalents
- TruffleRuby explicitly aims for MRI compatibility
- RUBY_VERSION constant reflects the Ruby version being emulated

**Risk assessment**: Low - Hash ordering is part of the Ruby spec since 1.9, all major implementations comply

**Alternatives considered**:
- Platform-specific detection: Rejected as unnecessary complexity
- Feature-based detection (test if Hash preserves order): Rejected as over-engineered

## Technical Decisions Summary

| Decision Point | Choice | Rationale |
|----------------|--------|-----------|
| Version cutoff | Ruby 1.9.0 | Well-documented Hash ordering introduction |
| Inclusion mechanism | Conditional `include` at load time | Zero runtime overhead, simple and clear |
| Methods to extract | All `@keys`-dependent methods (11 methods) | Complete separation, enables Hash method delegation |
| Testing approach | Environment variable `MAP_FORCE_ORDERING=1` | KISS principle, easy to use, no test modifications |
| Marshal compatibility | Accept limitation, document workaround | Edge case doesn't justify complexity |
| Alt Ruby impls | Trust RUBY_VERSION constant | All major implementations comply with spec |

## Implementation Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| Ruby version detection fails on unknown implementation | High | Very Low | RUBY_VERSION is universal Ruby constant |
| Tests fail on older Ruby due to syntax | High | Low | Use Ruby 1.8-compatible syntax in ordering module |
| Performance regression on Ruby 1.9+ | Medium | Very Low | No code changes to 1.9+ path, only omission of module |
| Subclasses of Map break | High | Low | Test with Map::Options subclass, verify inheritance |
| Marshal incompatibility causes production issues | Medium | Very Low | Document limitation, provide conversion helper |

## Next Steps (Phase 1)

Based on research findings, Phase 1 will generate:

1. **data-model.md**: Document the internal state model (with/without `@keys` based on Ruby version)
2. **contracts/**: N/A for this feature (no external APIs, internal refactoring only)
3. **quickstart.md**: Developer guide for working with the new module structure

## Open Questions

None - all research areas resolved with clear decisions.

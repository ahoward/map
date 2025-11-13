# Data Model: Conditional Ordered Map Module

**Date**: 2025-11-10
**Feature**: Conditional Ordered Map Module
**Phase**: 1 - Design

## Overview

This document describes the internal state model and behavior of the Map class under the conditional ordering module architecture.

## Entity: Map Class

### Description

Map is a string/symbol-indifferent ordered hash that extends Ruby's Hash class. Its internal state varies based on Ruby version to optimize for native Hash ordering capabilities.

### State Model

Map has two distinct internal state configurations depending on the Ruby runtime:

#### Configuration 1: Ruby < 1.9 (Legacy Ordering)

**Includes**: `Map::Ordering` module

**Instance Variables**:
- `@keys` (Array): Maintains insertion order of keys as strings

**Behavior**:
- Keys are tracked in `@keys` array upon insertion
- Iteration methods (`each`, `each_key`, `each_value`) use `@keys` for deterministic ordering
- `first` and `last` methods rely on `@keys.first` and `@keys.last`
- `delete` removes key from both Hash storage and `@keys` array
- `values` returns array built by iterating `@keys`

**State Transitions**:
```
[Empty Map]
  |
  | Map[:a, 1]  ->  @keys = ['a'], Hash = {'a' => 1}
  |
[Map with one entry]
  |
  | map[:b] = 2  ->  @keys = ['a', 'b'], Hash = {'a' => 1, 'b' => 2}
  |
[Map with two entries]
  |
  | map.delete(:a)  ->  @keys = ['b'], Hash = {'b' => 2}
  |
[Map with one entry]
```

#### Configuration 2: Ruby >= 1.9 (Native Ordering)

**Includes**: No ordering module

**Instance Variables**:
- None (Map-specific) - relies on Hash superclass storage

**Behavior**:
- Hash superclass maintains insertion order natively
- Iteration methods delegate to Hash superclass implementations
- `first` and `last` use Hash#first and Hash#last (available in Ruby 1.9+)
- `delete` uses Hash#delete (automatically maintains ordering)
- `values` uses Hash#values (preserves ordering)

**State Transitions**:
```
[Empty Map]
  |
  | Map[:a, 1]  ->  Hash = {'a' => 1} (ordered)
  |
[Map with one entry]
  |
  | map[:b] = 2  ->  Hash = {'a' => 1, 'b' => 2} (ordered)
  |
[Map with two entries]
  |
  | map.delete(:a)  ->  Hash = {'b' => 2} (ordered)
  |
[Map with one entry]
```

## Entity: Map::Ordering Module

### Description

Module containing all ordering-related methods that manually track insertion order using an `@keys` array. This module is only included in Map when Ruby < 1.9 or when forced via `ENV['MAP_FORCE_ORDERING']`.

### Methods

#### Class Methods

- `allocate`: Overrides Map.allocate to initialize `@keys = []` on new instances

#### Instance Methods

- `keys`: Returns `@keys` array (overrides Hash#keys)
- `[]=` (store): Tracks new keys in `@keys` array, delegates storage to Hash
- `values`: Builds array by iterating `@keys`, fetching each value
- `first`: Returns `[keys.first, self[keys.first]]`
- `last`: Returns `[keys.last, self[keys.last]]`
- `each` / `each_pair`: Iterates `@keys`, yielding `[key, self[key]]` pairs
- `each_key`: Iterates `@keys`, yielding each key
- `each_value`: Iterates `@keys`, yielding `self[key]` for each
- `each_with_index`: Iterates `@keys.each_with_index`, yielding `[[key, self[key]], index]`
- `delete`: Removes key from `@keys` array, then calls `super` to delete from Hash

### Constraints

- `@keys` must contain only string keys (symbol keys are converted to strings by Map#convert_key)
- Order of `@keys` must match insertion order
- No duplicate keys in `@keys` array
- `@keys` and Hash storage must stay synchronized (every key in one must be in the other)

## Version Detection Logic

### Conditional Inclusion

```ruby
# Pseudo-code for lib/map.rb
class Map < Hash
  # ... existing Map code ...

  # Conditional module inclusion at class definition time
  if RUBY_VERSION < '1.9' || ENV['MAP_FORCE_ORDERING']
    require_relative 'map/ordering'
    include Map::Ordering
  end
end
```

### Detection Rules

| Condition | Module Included? | Rationale |
|-----------|-----------------|-----------|
| RUBY_VERSION < '1.9' | Yes | Hash is unordered, need manual tracking |
| RUBY_VERSION >= '1.9' | No | Hash is ordered natively |
| ENV['MAP_FORCE_ORDERING'] = '1' | Yes | Testing mode - force ordering module |
| ENV['MAP_FORCE_ORDERING'] unset | Per version | Normal operation |

## API Compatibility Matrix

All public API methods maintain identical behavior regardless of configuration:

| Method | Ruby < 1.9 (with module) | Ruby >= 1.9 (without module) | Compatible? |
|--------|-------------------------|------------------------------|-------------|
| `keys` | Returns `@keys` | Returns Hash#keys (ordered) | ✅ Yes |
| `values` | Iterates `@keys` to build array | Returns Hash#values (ordered) | ✅ Yes |
| `each` | Iterates `@keys` | Uses Hash#each (ordered) | ✅ Yes |
| `first` | `[keys.first, self[keys.first]]` | Hash#first | ✅ Yes |
| `last` | `[keys.last, self[keys.last]]` | Hash#last | ✅ Yes |
| `delete` | Removes from `@keys` + Hash | Hash#delete (maintains order) | ✅ Yes |
| `[]=` | Tracks in `@keys` + Hash | Hash#[]= (maintains order) | ✅ Yes |

## Invariants

### Cross-Configuration Invariants

These properties must hold true in BOTH configurations:

1. **Insertion order preservation**: `map.keys` always returns keys in insertion order
2. **String/symbol indifference**: `map[:a]` and `map['a']` access the same value
3. **Deterministic iteration**: Multiple calls to `each` yield keys in same order
4. **First/last consistency**: `map.first[0] == map.keys.first`
5. **No nil default**: Map doesn't work with non-nil default values (existing constraint)

### Configuration-Specific Invariants

#### Ruby < 1.9 with Ordering Module:

1. **Synchronization**: `@keys.size == Hash.size` always
2. **Key membership**: Every key in `@keys` exists in Hash, and vice versa
3. **No duplicates**: `@keys.uniq.size == @keys.size`

#### Ruby >= 1.9 without Ordering Module:

1. **No @keys variable**: `instance_variables` should not include `@keys`
2. **Hash delegation**: Ordering methods delegate to Hash superclass

## Memory Footprint Comparison

### Ruby < 1.9 (with Ordering Module)

Per Map instance:
- Hash storage: ~40 bytes + (n * 24 bytes per entry)
- `@keys` array: ~40 bytes + (n * 8 bytes per string reference)
- **Total overhead**: ~80 bytes + (n * 32 bytes)

### Ruby >= 1.9 (without Ordering Module)

Per Map instance:
- Hash storage: ~40 bytes + (n * 24 bytes per entry)
- **Total overhead**: ~40 bytes + (n * 24 bytes)

### Memory Savings

For a Map with 100 entries:
- Ruby < 1.9: ~3,280 bytes
- Ruby >= 1.9: ~2,440 bytes
- **Savings**: ~840 bytes (25% reduction)

For a Map with 1,000 entries:
- Ruby < 1.9: ~32,080 bytes
- Ruby >= 1.9: ~24,040 bytes
- **Savings**: ~8,040 bytes (25% reduction)

## Subclassing Considerations

### Map::Options

The existing `Map::Options` subclass inherits ordering behavior from Map:

- If Map includes `Map::Ordering`, Map::Options inherits those methods
- If Map doesn't include `Map::Ordering`, Map::Options uses Hash ordering
- No changes required to Map::Options implementation

### Future Subclasses

Any subclass of Map will:
- Automatically get appropriate ordering behavior based on Ruby version
- Inherit `@keys` initialization if Ordering module is included
- Be able to override ordering methods if needed (standard Ruby inheritance)

## Testing Verification Points

To verify correct data model implementation:

1. **Instance variable presence**: Check `instance_variables.include?(:@keys)` matches expected configuration
2. **Ordering correctness**: Verify `keys`, `values`, `each` return deterministic order
3. **Synchronization**: On Ruby < 1.9, verify `@keys.size == size` after all operations
4. **Memory**: On Ruby >= 1.9, verify no `@keys` array allocated
5. **Marshal**: Verify Maps serialize/deserialize within same Ruby version
6. **Subclass inheritance**: Verify Map::Options exhibits same ordering behavior as Map

## Edge Cases

1. **Empty Map**: Should work identically in both configurations (no keys, no @keys)
2. **Marshal across versions**: May fail or produce inconsistent state (documented limitation)
3. **Forking**: `@keys` array duplicated in child process on Ruby < 1.9 (standard Ruby behavior)
4. **Thread safety**: Same thread-safety guarantees as Hash (no additional synchronization)

## Migration Path

For users upgrading from older Ruby versions:

1. **No code changes required**: API remains identical
2. **Memory reduction automatic**: Ruby 1.9+ users get automatic optimization
3. **Marshal incompatibility**: If loading Marshal dumps from Ruby 1.8.x on Ruby 1.9+:
   - Workaround: `map.to_hash.to_map` to normalize
   - Alternative: Use JSON/YAML for cross-version serialization

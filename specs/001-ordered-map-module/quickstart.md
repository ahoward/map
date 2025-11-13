# Developer Quickstart: Conditional Ordered Map Module

**Feature**: Conditional Ordered Map Module
**Branch**: `001-ordered-map-module`
**Last Updated**: 2025-11-10

## Overview

This guide helps developers understand and work with the conditional ordering module architecture in map.rb.

## What Changed?

### Before (All Ruby Versions)

```ruby
# lib/map.rb
class Map < Hash
  def keys
    @keys ||= []  # Always maintained for ordering
  end

  def []=(key, val)
    key, val = convert(key, val)
    keys.push(key) unless has_key?(key)  # Always track
    __set__(key, val)
  end

  # ... 10 other methods using @keys ...
end
```

**Problem**: Ruby 1.9+ already maintains Hash ordering, so `@keys` is redundant (memory waste).

### After (Version-Aware)

```ruby
# lib/map.rb
class Map < Hash
  # Core methods work for Ruby 1.9+ (no @keys needed)

  # Conditionally include ordering module for legacy Ruby
  if RUBY_VERSION < '1.9' || ENV['MAP_FORCE_ORDERING']
    require_relative 'map/ordering'
    include Map::Ordering
  end
end

# lib/map/ordering.rb
module Map::Ordering
  def self.included(base)
    base.class_eval do
      def self.allocate
        super.instance_eval do
          @keys = []
          self
        end
      end
    end
  end

  def keys
    @keys ||= []
  end

  def []=(key, val)
    key, val = convert(key, val)
    keys.push(key) unless has_key?(key)
    __set__(key, val)
  end

  # ... other ordering methods ...
end
```

**Solution**: Ruby 1.9+ uses native Hash ordering, Ruby < 1.9 includes module for manual ordering.

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────┐
│                    Map Class                        │
│                  (extends Hash)                     │
│                                                     │
│  Core methods (work on Ruby 1.9+ with native Hash)│
│  - convert_key, convert_value                      │
│  - initialize, update, merge                       │
│  - get, set (use Hash methods)                     │
└─────────────────────────────────────────────────────┘
                        △
                        │
                        │ conditionally includes
                        │ (if RUBY_VERSION < '1.9')
                        │
┌─────────────────────────────────────────────────────┐
│              Map::Ordering Module                   │
│                                                     │
│  Ordering-specific methods (override Hash methods):│
│  - allocate (class method via included hook)       │
│  - keys, values, first, last                       │
│  - each, each_key, each_value, each_with_index     │
│  - []=, delete                                     │
│                                                     │
│  Uses @keys array to maintain insertion order      │
└─────────────────────────────────────────────────────┘
```

### Decision Tree

```
Map class loaded
    │
    ├─ Is RUBY_VERSION < '1.9'?
    │   ├─ YES → Include Map::Ordering
    │   │         └─ Use @keys array for ordering
    │   └─ NO ──┐
    │           │
    └─ Is ENV['MAP_FORCE_ORDERING'] set?
        ├─ YES → Include Map::Ordering (testing mode)
        │         └─ Use @keys array for ordering
        └─ NO → No module inclusion
                 └─ Use native Hash ordering
```

## Development Workflow

### Setting Up Your Environment

```bash
# Clone and checkout feature branch
git clone https://github.com/ahoward/map.git
cd map
git checkout 001-ordered-map-module

# Check Ruby version
ruby --version
# Should be 3.0+ per current gemspec
```

### Running Tests

#### Normal Mode (Ruby 1.9+ behavior)

```bash
# Run all tests using native Hash ordering
rake test
```

Expected:
- All tests pass
- Map instances have NO `@keys` instance variable
- Ordering works via Hash#keys, Hash#each, etc.

#### Forced Ordering Mode (Ruby < 1.9 simulation)

```bash
# Force inclusion of ordering module
MAP_FORCE_ORDERING=1 rake test
```

Expected:
- All tests pass
- Map instances HAVE `@keys` instance variable
- Ordering works via `@keys` array tracking

### Verifying Both Paths

```ruby
# Quick verification script
# test/verify_ordering.rb

require 'map'

def test_ordering_module_state
  map = Map[:a, 1, :b, 2, :c, 3]

  puts "Ruby Version: #{RUBY_VERSION}"
  puts "Force Ordering: #{ENV['MAP_FORCE_ORDERING']}"
  puts "Has @keys: #{map.instance_variables.include?(:@keys)}"
  puts "Keys: #{map.keys.inspect}"
  puts "Values: #{map.values.inspect}"
  puts "First: #{map.first.inspect}"
  puts "Last: #{map.last.inspect}"

  # Verify ordering is maintained
  raise "Ordering broken!" unless map.keys == ['a', 'b', 'c']
  raise "Values broken!" unless map.values == [1, 2, 3]

  puts "✅ All checks passed!"
end

test_ordering_module_state
```

Run both ways:

```bash
# Test without ordering module
ruby test/verify_ordering.rb
# Should show: Has @keys: false

# Test with ordering module
MAP_FORCE_ORDERING=1 ruby test/verify_ordering.rb
# Should show: Has @keys: true
```

## Code Organization

### File Structure

```
lib/map.rb                  # Main Map class
                            # - Contains conditional include logic
                            # - Methods work for Ruby 1.9+ native ordering

lib/map/ordering.rb         # NEW: Ordering module
                            # - All @keys-dependent methods
                            # - Included only when needed

lib/map/_lib.rb            # Unchanged: utility methods
lib/map/options.rb         # Unchanged: Map::Options subclass
```

### What Goes Where?

**lib/map.rb** (Methods that work with native Hash ordering):
- `convert_key` - Key normalization (string/symbol)
- `convert_value` - Recursive Map conversion
- `initialize`, `update`, `merge` - Constructors and merging
- `get` (fetch with nested paths) - Doesn't depend on ordering
- `method_missing` - Attribute-style access

**lib/map/ordering.rb** (Methods that need `@keys` array):
- `allocate` - Initialize `@keys = []`
- `keys` - Return `@keys`
- `values` - Iterate `@keys` to build values array
- `[]=`, `delete` - Track keys in `@keys`
- `each`, `each_key`, `each_value`, `each_with_index` - Iterate via `@keys`
- `first`, `last` - Use `@keys.first`, `@keys.last`

## Common Development Tasks

### Adding a New Method to Map

**Question**: Should it go in `Map` or `Map::Ordering`?

**Decision tree**:
1. Does it depend on key ordering?
   - NO → Add to `lib/map.rb`
   - YES → Continue to #2
2. Does it need `@keys` array specifically?
   - NO → Add to `lib/map.rb` (can use Hash methods)
   - YES → Add to `lib/map/ordering.rb`

**Examples**:

```ruby
# Example 1: New method that doesn't care about ordering
# Add to lib/map.rb
def has_nested?(path)
  get(path) != nil
end

# Example 2: New method that needs ordering but can use Hash methods
# Add to lib/map.rb (works on Ruby 1.9+)
def second
  key = keys[1]  # Hash#keys is ordered on 1.9+
  [key, self[key]]
end

# Example 3: New method that explicitly needs @keys
# Add to lib/map/ordering.rb
def reverse_each
  @keys.reverse.each { |key| yield(key, self[key]) }
end
```

### Modifying an Ordering Method

If you need to modify a method in `Map::Ordering`:

1. Edit `lib/map/ordering.rb`
2. Test both paths:
   ```bash
   # Ruby 1.9+ path (should still work without your change)
   rake test

   # Legacy path (should work with your change)
   MAP_FORCE_ORDERING=1 rake test
   ```

### Debugging Ordering Issues

```ruby
# Add to your test or debugging session
map = Map[:a, 1, :b, 2]

# Check which path is being used
if map.instance_variables.include?(:@keys)
  puts "Using Map::Ordering module"
  puts "@keys = #{map.instance_variable_get(:@keys).inspect}"
else
  puts "Using native Hash ordering"
end

# Verify ordering consistency
puts "Keys order: #{map.keys.inspect}"
puts "Each order: #{map.map { |k, v| k }.inspect}"
```

## Testing Strategy

### Test Categories

1. **Functional tests** (existing in `test/map_test.rb`):
   - No modifications needed
   - Run in both modes to verify identical behavior

2. **Internal state tests** (NEW tests to add):
   - Verify `@keys` presence/absence based on mode
   - Check memory footprint differences
   - Validate synchronization on Ruby < 1.9 mode

3. **Performance benchmarks** (optional):
   - Compare iteration speed with/without module
   - Measure memory usage with/without `@keys`

### Writing New Tests

```ruby
# In test/map_test.rb

Testing Map do
  testing 'conditional ordering module inclusion' do
    map = Map[:a, 1, :b, 2, :c, 3]

    # Test behavior (should work in both modes)
    assert{ map.keys == ['a', 'b', 'c'] }
    assert{ map.values == [1, 2, 3] }

    # Test internal state (mode-dependent)
    if ENV['MAP_FORCE_ORDERING'] || RUBY_VERSION < '1.9'
      assert{ map.instance_variables.include?(:@keys) }
    else
      assert{ !map.instance_variables.include?(:@keys) }
    end
  end
end
```

## Troubleshooting

### Problem: Tests pass normally but fail with MAP_FORCE_ORDERING=1

**Cause**: Likely a method is missing from `Map::Ordering` module

**Solution**:
1. Identify which test is failing
2. Check if the failing method uses `@keys`
3. Add missing method to `lib/map/ordering.rb`

### Problem: Memory usage isn't reduced on Ruby 3.x

**Cause**: Module is being included when it shouldn't be

**Solution**:
```ruby
# Verify module isn't included
map = Map.new
puts map.instance_variables.inspect
# Should be: [] (empty, no @keys)

# Check if module was mistakenly included
puts Map.ancestors.include?(Map::Ordering)
# Should be: false (on Ruby 1.9+)
```

### Problem: Subclass behavior differs from Map

**Cause**: Ordering module methods not inherited properly

**Solution**:
```ruby
# Verify inheritance chain
puts Map::Options.ancestors
# Should include Map::Ordering if Map does

# Test with subclass
opts = Map::Options[:a, 1, :b, 2]
puts opts.keys.inspect
# Should be: ['a', 'b'] (ordered)
```

## Performance Considerations

### Memory Impact

| Scenario | Before | After | Savings |
|----------|--------|-------|---------|
| Ruby 1.8.x | `@keys` array | `@keys` array | 0% (unchanged) |
| Ruby 1.9-2.x | `@keys` array | No `@keys` | ~25% per instance |
| Ruby 3.x | `@keys` array | No `@keys` | ~25% per instance |

### CPU Impact

| Operation | Ruby < 1.9 (with module) | Ruby >= 1.9 (native) | Impact |
|-----------|-------------------------|----------------------|---------|
| Insert | Track in `@keys` + Hash | Hash only | Negligible (one less array operation) |
| Iterate | Iterate `@keys` array | Iterate Hash | Negligible (both O(n)) |
| Delete | Remove from `@keys` + Hash | Hash only | Minor (array search removed) |

**Expected**: No measurable performance difference (< 5% regression per success criteria).

## Next Steps

After reviewing this quickstart:

1. Read the [data-model.md](data-model.md) for detailed state diagrams
2. Review [research.md](research.md) for technical decisions
3. Proceed to implementation using the `/speckit.tasks` command to generate implementation tasks

## Questions?

If you encounter issues or have questions:

1. Check the [data-model.md](data-model.md) for state model details
2. Review [research.md](research.md) for decision rationale
3. Examine existing tests in `test/map_test.rb` for examples
4. Run verification script to diagnose which path is active

# Supported Data Types

NetFlow provides a wide range of highly efficient data types to ensure that your packets use as little bandwidth as possible. The types are available under the `t` table of the module.

## Primitives

These are the fundamental building blocks for your network packets.

| Type | Description | Size |
| :--- | :--- | :--- |
| `uint8`, `uint16`, `uint32` | Unsigned integers | 1, 2, 4 bytes |
| `int8`, `int16`, `int32` | Signed integers | 1, 2, 4 bytes |
| `float32`, `float64` | Single and double precision floats | 4, 8 bytes |
| `bool` | Boolean value | 1 bit (aligned) |
| `string` | UTF-8 string | Dynamic |
| `buff` | Raw Luau buffer | Dynamic |
| `nothing` | Represents a `nil` value | 0 bytes |
| `unknown` | For values with unknown types (using Roblox serialization) | 1 byte in buffer + Type Size |

## Complex Types

You can combine primitives to create more complex data structures.

### `struct(spec: table)`
A structure (struct) is a collection of named fields with defined types. **Use this instead of `t.table`.**
It is the most common complex type used in schemas.
```lua
Net.t.struct({
    Id = Net.t.uint32,
    Name = Net.t.string,
    Position = Net.t.vec3
})
```

### `array(type: DataType)`
A list of elements of the same type.
```lua
Net.t.array(Net.t.uint32)
```

### `map(key: DataType, value: DataType)`
A set of key-value pairs.
```lua
Net.t.map(Net.t.string, Net.t.uint8)
```

### `optional(type: DataType)`
Represents a value that might be `nil`.
```lua
Net.t.optional(Net.t.vec3)
```

## Optimized Types

| Type | Description | Optimization |
| :--- | :--- | :--- |
| `varint` | Variable-length integer | Smaller numbers take fewer bytes. |
| `float16` | Half-precision float | 2 bytes instead of 4. |
| `vec3q` | Quantized Vector3 | Compressed position data. |
| `cframeq` | Quantized CFrame | Compressed rotation/translation data. |
| `bitfield` | Bit-packed booleans | Pack up to 8 booleans into 1 byte. |
| `string_interned` | Cached String | Sends the full string only once, uses a tiny index for subsequent sends. |
| `auto` | Dynamic Type | Automatically detects the type of the value at runtime. Supports primitives, Roblox types, and recursive tables. Has overhead. |

## Roblox Types

NetFlow supports standard Roblox engine types for convenience.

*   `inst`: Roblox Instance.
*   `cframe`: Roblox CFrame.
*   `color3`: Roblox Color3.
*   `vec2`: Roblox Vector2.
*   `vec3`: Roblox Vector3 (use `t.vec3`, not `t.vector3`).

## Example Usage

```lua
local Net = require(path.to.NetFlow)

local MyPacket = Net.define_packet({
    value = Net.t.struct({
        Players = Net.t.array(Net.t.string),
        Score = Net.t.varint,
        IsGameOver = Net.t.bitfield({ "WinnerFound", "Draw" })
    })
})(101)
```

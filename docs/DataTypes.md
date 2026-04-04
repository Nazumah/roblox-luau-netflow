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
| `unknown` | For values with unknown types | Dynamic |

## Complex Types

You can combine primitives to create more complex data structures.

### `struct`
A collection of named fields with defined types. Useful for sending objects.
```lua
Net.t.struct({
    Id = Net.t.uint16,
    Name = Net.t.string
})
```

### `array`
A list of elements of the same type.
```lua
Net.t.array(Net.t.uint32)
```

### `map`
A set of key-value pairs.
```lua
Net.t.map(Net.t.string, Net.t.uint8)
```

### `optional`
Represents a value that might be `nil`.
```lua
Net.t.optional(Net.t.vec3)
```

## Optimized Types

These types are specifically designed for games to minimize network footprint.

| Type | Description | Optimization |
| :--- | :--- | :--- |
| `varint` | Variable-length integer | Smaller numbers take fewer bytes. |
| `float16` | Half-precision float | 2 bytes instead of 4. |
| `vec3q` | Quantized Vector3 | Compressed position data. |
| `cframeq` | Quantized CFrame | Compressed rotation/translation data. |
| `bitfield` | Bit-packed booleans | Pack up to 8 booleans into 1 byte. |

## Roblox Types

NetFlow supports standard Roblox engine types for convenience.

*   `inst`: Roblox Instance.
*   `cframe`: Roblox CFrame.
*   `color3`: Roblox Color3.
*   `vec2`: Roblox Vector2.
*   `vec3`: Roblox Vector3.

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

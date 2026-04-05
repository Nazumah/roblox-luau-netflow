# NetFlow Data Types (`Net.t`)

NetFlow provides a strictly typed serialization system designed for maximum efficiency.

## Atomic Types

| Type | Size | Description |
|------|------|-------------|
| `Net.t.bool` | 1 bit | Boolean value packed into bitfields. |
| `Net.t.uint8` | 1 byte | Unsigned integer (0–255). |
| `Net.t.uint16` | 2 bytes | Unsigned integer (0–65,535). |
| `Net.t.uint32` | 4 bytes | Unsigned integer (0–4.29B). |
| `Net.t.int8` | 1 byte | Signed integer (-128–127). |
| `Net.t.int16` | 2 bytes | Signed integer (-32,768–32,767). |
| `Net.t.int32` | 4 bytes | Signed integer (-2.14B–2.14B). |
| `Net.t.float32` | 4 bytes | Standard precision float. |
| `Net.t.float64` | 8 bytes | Double precision float. |
| `Net.t.string` | Var | UTF-8 encoded string. |

## Spatial Types

| Type | Size | Description |
|------|------|-------------|
| `Net.t.vec2` | 8 bytes | Vector2 (2x float32). |
| `Net.t.vec3` | 12 bytes | Vector3 (3x float32). |
| `Net.t.cframe` | 48 bytes | Standard Roblox CFrame. |
| `Net.t.color3` | 3 bytes | Color3 (packed as 8-bit RGB). |

## Composite Types

### `Net.t.struct(fields: { [string]: DataType })`
Serializes a table with fixed keys. Keys are not sent over the wire, only values in order.

### `Net.t.array(elementType: DataType)`
Variable length array of the specified type.

### `Net.t.map(keyType: DataType, valueType: DataType)`
A dictionary containing keys and values of the specified types.

---

## Specialized Optimizations

### `Net.t.bitfield(fields: { [string]: number })`
Combines multiple boolean or small integer fields into a single byte-aligned block. Extremely efficient for state syncing.

### `Net.t.enum(choices: { string })`
Maps strings to their indices in the array, sending only a small integer over the wire.

### `Net.t.varint`
Variable-length integer prefixing for optimal distribution.

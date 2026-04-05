# Why Use NetFlow?

When developing large-scale projects in Roblox, one of the most common bottlenecks is **Network Bandwidth** and **Latency**. The default `RemoteEvent` is extremely convenient but incurs significant overhead when transmitting complex data.

NetFlow is designed to solve these issues and provide optimal network performance by leveraging Luau's buffer library.

## Problems with Standard RemoteEvents

1. **High Data Usage**: The default serialization in Roblox is flexible but inefficient. For example, sending a single number between 0 and 100 might consume more bytes than necessary pointlessly.
2. **Serialization Overhead**: When sending complex tables via `RemoteEvent`, the engine traverses and transforms the table every single time, which adds CPU overhead.
3. **Lack of Type Safety**: Standard remotes don't enforce what data can be sent, leading to runtime errors and difficult-to-maintain code.

## Key Advantages of NetFlow

### 1. Buffer-Based Serialization
NetFlow interacts directly with Luau's `buffer` library, controlling data at the byte level. This approach is significantly faster than table-based transmission and drastically reduces bandwidth consumption.

### 2. Variable-Length Encoding (Varint)
Instead of using a fixed 8 bytes for every number, `varint` allows small numbers to be transmitted using as little as 1 byte.

### 3. Highly Optimized Custom Types
- **`float16`**: Uses 2 bytes instead of 4 for decimal data.
- **`vec3q`, `cframeq`**: Applies quantization techniques to compress position and rotation info by more than 50%.
- **`bitfield`**: Packs multiple booleans into a single byte.
- **`string_interned`**: Sends the full string only once and uses a index for subsequent sends.

### 4. Zero-Allocation Response Processing
NetFlow uses a custom coroutine reuse system to process incoming packets. This prevents the constant memory allocation and Garbage Collection (GC) spikes common in other libraries.

### 5. Stable Network Namespacing
Hashed string-based namespaces allow for automatic ID generation and collision-free organization across server and client.

## Code Comparison

### Standard Roblox RemoteEvent
```lua
RemoteEvent:FireAllClients({
    Position = Vector3.new(10, 20, 30),
    Health = 100,
    IsActive = true,
    Name = "Player1"
})
```

### Using NetFlow
```lua
local Net = require(path.to.NetFlow)
local PlayerNamespace = Net.namespace("Players")

local PlayerUpdate = PlayerNamespace("Update", {
    value = Net.t.struct({
        Position = Net.t.vec3,
        Health = Net.t.uint8,
        IsActive = Net.t.bool,
        Name = Net.t.string_interned
    })
})

PlayerUpdate.sendToAll({
    Position = Vector3.new(10, 20, 30),
    Health = 100,
    IsActive = true,
    Name = "Player1"
})
```

---

NetFlow is the ultimate choice for developers who need to guarantee network performance in complex environments.

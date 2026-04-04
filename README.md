# NetFlow

**NetFlow** is a high-performance, buffer-based networking library for Luau on Roblox. It is designed to provide ultra-low bandwidth usage and extreme serialization performance by leveraging the power of Luau's `buffer` library.

## Why NetFlow?

Standard `RemoteEvent` serialization in Roblox can be a bottleneck for complex games. NetFlow overcomes these limitations by:

-   **Reducing Bandwidth**: Using custom types like `varint`, `float16`, and quantized vectors (`vec3q`) to pack data into the smallest possible byte representation.
-   **Blazing Fast Performance**: Direct buffer manipulation avoids the overhead of table traversal and transformation.
-   **Type Safety**: Catch data format issues early with pre-defined packet structures.
-   **Bandwidth Insight**: Real-time bandwidth monitoring to track exactly how much data your game is sending and receiving.

## Installation

### Wally
Add the dependency to your `wally.toml`:
```toml
[dependencies]
NetFlow = "nazumah/roblox-luau-netflow@0.1.0"
```

### Rojo
You can also clone this repository and include the `src` folder in your project.

## Quick Start

### 1. Initialize and Define Packets
Create a shared module to define your network packets.

```lua
local Net = require(path.to.NetFlow)

local Packets = {
    PlayerUpdate = Net.define_packet({
        reliability = "Unreliable",
        value = Net.t.struct({
            Position = Net.t.vec3,
            Health = Net.t.uint8,
        })
    })(1), -- Unique ID
}

return Packets
```

### 2. Sending Data (Server)
```lua
local Packets = require(path.to.Packets)

Packets.PlayerUpdate.sendToAll({
    Position = Vector3.new(10, 20, 30),
    Health = 100
})
```

### 3. Listening for Data (Client)
```lua
local Packets = require(path.to.Packets)

Packets.PlayerUpdate.listen(function(data)
    print("Received update:", data.Position, data.Health)
end)
```

## Documentation

For more detailed information, check out the [docs](docs/) directory:

-   [Why Use NetFlow?](docs/WhyUseNetFlow.md)
-   [Supported Data Types](docs/DataTypes.md)

## License
Licensed under the MIT License.
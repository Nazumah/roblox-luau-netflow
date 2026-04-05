# NetFlow

[![Wally](https://img.shields.io/badge/Wally-1.7.3-blue.svg)](https://wally.run/package/nazumah/netflow)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Luau](https://img.shields.io/badge/Luau-Strict-blueviolet.svg)](https://luau-lang.org/)

NetFlow is a high-performance, buffer-based networking library for Luau on Roblox. It is designed to provide ultra-low bandwidth usage and extreme serialization speeds by leveraging the power of Luau's `buffer` library.

---

## Performance

Standard `RemoteEvent` serialization in Roblox can be a major network bottleneck. NetFlow delivers up to **3.3x lower bandwidth usage** and faster processing by:

- **Binary Serialization**: Pack data into bits and bytes instead of expensive Roblox variants.
- **Zero-Copy Logic**: Direct buffer manipulation avoids the overhead of constant table creation.
- **Strict Schemas**: Define exactly how your data is structured for maximum efficiency.
- **Stable Identification**: Namespaced packets use 2-byte hashes instead of long strings.

---

## Installation

### Wally
Add the dependency to your `wally.toml`:

```toml
[dependencies]
NetFlow = "nazumah/netflow@1.7.3"
Async = "nazumah/async@1.0.2"
```

---

## Quick Start

### 1. Define Namespaced Packets
```lua
local Net = require(path.to.NetFlow)

-- Create a namespace for your feature
local ns = Net.namespace("UnitSystem")

-- Define packets with precise types
local Packets = {
    PositionUpdate = ns("Update", {
        value = Net.t.struct({
            Id = Net.t.uint32,
            Pos = Net.t.vec3,
        }),
        reliability = "Unreliable",
    })
}

return Packets
```

### 2. Sending Data (Server)
```lua
local Packets = require(path.to.Packets)

Packets.PositionUpdate.sendToAll({
    Id = 12345,
    Pos = Vector3.new(10, 20, 30)
})
```

### 3. Listening for Data (Client)
```lua
local Packets = require(path.to.Packets)

Packets.PositionUpdate.listen(function(data)
    print("Unit", data.Id, "moved to", data.Pos)
end)
```

---

## Documentation

For further technical specifications, please see:

- [Why Use NetFlow?](docs/WhyUseNetFlow.md)
- [Supported Data Types](docs/DataTypes.md)
- [API Reference](docs/API.md)

---

## License
This project is licensed under the [MIT](LICENSE) License.
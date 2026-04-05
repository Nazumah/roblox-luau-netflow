# NetFlow

[![Wally](https://img.shields.io/badge/Wally-1.7.5-blue.svg)](https://wally.run/package/nazumah/netflow)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Luau](https://img.shields.io/badge/Luau-Strict-blueviolet.svg)](https://luau-lang.org/)

NetFlow is an ultra-high performance, buffer-based networking library for Luau on Roblox. By bypassing standard `RemoteEvent` serialization and using binary buffers, NetFlow achieves extreme bandwidth efficiency and processing speed.

---

## Technical Advantages

- **Hashed Namespacing**: Uses 2-byte hashes for packet identification, eliminating string overhead and providing stable IDs across server and client.
- **Buffer-Level Control**: Direct manipulation of Luau `buffer` objects ensures zero-copy serialization for primitive and complex types.
- **3.3x Lower Bandwidth**: Real-world benchmarks show up to 3.3x reduction in network traffic compared to standard Roblox remotes.
- **First-Class IntelliSense**: Unlike other networking libraries, NetFlow provides explicit type exports for its entire API, including the `Net.t` type-checking library.
- **Async Integration**: Native support for request-response patterns using the [Async](https://github.com/Nazumah/roblox-luau-async) library.

---

## Installation

### Wally
Update your `wally.toml`:

```toml
[dependencies]
NetFlow = "nazumah/netflow@1.7.5"
Async = "nazumah/async@1.0.4"
```

---

## Quick Start

### 1. Define a Packet
```lua
local Net = require(path.to.NetFlow)
local ns = Net.namespace("Combat")

local DamagePacket = ns("Damage", {
    value = Net.t.struct({
        TargetId = Net.t.uint32,
        Amount = Net.t.float32,
    }),
    reliability = "Unreliable"
})
```

### 2. Communicating
```lua
-- On Server
DamagePacket.sendToAll({ TargetId = 1, Amount = 25.5 })

-- On Client
DamagePacket.listen(function(data)
    print("Received damage:", data.Amount)
end)
```

---

## Documentation

- [Why Use NetFlow?](docs/WhyUseNetFlow.md)
- [Supported Data Types](docs/DataTypes.md)
- [API Reference](docs/API.md)

---

## License
Licensed under the [MIT](LICENSE) License.
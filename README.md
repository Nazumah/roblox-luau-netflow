# NetFlow
### Fast, typed, and hassle-free networking for Roblox.

NetFlow is a networking library for Roblox that makes your game faster and your code cleaner. It uses binary serialization (via ByteNet) to keep packets tiny, while giving you strict Luau types so you don't have to guess what's in your data.

---

## Why NetFlow?

- **Actually Fast**: Ditch the heavy JSON-like overhead of standard RemoteEvents. We use Buffers to keep network usage minimal.
- **Type Safety**: Full Luau auto-completion. If your packet has a `health` field, your IDE will know it's a number.
- **Better Invocations**: Forget the flaky `RemoteFunction`. Our `Async` patterns make request-response reliable and safe.

---

## Quick Start

### 1. Define your packets
Create a shared module to keep your network schema in one place.

```lua
local NetFlow = require(path.to.netflow)
local t = NetFlow.t

local Packets = {
    -- One-way: Player movement (Unreliable for performance)
    Move = NetFlow.define_packet({
        value = t.struct({
            pos = t.vec3,
            look = t.vec2,
        }),
        reliability = "Unreliable"
    })(1),

    -- Two-way: Get player stats
    GetStats = NetFlow.define_invoke({
        request = t.string,
        response = t.struct({
            wins = t.uint32,
            level = t.uint16,
        })
    })(2, 3)
}

return Packets
```

### 2. Usage (Server & Client)

**On the Server:**
```lua
Packets.Move.listen(function(data, player)
    print(player.Name .. " moved to " .. tostring(data.pos))
end)

Packets.GetStats.setCallback(function(player, name)
    return { wins = 10, level = 5 }
end)
```

**On the Client:**
```lua
Packets.Move.send({
    pos = Vector3.new(0, 5, 0),
    look = Vector2.new(1, 0)
})

Packets.GetStats.invokeServer("Hyese"):andThen(function(stats)
    print("Level: " .. stats.level)
end)
```

---

## Supported Types
`uint8/16/32`, `int8/16/32`, `float32/64`, `string`, `bool`, `vec2/vec3`, `cframe`, `color3`, `struct`, `array`, `map`.

---

## 한글 요약 (Korean Summary)
NetFlow는 Roblox에서 **빠르고 안전한 네트워킹**을 구현하기 위한 모듈입니다.
- **성능**: 버퍼 기반 이진 직렬화로 패킷 크기를 최소화합니다.
- **타입**: Luau 타입 시스템을 지원해 자동 완성이 완벽합니다.
- **Invoke**: 비동기 요청-응답을 안전하게 처리합니다.

---

## License
MIT. Use it for whatever you want.

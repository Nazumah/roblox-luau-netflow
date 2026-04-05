# NetFlow API Reference

This document provides the technical specification for the **NetFlow** library.

## Core API

### `Net.namespace(name: string) -> Namespace`
Creates a new communication namespace. This provides stable, hashed identification for all packets defined within it.

### `Namespace(name: string, props: PacketProps) -> Packet | Invoke`
Defines a packet or remote procedure call (Invoke) within the namespace.
- If `props` has `value`, a **Packet** is created.
- If `props` has `request` and `response`, an **Invoke** is created.

---

## Packet Interface

### Server Members
- `:sendTo(data: T, player: Player)`
- `:sendToList(data: T, players: {Player})`
- `:sendToAll(data: T)`
- `:sendToAllExcept(data: T, except: Player)`

### Client Members
- `:send(data: T)`

### Shared Members
- `:listen(callback: (data: T, player: Player?) -> ()) -> DisconnectFunc`
- `:once(callback: (data: T, player: Player?) -> ()) -> DisconnectFunc`
- `:wait() -> (T, Player?)`

---

## Invoke Interface

### Client Members
- `:invokeServer(data: Req) -> Async<Res>`

### Server Members
- `:invokeClient(player: Player, data: Req) -> Async<Res>`

### Shared Members
- `:setCallback(callback: (player: Player?, data: Req) -> Res)`

---

## Middleware & Monitoring

### `Net.middleware`
- `addIncoming(fn: (packetId: number, data: any, player: Player?) -> boolean)`
- `addOutgoing(fn: (packetId: number, data: any, player: Player?) -> boolean)`

### `Net.bandwidth`
- `get_stats() -> BandwidthStats` (Returns `bytes_in`, `bytes_out`, etc.)

---

## Data Types (`Net.t`)

NetFlow includes a comprehensive type-checking and serialization library:
- **Primitives**: `uint8`, `uint16`, `uint32`, `int8`, `float32`, `string`, `bool`, etc.
- **Spatial**: `vec2`, `vec3`, `cframe`, `color3`.
- **Composite**: `struct`, `array`, `map`, `tuple`, `optional`.
- **Advanced**: `bitfield`, `varint`, `float16`, `enum`.

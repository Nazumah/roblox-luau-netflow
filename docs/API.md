# API Reference

This page documents the full API surface of **NetFlow**.

## Core Functions

### `Net.namespace(name: string)`
Creates a new namespace object for organizing related packets. Namespaces provide stable, hashed packet IDs automatically.

**Returns:** A `Namespace` callable table.

### `Namespace(packetName: string, props: PacketProps)`
Calling a namespace like a function defines a packet within that namespace.
- If `props` has `value`, it creates a standard **Packet**.
- If `props` has `request` and `response`, it creates an **Invoke**.

```lua
local Combat = Net.namespace("Combat")
local DamagePacket = Combat("Damage", { value = Net.t.uint16 })
```

---

## Packet Methods

When you define a standard packet, it returns a `Packet` object with the following methods:

### Server-Only
-   **`sendTo(data: T, player: Player)`**: Sends a packet to a specific player.
-   **`sendToList(data: T, players: {Player})`**: Sends a packet to a list of players.
-   **`sendToAll(data: T)`**: Sends a packet to everyone.
-   **`sendToAllExcept(data: T, except: Player)`**: Sends a packet to everyone except one player.

### Client-Only
-   **`send(data: T)`**: Sends a packet to the server.

### Shared
-   **`listen(callback: (data: T, player: Player?) -> ())`**: Connects a listener function. Returns a disconnect function.
-   **`once(callback: (data: T, player: Player?) -> ())`**: Listens for the next packet then disconnects.
-   **`wait() -> (T, Player?)`**: Yields the current thread until data is received.

---

## Invoke Methods

Defined when providing `request` and `response` schema. Used for request-response patterns.

### Client-Only
-   **`invokeServer(data: Req) -> Async<Res>`**: Calls a server-side callback and waits (async) for a response.

### Server-Only
-   **`invokeClient(player: Player, data: Req) -> Async<Res>`**: Calls a client-side callback and waits for a response.

### Shared
-   **`setCallback(callback: (player: Player?, data: Req) -> Res)`**: Defines the handler for incoming requests.

---

## Middleware

Middleware allows you to intercept every packet being sent or received.

### `Net.middleware.addIncoming(fn: (packetId: number, data: any, player: Player?) -> boolean)`
Adds a listener for incoming data. If the function returns `false`, the packet is dropped.

### `Net.middleware.addOutgoing(fn: (packetId: number, data: any, player: Player?) -> boolean)`
Adds a listener for outgoing data. If the function returns `false`, the packet is not sent.

---

## Bandwidth Monitoring

### `Net.bandwidth.get_stats() -> BandwidthStats`
Returns an object containing bandwidth usage information for the current session.

```lua
local stats = Net.bandwidth.get_stats()
print(stats.bytes_in, stats.bytes_out)
```

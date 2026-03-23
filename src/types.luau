export type ChannelState = {
	buff: buffer,
	cursor: number,
	size: number,
	references: { unknown },
}

export type PacketProps<T> = {
	value: T,
	reliability: ("Reliable" | "Unreliable")?,
	max_per_frame: number?,
}

export type DataType<T> = {
	__T: T,
	write: (value: T) -> (),
	read: (b: buffer, cursor: number) -> (T, number),
	length: number?,
}

export type Packet<T> = {
	sendTo: (data: T, player: Player) -> (),
	sendToList: (data: T, players: { Player }) -> (),
	sendToAll: (data: T) -> (),
	sendToAllExcept: (data: T, except: Player) -> (),
	send: (data: T) -> (),
	listen: (callback: (data: T, player: Player?) -> ()) -> (() -> ()),
	once: (callback: (data: T, player: Player?) -> ()) -> (() -> ()),
	wait: () -> (T, Player?),
}

export type BandwidthStats = {
	bytes_out: number,
	bytes_in: number,
	packets_out: number,
	packets_in: number,
}

return nil

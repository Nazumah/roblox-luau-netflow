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

type Packet<T> = {
	send_to_all: (data: T) -> (),
	send_to: (data: T, target: Player) -> (),
	send_to_list: (data: T, targets: { Player }) -> (),
	send_to_all_except: (data: T, exception: Player) -> (),

	wait: () -> T,
	send: (data: T, target: Player?) -> (),
	listen: (callback: (data: T, player: Player?) -> ()) -> (),
}

return nil

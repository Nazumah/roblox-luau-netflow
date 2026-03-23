local current_references: { [number]: unknown }?

local readRefs = {}

function readRefs.set(refs: { [number]: unknown }?)
	current_references = refs
end

function readRefs.get(idx: number): unknown
	if not current_references then
		error("No references set")
	end
	return current_references[idx]
end

function readRefs.getAll(): { [number]: unknown }?
	return current_references
end

return readRefs

.pragma library

function path(resource, id) {
    return "/database/" + resource + (id === undefined ? "" : "/" + encodeURIComponent(String(id)))
}

function listPath(resource, limit, offset) {
    return path(resource) + (limit ? "?limit=" + limit + "&offset=" + offset : "")
}

function records(data) {
    if (!data || typeof data !== "object" || !Number.isInteger(data.length) || data.length < 0)
        return null

    const records = Array.from(data)
    return records.every(record => record && typeof record === "object" && "id" in record) ? records : null
}

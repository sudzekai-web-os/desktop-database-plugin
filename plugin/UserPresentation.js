.pragma library

function roleLabel(role) {
    const labels = { Administrator: "Администратор", User: "Пользователь", Viewer: "Наблюдатель" }
    return labels[role] || role || ""
}

function supportsBlocking(version) {
    const parts = version.split(".").map(Number)
    return parts.length === 3 && (parts[0] > 0 || parts[1] > 2 || (parts[1] === 2 && parts[2] >= 2))
}

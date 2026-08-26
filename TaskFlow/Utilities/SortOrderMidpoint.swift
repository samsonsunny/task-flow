import Foundation

private let alphabet = Array("abcdefghijklmnopqrstuvwxyz")

private func charValue(_ c: Character) -> Int {
    alphabet.firstIndex(of: c) ?? -1
}

private func charFrom(_ value: Int) -> Character {
    alphabet[max(0, min(25, value))]
}

func midpoint(between lower: String?, and upper: String?) -> String? {
    if lower == nil && upper == "" { return nil }

    let lowChars = Array(lower ?? "")
    let upChars = upper.map(Array.init)
    var result = ""

    for i in 0... {
        let lv = i < lowChars.count ? charValue(lowChars[i]) : -1
        let uv: Int
        if let upChars, i < upChars.count {
            uv = charValue(upChars[i])
        } else {
            uv = 26
        }

        if uv - lv > 1 {
            result.append(charFrom(lv + (uv - lv) / 2))
            return result
        }

        if uv - lv == 1 && lv == -1 && uv == 0 {
            if let upChars, i + 1 < upChars.count {
                result.append("a")
                continue
            }
            return nil
        }

        result.append(charFrom(lv))
    }

    return nil
}

func widen(_ bound: String) -> String {
    bound + "z"
}

func isBetween(_ value: String, lower: String?, upper: String?) -> Bool {
    if let lower, let upper {
        return lower < value && value < upper
    } else if let lower {
        return lower < value
    } else if let upper {
        return value < upper
    }
    return true
}

func midpointOrWiden(between lower: String?, and upper: String?) -> String {
    if let result = midpoint(between: lower, and: upper) {
        return result
    }
    if let upper {
        let widened = widen(upper)
        return midpointOrWiden(between: lower, and: widened)
    } else {
        return (lower ?? "m") + "z"
    }
}

func repairNilSortOrders(_ tasks: [TaskItem]) {
    let nilTasks = tasks.filter { $0.sortOrder == nil }
    guard !nilTasks.isEmpty else { return }
    let sorted = nilTasks.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    var previous: Int = -1
    for task in sorted {
        previous += 1
        task.sortOrder = previous
    }
}

// MARK: - Int Sort Order Utilities (for TaskItem)

func recalculateSortOrders(for tasks: [TaskItem]) {
    for (index, task) in tasks.enumerated() {
        task.sortOrder = index
    }
}

func nextSortOrder(for tasks: [TaskItem]) -> Int {
    (tasks.compactMap { $0.sortOrder }.max() ?? -1) + 1
}

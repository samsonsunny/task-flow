import Foundation

private let alphabet = Array("abcdefghijklmnopqrstuvwxyz")

private func charValue(_ c: Character) -> Int {
    alphabet.firstIndex(of: c) ?? -1
}

private func charFrom(_ value: Int) -> Character {
    alphabet[max(0, min(25, value))]
}

func midpoint(between lower: String?, and upper: String?) -> String? {
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
            return nil
        }

        result.append(charFrom(lv))
    }

    return nil
}

func widen(_ bound: String) -> String {
    bound + "z"
}

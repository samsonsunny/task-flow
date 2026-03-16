extension String {
    func trimmingTrailingNewlines() -> String {
        var result = self
        while result.last?.isNewline == true {
            result.removeLast()
        }
        return result
    }
}


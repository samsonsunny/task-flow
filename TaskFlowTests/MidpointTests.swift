import Testing
@testable import TaskFlow

@Test func midpointBothNil() throws {
    let result = midpoint(between: nil, and: nil)
    #expect(result == "m")
}

@Test func midpointNoLower() throws {
    let result = try #require(midpoint(between: nil, and: "m"))
    #expect(result < "m")
}

@Test func midpointNoUpper() throws {
    let result = try #require(midpoint(between: "a", and: nil))
    #expect(result > "a")
}

@Test func midpointAdjacentLetters() throws {
    let result = try #require(midpoint(between: "a", and: "b"))
    #expect(result > "a")
    #expect(result < "b")
}

@Test func midpointWithinWord() throws {
    let result = try #require(midpoint(between: "a", and: "am"))
    #expect(result > "a")
    #expect(result < "am")
}

@Test func midpointLongerStrings() throws {
    let result = try #require(midpoint(between: "an", and: "b"))
    #expect(result > "an")
    #expect(result < "b")
}

@Test func midpointPrefixEdge() throws {
    let result = try #require(midpoint(between: "m", and: "mc"))
    #expect(result > "m")
    #expect(result < "mc")
}

@Test func midpointChainProducesAscendingOrder() throws {
    let a = try #require(midpoint(between: nil, and: nil))
    let b = try #require(midpoint(between: a, and: nil))
    let c = try #require(midpoint(between: b, and: nil))
    let d = try #require(midpoint(between: c, and: nil))
    let sorted = [d, c, b, a].sorted()
    #expect(sorted == [a, b, c, d])
}

@Test func midpointReturnsNilForImpossibleGap() throws {
    let result = midpoint(between: "f", and: "fa")
    #expect(result == nil)
}

@Test func midpointAfterWidenWorks() throws {
    let widened = widen("fa")
    #expect(widened == "faz")
    let result = try #require(midpoint(between: "f", and: widened))
    #expect(result > "f")
    #expect(result < widened)
}

// MARK: - Edge cases

@Test func midpointNilAndEmptyString() throws {
    let result = midpoint(between: nil, and: "")
    #expect(result == nil)
}

@Test func midpointExhaustionChainWidensPreservingOrder() throws {
    let lower: String? = nil
    var upper: String? = "z"
    var results: [String] = []
    for _ in 0..<20 {
        if let m = midpoint(between: lower, and: upper) {
            results.append(m)
            upper = m
        } else {
            upper = widen(upper!)
            if let m = midpoint(between: lower, and: upper) {
                results.append(m)
                upper = m
            }
        }
    }
    #expect(results.count == 20)
}

@Test func midpointReturnsNilForImpossibleGapRecovery() throws {
    let result = midpoint(between: "f", and: "fa")
    #expect(result == nil)
    let widened = widen("fa")
    let recovered = try #require(midpoint(between: "f", and: widened))
    #expect(recovered > "f")
    #expect(recovered < widened)
}

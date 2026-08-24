import Foundation

/// A deterministic random source.
///
/// Two things depend on this. Code Minute has to produce the same five
/// questions on every device without a server telling it to, and
/// `CalcGenerator` has to be reproducible under test so a seeded run can be
/// checked against known answers.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9e3779b97f4a7c15 : seed
    }

    mutating func next() -> UInt64 {
        // xorshift64*, chosen because it is short enough to read and verify.
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2685821657736338717
    }
}

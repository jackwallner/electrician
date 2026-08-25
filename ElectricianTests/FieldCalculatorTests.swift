import XCTest
@testable import Electrician

final class FieldCalculatorTests: XCTestCase {

    func testAmpacityMatchesTheExamOrderOfOperations() throws {
        // 12 AWG Cu THHN, 75 C terminals, 40 C ambient, 6 current-carrying.
        // 90 C table 30 A * 0.91 * 0.80 = 21.84, then 75 C cap 25 A, then
        // 240.4(D) cap 20 A.
        let result = FieldCalculators.ampacity(
            size: "12 AWG",
            material: .copper,
            insulation: .c90,
            termination: .c75,
            ambientCelsius: 40,
            currentCarrying: 6
        )
        let unwrapped = try XCTUnwrap(result)
        XCTAssertEqual(unwrapped.tableAmps, 30)
        XCTAssertEqual(unwrapped.ambientFactor, 0.91, accuracy: 0.0001)
        XCTAssertEqual(unwrapped.adjustment, 0.80, accuracy: 0.0001)
        XCTAssertEqual(unwrapped.afterDerate, 21.84, accuracy: 0.001)
        XCTAssertEqual(unwrapped.terminationCap, 25)
        XCTAssertEqual(unwrapped.smallConductorCeiling, 20)
        XCTAssertEqual(unwrapped.allowable, 21.84, accuracy: 0.001)
        XCTAssertEqual(unwrapped.ocpdCeiling, 20, accuracy: 0.001)
    }

    func testConduitFillRejectsTheSizeThatFailsFortyPercent() throws {
        // 9 of 12 AWG THHN in 1/2" EMT: 9 * 0.0133 = 0.1197, 40% of 0.304 is
        // 0.1216, so it fits, and 1/2" is the smallest that does.
        let half = FieldCalculators.conduitFill(
            conductorSize: "12 AWG", count: 9, tradeSize: "1/2\""
        )
        XCTAssertEqual(try XCTUnwrap(half).fits, true)
        XCTAssertEqual(try XCTUnwrap(half).smallestFitting, "1/2\"")

        // 12 of 12 AWG: 0.1596 vs 0.1216, 1/2" fails, 3/4" is the next size.
        let packed = FieldCalculators.conduitFill(
            conductorSize: "12 AWG", count: 12, tradeSize: "1/2\""
        )
        let unwrapped = try XCTUnwrap(packed)
        XCTAssertFalse(unwrapped.fits)
        XCTAssertEqual(unwrapped.smallestFitting, "3/4\"")
    }

    func testVoltageDropMatchesTheGeneratorFormula() throws {
        let cm = try XCTUnwrap(NECTables.circularMils["10 AWG"])
        let expected = Phase.single.voltageDropFactor
            * ConductorMaterial.copper.voltageDropK
            * 16 * 100 / cm
        let result = FieldCalculators.voltageDrop(
            size: "10 AWG",
            material: .copper,
            phase: .single,
            systemVolts: 120,
            amps: 16,
            oneWayFeet: 100
        )
        let unwrapped = try XCTUnwrap(result)
        XCTAssertEqual(unwrapped.volts, expected, accuracy: 0.0001)
        XCTAssertEqual(unwrapped.percent, expected / 120 * 100, accuracy: 0.0001)
    }

    func testOhmsLawFromAnyPair() throws {
        let vi = try XCTUnwrap(FieldCalculators.ohmsLaw(volts: 120, amps: 10, ohms: nil, watts: nil))
        XCTAssertEqual(vi.ohms, 12, accuracy: 0.0001)
        XCTAssertEqual(vi.watts, 1200, accuracy: 0.0001)

        let vr = try XCTUnwrap(FieldCalculators.ohmsLaw(volts: 120, amps: nil, ohms: 12, watts: nil))
        XCTAssertEqual(vr.amps, 10, accuracy: 0.0001)

        let rp = try XCTUnwrap(FieldCalculators.ohmsLaw(volts: nil, amps: nil, ohms: 12, watts: 1200))
        XCTAssertEqual(rp.volts, 120, accuracy: 0.0001)
        XCTAssertEqual(rp.amps, 10, accuracy: 0.0001)

        XCTAssertNil(FieldCalculators.ohmsLaw(volts: 120, amps: nil, ohms: nil, watts: nil))
        XCTAssertNil(FieldCalculators.ohmsLaw(volts: 0, amps: 10, ohms: nil, watts: nil))
    }

    /// A consistent over-specified circuit is not a conflict. Someone who fills
    /// in all four correct values should not be told they got something wrong.
    func testOhmsLawAcceptsConsistentExtraInputs() throws {
        let all = try XCTUnwrap(FieldCalculators.ohmsLaw(volts: 120, amps: 10, ohms: 12, watts: 1200))
        XCTAssertTrue(all.isConsistent, "reported \(all.conflicts)")
        XCTAssertEqual(all.basis, "V and I")
    }

    /// The one the tool used to get wrong: extra values that describe a
    /// DIFFERENT circuit were silently discarded, and the answer came back
    /// looking like the app had checked the work.
    func testOhmsLawReportsContradictoryInputs() throws {
        let conflicting = try XCTUnwrap(FieldCalculators.ohmsLaw(volts: 120, amps: 10, ohms: 5, watts: nil))
        XCTAssertEqual(conflicting.basis, "V and I")
        XCTAssertEqual(conflicting.ohms, 12, accuracy: 0.0001)
        XCTAssertEqual(conflicting.conflicts, ["R"])

        let twoWrong = try XCTUnwrap(FieldCalculators.ohmsLaw(volts: 120, amps: 10, ohms: 5, watts: 500))
        XCTAssertEqual(Set(twoWrong.conflicts), ["R", "P"])
    }

    /// Rounding is not a conflict. 12.0 Ω typed against a computed 11.999 Ω has
    /// to pass, or the warning fires constantly and gets ignored.
    func testOhmsLawToleratesRounding() throws {
        let rounded = try XCTUnwrap(FieldCalculators.ohmsLaw(volts: 120, amps: 10, ohms: 11.95, watts: nil))
        XCTAssertTrue(rounded.isConsistent, "reported \(rounded.conflicts)")
    }

    /// Each remaining pair solves the same circuit, and reports which pair it
    /// used. The `basis` string is shown to the reader, so it has to be right.
    func testOhmsLawNamesThePairItSolvedFrom() throws {
        XCTAssertEqual(try XCTUnwrap(FieldCalculators.ohmsLaw(volts: nil, amps: 10, ohms: 12, watts: nil)).basis, "I and R")
        XCTAssertEqual(try XCTUnwrap(FieldCalculators.ohmsLaw(volts: 120, amps: nil, ohms: nil, watts: 1200)).basis, "V and P")
        XCTAssertEqual(try XCTUnwrap(FieldCalculators.ohmsLaw(volts: nil, amps: 10, ohms: nil, watts: 1200)).basis, "I and P")
        XCTAssertEqual(try XCTUnwrap(FieldCalculators.ohmsLaw(volts: nil, amps: nil, ohms: 12, watts: 1200)).basis, "R and P")

        // V and P solves R the long way round; make sure it lands on the same
        // circuit the other pairs describe.
        let vp = try XCTUnwrap(FieldCalculators.ohmsLaw(volts: 120, amps: nil, ohms: nil, watts: 1200))
        XCTAssertEqual(vp.ohms, 12, accuracy: 0.0001)
        XCTAssertEqual(vp.amps, 10, accuracy: 0.0001)

        let ip = try XCTUnwrap(FieldCalculators.ohmsLaw(volts: nil, amps: 10, ohms: nil, watts: 1200))
        XCTAssertEqual(ip.ohms, 12, accuracy: 0.0001)
        XCTAssertEqual(ip.volts, 120, accuracy: 0.0001)
    }

    /// The assumptions are shown beside the voltage-drop result, and the 3%
    /// figure has to keep being described as a recommendation.
    func testVoltageDropStatesItsAssumptions() {
        XCTAssertFalse(FieldCalculators.VoltageDropResult.assumptions.isEmpty)
        for assumption in FieldCalculators.VoltageDropResult.assumptions {
            XCTAssertFalse(assumption.contains("—"), assumption)
        }
        XCTAssertTrue(FieldCalculators.VoltageDropResult.threePercentNote.contains("recommendation"))
    }
}

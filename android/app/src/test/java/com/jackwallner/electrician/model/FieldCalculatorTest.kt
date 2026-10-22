package com.jackwallner.electrician.model

import org.junit.Assert.*
import org.junit.Test

class FieldCalculatorTest {
    @Test fun examOrderDeratesBeforeTerminationAndSmallConductorCaps() {
        val result = checkNotNull(FieldCalculators.ampacity("12 AWG", ConductorMaterial.copper, TemperatureRating.c90, TemperatureRating.c75, 40, 6))
        assertEquals(30, result.tableAmps)
        assertEquals(0.91, result.ambientFactor, 1e-4)
        assertEquals(0.8, result.adjustment, 1e-4)
        assertEquals(21.84, result.afterDerate, 1e-3)
        assertEquals(25, result.terminationCap)
        assertEquals(20, result.smallConductorCeiling)
        assertEquals(21.84, result.allowable, 1e-3)
        assertEquals(20.0, result.ocpdCeiling, 1e-3)
    }

    @Test fun conduitFillFitsNineConductorsAndRejectsTwelveInHalfInchEmt() {
        val half = checkNotNull(FieldCalculators.conduitFill("12 AWG", 9, "1/2\""))
        assertTrue(half.fits)
        assertEquals("1/2\"", half.smallestFitting)
        assertEquals(0.1197 / 0.304, half.actualPercent, 1e-9)
        val packed = checkNotNull(FieldCalculators.conduitFill("12 AWG", 12, "1/2\""))
        assertFalse(packed.fits)
        assertEquals("3/4\"", packed.smallestFitting)
        assertNull(FieldCalculators.conduitFill("12 AWG", 0, "1/2\""))
    }

    @Test fun voltageDropMatchesSourceExampleAndKeepsItsAssumptions() {
        val result = checkNotNull(FieldCalculators.voltageDrop("10 AWG", ConductorMaterial.copper, Phase.single, 120.0, 16.0, 100.0))
        val expected = 2 * 12.9 * 16 * 100 / 10380
        assertEquals(expected, result.volts, 1e-4)
        assertEquals(expected / 120 * 100, result.percent, 1e-4)
        assertEquals(4, VoltageDropResult.assumptions.size)
        assertTrue(VoltageDropResult.threePercentNote.contains("recommendation"))
    }

    @Test fun ohmsLawSolvesAllSixPairsAndNamesTheBasis() {
        val inputs = listOf(
            listOf(120.0, 10.0, null, null), listOf(120.0, null, 12.0, null), listOf(null, 10.0, 12.0, null),
            listOf(120.0, null, null, 1200.0), listOf(null, 10.0, null, 1200.0), listOf(null, null, 12.0, 1200.0),
        )
        val basis = listOf("V and I", "V and R", "I and R", "V and P", "I and P", "R and P")
        inputs.zip(basis).forEach { (values, label) ->
            val result = checkNotNull(FieldCalculators.ohmsLaw(values[0], values[1], values[2], values[3]))
            assertEquals(label, result.basis)
            assertEquals(120.0, result.volts, 1e-4)
            assertEquals(10.0, result.amps, 1e-4)
            assertEquals(12.0, result.ohms, 1e-4)
            assertEquals(1200.0, result.watts, 1e-4)
        }
    }

    @Test fun contradictoryExtraInputsAreNamedWhileRoundedInputsPass() {
        assertTrue(checkNotNull(FieldCalculators.ohmsLaw(120.0, 10.0, 12.0, 1200.0)).isConsistent)
        assertEquals(listOf("R"), checkNotNull(FieldCalculators.ohmsLaw(120.0, 10.0, 5.0, null)).conflicts)
        assertEquals(listOf("R", "P"), checkNotNull(FieldCalculators.ohmsLaw(120.0, 10.0, 5.0, 500.0)).conflicts)
        assertTrue(checkNotNull(FieldCalculators.ohmsLaw(120.0, 10.0, 11.95, null)).isConsistent)
    }

    @Test fun oneInvalidOrSingleCircuitInputDoesNotInventAnAnswer() {
        assertNull(FieldCalculators.ohmsLaw(120.0, null, null, null))
        assertNull(FieldCalculators.ohmsLaw(0.0, 10.0, null, null))
        assertNull(FieldCalculators.ohmsLaw(Double.NaN, 10.0, null, null))
        assertNull(FieldCalculators.ohmsLaw(Double.POSITIVE_INFINITY, 10.0, null, null))
    }

    @Test fun equipmentGroundUsesTheNotExceedingBandAboveTheBreaker() {
        assertEquals("12 AWG", NECTables.equipmentGroundingConductor(20, ConductorMaterial.copper))
        assertEquals("8 AWG", NECTables.equipmentGroundingConductor(100, ConductorMaterial.copper))
        assertEquals("4 AWG", NECTables.equipmentGroundingConductor(200, ConductorMaterial.aluminum))
        assertEquals(60, NECTables.equipmentGroundingRow(45))
        assertEquals("10 AWG", NECTables.equipmentGroundingConductor(45, ConductorMaterial.copper))
        assertEquals("6 AWG", NECTables.equipmentGroundingConductor(175, ConductorMaterial.copper))
    }

    @Test fun electrodeUsesServiceMaterialAndParallelEquivalentArea() {
        assertEquals("4 AWG", NECTables.groundingElectrodeConductor("2/0 AWG", ConductorMaterial.copper, ConductorMaterial.copper))
        assertEquals("6 AWG", NECTables.groundingElectrodeConductor("2/0 AWG", ConductorMaterial.aluminum, ConductorMaterial.copper))
        assertEquals(NECTables.groundingElectrodeConductor("500 kcmil", ConductorMaterial.copper, ConductorMaterial.copper),
            NECTables.groundingElectrodeConductor("250 kcmil", ConductorMaterial.copper, ConductorMaterial.copper, 2))
    }

    @Test fun rodAndConcreteCeilingsOverrideTheServiceTable() {
        val rod = checkNotNull(NECTables.groundingElectrodeConductor("500 kcmil", ConductorMaterial.copper, ElectrodeType.rodPipePlate))
        assertEquals("1/0 AWG", rod.first)
        assertEquals("6 AWG", rod.second)
        assertEquals("4 AWG", checkNotNull(NECTables.groundingElectrodeConductor("500 kcmil", ConductorMaterial.copper, ElectrodeType.concreteEncased)).second)
        assertEquals("1/0 AWG", checkNotNull(NECTables.groundingElectrodeConductor("500 kcmil", ConductorMaterial.copper, ElectrodeType.waterPipe)).second)
    }

    @Test fun motorProtectionRoundsUpAndOverloadUsesNameplate() {
        assertEquals(14.0, checkNotNull(NECTables.motorFLC("10 hp", MotorSupply.three460)), 1e-9)
        assertEquals(35, NECTables.motorBranchOCPD(14.0, MotorProtection.inverseTimeBreaker))
        assertEquals(15.2, checkNotNull(NECTables.motorFLC("5 hp", MotorSupply.three230)), 1e-9)
        assertEquals(40, NECTables.motorBranchOCPD(15.2, MotorProtection.inverseTimeBreaker))
        assertEquals(20.0, NECTables.motorOverloadTrip(16.0, 1.15, null), 1e-3)
        assertEquals(18.4, NECTables.motorOverloadTrip(16.0, 1.0, null), 1e-3)
    }

    @Test fun higherMotorVoltageUsesLowerTableCurrent() {
        NECTables.motorRatings(MotorSupply.three460).forEach {
            val at460 = checkNotNull(NECTables.motorFLC(it.label, MotorSupply.three460))
            val at230 = NECTables.motorFLC(it.label, MotorSupply.three230) ?: return@forEach
            val at208 = NECTables.motorFLC(it.label, MotorSupply.three208) ?: return@forEach
            assertTrue(at230 > at460)
            assertTrue(at208 > at230)
        }
    }

    @Test fun lightingDemandAppliesBothThresholds() {
        assertEquals(2500.0, NECTables.generalLightingDemand(2500.0), 1e-3)
        assertEquals(5800.0, NECTables.generalLightingDemand(11000.0), 1e-3)
        assertEquals(43950.0, NECTables.generalLightingDemand(120000.0), 1e-3)
        assertEquals(48950.0, NECTables.generalLightingDemand(140000.0), 1e-3)
    }

    @Test fun rangesApplyColumnCAndMajorFractionOverTwelve() {
        assertEquals(8.0, checkNotNull(NECTables.rangeDemandKW(1, 8.0)), 1e-9)
        assertEquals(8.0, checkNotNull(NECTables.rangeDemandKW(1, 12.0)), 1e-9)
        assertEquals(9.6, checkNotNull(NECTables.rangeDemandKW(1, 16.0)), 1e-3)
        assertEquals(14.0, checkNotNull(NECTables.rangeDemandKW(3, 12.0)), 1e-9)
        assertEquals(15.4, checkNotNull(NECTables.rangeDemandKW(3, 14.0)), 1e-3)
        assertEquals(8.4, checkNotNull(NECTables.rangeDemandKW(1, 12.5)), 1e-3)
    }

    @Test fun appliancesNeedFourAndDwellingServiceHonorsItsFloor() {
        assertEquals(8000.0, NECTables.fastenedApplianceDemand(8000.0, 3), 1e-3)
        assertEquals(6000.0, NECTables.fastenedApplianceDemand(8000.0, 4), 1e-3)
        assertEquals(100, NECTables.dwellingServiceRating(42.0))
        assertEquals(150, NECTables.dwellingServiceRating(145.1))
    }

    @Test fun dwellingStandardAndOptionalExamplesRemainDistinct() {
        val result = checkNotNull(FieldCalculators.dwellingLoad(2000.0, 2, 1, 12.0, 1, 5500.0, listOf(4500.0, 1200.0, 900.0, 1000.0), 5000.0, 10000.0, largestRetainedMotorVA = 900.0))
        assertEquals(5625.0, result.generalAfterDemand, 1e-3)
        assertEquals(5700.0, result.applianceAfterDemand, 1e-3)
        assertEquals(35050.0, result.totalVA, 0.5)
        assertEquals(150, result.serviceRating)
        val optional = NECTables.optionalMethodGeneralLoad(35600.0)
        val hvac = NECTables.optionalMethodHVAC(5000.0, 10000.0, 1)
        assertEquals(20240.0, optional, 0.5)
        assertEquals(6500.0, hvac, 0.5)
        assertEquals(125, NECTables.dwellingServiceRating(NECTables.serviceAmps(optional + hvac)))
    }

    @Test fun boxFillCountsGroundsOnceAndDeviceYokesTwice() {
        val result = checkNotNull(FieldCalculators.boxFill(6, "12 AWG", 1, true, 3, "12 AWG"))
        assertEquals(22.5, result.required, 1e-3)
        assertEquals(25.3125, checkNotNull(FieldCalculators.boxFill(6, "12 AWG", 1, true, 9, "12 AWG")).required, 1e-4)
        assertNotNull(result.smallestBox)
        assertEquals(18.0, checkNotNull(NECTables.smallestBox(18.0)).cubicInches, 1e-9)
        assertNull(NECTables.smallestBox(999.0))
    }
}

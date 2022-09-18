library CumulativeMedicationDurationFHIR4Tests

using FHIR version '4.0.1'

include FHIRHelpers version '4.1.000'

include CumulativeMedicationDurationFHIR4 called CMD

context Patient

/*
# Example 1:
MedicationRequest 2 tabs 3x/day   #180/2
* dosage = 2
* frequency = 3x /day (i.e., repeats / period = day)
* supply = 180
* daysSupplied = 30 days
* refills = 2

derived daysSupplied = [supply (180) / ((dosage (2) x frequency (3))] = 30
daysSuppliedWithRefills = [supply (180) x (1 + refills (2)) / ((dosage (2) x frequency (3))] = 30 x 3 = 90 days
*/

/*
## Example 1a - boundsPeriod specified

## Example 1b - expectedSupplyDuration specified

## Example 1c - Calculated from dosing information
*/

/*
# Example 2:
MedicationDispense 2 tabs 3x/day #180/2*
* dosage = 2
* frequency = 3x /day (i.e., repeats / period = day)
* supply = 180
* daysSupplied = 30 days
* refills = n/a

derived daysSupplied = [supply (180) / ((dosage (2) x frequency (3))] = 30
*/

/*
## Example 2a - daysSupply Specified

## Example 2b - Calculated from dosing information
*/

/*
# Example 3:
MedicationRequest ½ tab 2x/day #30/2
* dosage = 1/2
* frequency = 2x /day (i.e., repeats / period = day)
* supply = 30
* daysSupplied = 30
* refills = 2

derived daysSupplied = [supply (30) / ((dosage (1/2) x frequency (2))] = 30
daysSuppliedWithRefills = [supply (30) x (1 + refills (2)) / ((dosage (1/2) x frequency (2) = 30 x 3 = 90 days
*/

/*
## Example 3a - boundsPeriod specified

## Example 3b - expectedSupplyDuration specified

## Example 3c - Calculated from dosing information
*/

/*4
# Example 4:
MedicationDispense ½ tab 2x/day #30/2*
* dosage = 1/2
* frequency = 2x /day (i.e., repeats / period = day)
* supply = 30
* daysSupplied = 30
* refills = n/a

derived daysSupplied = [supply (30) / ((dosage (1/2) x frequency (2))] = 30
*/

/*
## Example 4a - daysSupply Specified

## Example 4b - Calculated from dosing information
*/

/*
# Example 5:
MedicationRequest 5 ml 3x/day  #150 ml/0
* dosage = 5 ml
* frequency = 3x /day (i.e., repeats / period = day)
* supply = 150 ml
* daysSupplied = 10
* refills = 0

derived daysSupplied = [supply (150 ml) / ((dosage (5 ml) x frequency (3)) = 10 days
daysSuppliedWithRefills = [supply (150 ml) x (1 + refills (0)) / ((dosage (5 ml) x frequency (3)) = 10 days
*/

/*
# Example 6:
MedicationDispense 5 ml 3x/day  #150 ml/0*
* dosage = 5 ml
* frequency = 3x /day (i.e., repeats / period = day)
* supply = 150 ml
* daysSupplied = 10
* refills = n/a

* CMD calculated for “Medication, Dispensed” does not use the number of refills; rather, the days covered by each dispensing event must be retrieved and added.
*/

define August: Interval[@2022-08-01, @2022-08-31]
define August10ToSeptember10: Interval[@2022-08-10, @2022-09-10]
define October: Interval[@2022-10-01, @2022-10-31]
define AugustAndSeptember: Interval[@2022-08-01, @2022-09-30]

//define TestRolloutIntervalsNull: CMD.RolloutIntervals(null) is null
//define TestRolloutIntervalsSingle: CMD.RolloutIntervals({ August }) = { August }
//define TestRolloutIntervalsAugust10: CMD.RolloutIntervals({ August, August10ToSeptember10 }) = { AugustAndSeptember }
//define TestRolloutIntervalsNonOverlapping: CMD.RolloutIntervals({ August, October }) = { August, October }

define Prescriptions: [MedicationRequest]
define Dispenses: [MedicationDispense]

define PrescriptionPeriods:
  Prescriptions P
    return CMD.MedicationRequestPeriod(P)

define DispensePeriods:
  Dispenses D
    return CMD.MedicationDispensePeriod(D)

define CumulativeDuration:
  CMD.CumulativeDuration(PrescriptionPeriods union DispensePeriods)

// TODO: Debug this
define CumulativeMedicationDuration:
  CMD.CumulativeMedicationDuration(
    Prescriptions
      union Dispenses
  )

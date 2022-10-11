library HospitalHarmHyperglycemiainHospitalizedPatientsFHIR version '0.0.014'

using FHIR version '4.0.1'

include FHIRHelpers version '4.1.000' called FHIRHelpers
include SupplementalDataElementsFHIR4 version '3.0.000' called SDE
include MATGlobalCommonFunctionsFHIR4 version '7.0.000' called Global

codesystem "LOINC": 'http://loinc.org' 

valueset "birth date": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.560.100.4'
valueset "Diabetes": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.103.12.1001' 
valueset "Encounter Inpatient": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.307' 
valueset "Glucose Lab Test Mass Per Volume": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1248.34' 
valueset "Hypoglycemics Treatment Medications": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1196.394' 

code "Birth date": '21112-8' from "LOINC" display 'Birth date'

parameter "Measurement Period" Interval<DateTime>

context Patient

/***/
define "Days in Hospitalization":
  "Initial Population" EligibleInpatientHospitalization
    let period: Global."HospitalizationWithObservation" ( EligibleInpatientHospitalization ),
    relevantPeriod: "Hospital Days Max 10"(period)
    return Tuple {
      encounter: EligibleInpatientHospitalization,
      hospitalizationPeriod: period,
      relevantPeriod: relevantPeriod,
      relevantDays: "Days In Period"(relevantPeriod)
    }

define "Denominator":
  "Initial Population"

define "Inpatient Encounter During Measurement Period":
  [Encounter: "Encounter Inpatient"] EncounterInpatient
    where EncounterInpatient.status = 'finished'
      and EncounterInpatient.period ends during day of "Measurement Period"

define "SDE Ethnicity":
  SDE."SDE Ethnicity"

define "SDE Payer":
  SDE."SDE Payer"

define "SDE Race":
  SDE."SDE Race"

define "SDE Sex":
  SDE."SDE Sex"

define "Qualifying Encounters":
  "Inpatient Encounter During Measurement Period" InpatientEncounter
    where AgeInYearsAt(date from start of InpatientEncounter.period)>= 18

define "Numerator":
  "Encounter with Hyperglycemic Events"

define "Initial Population":
  "Encounter with Existing Diabetes Diagnosis"
    union "Encounter with Hypoglycemic Medication"
    union "Encounter with Elevated Blood Glucose Lab"

define "First Blood Glucose within 1 Hour Prior To and 6 Hours After Encounter Start":
  First(["Observation": "Glucose Lab Test Mass Per Volume"] FirstBloodGlucose
      with("Qualifying Encounters")InpatientEncounter
        such that FirstBloodGlucose.effective as dateTime during Interval[(start of Global."HospitalizationWithObservation"(InpatientEncounter)- 1 hour),(start of Global."HospitalizationWithObservation"(InpatientEncounter)+ 6 hours)]
          and FirstBloodGlucose.status in { 'final', 'amended', 'corrected' }
          and FirstBloodGlucose.status != 'cancelled'
      sort by effective
  )

/**
 * Using the already calculated pairing of hospitalization periods with encounters, filter on ones with 
 * hypoglycemic medicatons and return the encounter.*/
define "Encounter with Hypoglycemic Medication":
  from
    "Encounter with Hospitalization Period" Hospitalization,
    ["MedicationAdministration": "Hypoglycemics Treatment Medications"] HypoglycemicMed
    where HypoglycemicMed.status = 'completed'
      and HypoglycemicMed.status != 'not-done'
      and Global."Normalize Interval" ( HypoglycemicMed.effective ) during Hospitalization.hospitalizationPeriod
    return Hospitalization.encounter

/***/
define "Encounter with Hyperglycemic Events":
  "Days with Hyperglycemic Events" HyperglycemicEventDays
    where exists ( HyperglycemicEventDays.eligibleEventDays EligibleEventDay
        where EligibleEventDay.hasHyperglycemicEvent
    )
    return HyperglycemicEventDays.encounter

/**
 * Create paring of encounters to hospitalization period so this calculation can be inspected and the result 
 * can be reused, making the logic faster.*/
define "Encounter with Hospitalization Period":
  "Qualifying Encounters" InpatientHospitalization
    return Tuple {
      encounter: InpatientHospitalization,
      hospitalizationPeriod: Global."HospitalizationWithObservation" ( InpatientHospitalization )
    }

define "Encounter with First Blood Glucose Greater Than or Equal to 1000":
  "Qualifying Encounters" InpatientHospitalization
    with "First Blood Glucose within 1 Hour Prior To and 6 Hours After Encounter Start" FirstGlucoseResult
      such that FirstGlucoseResult.value as Quantity >= 1000 'mg/dL'

define "Encounter with Existing Diabetes Diagnosis Verified":
  "Encounter with Hospitalization Period" Hospitalization
    with ["Condition": "Diabetes"] Diabetes
      such that Diabetes.verificationStatus.coding.code.value ~ { 'confirmed' }
        and ( Global."Prevalence Period" ( Diabetes ) starts before 
          end of Hospitalization.hospitalizationPeriod
        )
    return Hospitalization.encounter

/**
 * Using the already calculated pairing of hospitalization periods with encounters, filter on ones with 
 * diabetes and return the encounter.*/
define "Encounter with Existing Diabetes Diagnosis":
  "Encounter with Hospitalization Period" Hospitalization
    with ["Condition": "Diabetes"] Diabetes
      such that ( Global."Prevalence Period" ( Diabetes ) starts before 
        end of Hospitalization.hospitalizationPeriod
      )
    return Hospitalization.encounter

/**
 * Using the already calculated pairing of hospitalization periods with encounters, filter on ones with 
 * any elevated (>= 200) blood glucose reading during the hospitalization*/
define "Encounter with Elevated Blood Glucose Lab":
  "Encounter with Hospitalization Period" Hospitalization
    with ["Observation": "Glucose Lab Test Mass Per Volume"] BloodGlucoseLab
      such that BloodGlucoseLab.effective as dateTime during Hospitalization.hospitalizationPeriod
        and BloodGlucoseLab.status in { 'final', 'amended', 'corrected' }
        and BloodGlucoseLab.status != 'cancelled'
        and BloodGlucoseLab.value >= 200 'mg/dL'
    return Hospitalization.encounter

define "Denominator Exclusions":
  "Encounter with First Blood Glucose Greater Than or Equal to 1000"

/*# hyper days uses "Relevant Encounters With Glucose Result Days" to find if hyper event on each day. Skips 1st day in 'RelevantDays`. Returns boolean based on: Today high result OR Today no result AND Yesterday high result AND 2 days ago high result*/
define "Days with Hyperglycemic Events":
  "Days with Glucose Results" EncounterWithResultDays
            let eligibleEventDays: EncounterWithResultDays.relevantDays EncounterDay
              where EncounterDay.dayIndex > 1
              return Tuple {
                dayIndex: EncounterDay.dayIndex,
                dayPeriod: EncounterDay.dayPeriod,
                hasHyperglycemicEvent: ( EncounterDay.hasSevereResult
                    or ( EncounterDay.hasNoResult
                        and EncounterWithResultDays.relevantDays[EncounterDay.dayIndex - 2].hasElevatedResult
                        and EncounterWithResultDays.relevantDays[EncounterDay.dayIndex - 3].hasElevatedResult
                    )
                )
              }
            return Tuple {
              encounter: EncounterWithResultDays.encounter,
              relevantPeriod: EncounterWithResultDays.relevantPeriod,
              eligibleEventDays: eligibleEventDays
            }

define "Days with Glucose Results":
  "Days in Hospitalization" InpatientHospitalDays
    return Tuple {
      encounter: InpatientHospitalDays.encounter,
      relevantPeriod: InpatientHospitalDays.relevantPeriod,
      relevantDays: ( InpatientHospitalDays.relevantDays EncounterDay
          return Tuple {
            dayIndex: EncounterDay.dayIndex,
            dayPeriod: EncounterDay.dayPeriod,
            hasSevereResult: exists ( ["Observation": "Glucose Lab Test Mass Per Volume"] BloodGlucoseLab1
                where BloodGlucoseLab1.status in { 'final', 'amended', 'corrected' }
                  and BloodGlucoseLab1.status != 'cancelled'
                  and BloodGlucoseLab1.value > 300 'mg/dL'
                  and BloodGlucoseLab1.effective as dateTime during EncounterDay.dayPeriod
            ),
            hasElevatedResult: exists ( ["Observation": "Glucose Lab Test Mass Per Volume"] BloodGlucoseLab2
                where BloodGlucoseLab2.status in { 'final', 'amended', 'corrected' }
                  and BloodGlucoseLab2.status != 'cancelled'
                  and BloodGlucoseLab2.value >= 200 'mg/dL'
                  and BloodGlucoseLab2.effective as dateTime during EncounterDay.dayPeriod
            ),
            hasNoResult: not exists ( ["Observation": "Glucose Lab Test Mass Per Volume"] BloodGlucoseLab3
                where BloodGlucoseLab3.status in { 'final', 'amended', 'corrected' }
                  and BloodGlucoseLab3.status != 'cancelled'
                  and BloodGlucoseLab3.effective as dateTime during EncounterDay.dayPeriod
            )
          }
      )
    }

/**
 * Creates a list of 24 hour long intervals in an interval paired with the index (1 indexed) to which 24 hour interval it is.*/
define function "Days In Period"(Period Interval<DateTime> ):
  ( "Interval To Day Numbers"(Period)) DayIndex
    let startPeriod: start of Period + ( 24 hours * ( DayIndex - 1 ) ),
    endPeriod: if ( hours between startPeriod and 
      end of Period < 24
    ) then startPeriod 
      else start of Period + ( 24 hours * DayIndex )
    return Tuple {
      dayIndex: DayIndex,
      dayPeriod: Interval[startPeriod, endPeriod )
    }

/**
 * Crops an interval to a maximum length of 10 days.*/
define function "Hospital Days Max 10"(Period Interval<DateTime> ):
  Interval[start of Period, Min({ 
    end of Period, start of Period + 10 days }
  )]

/**
 * Creates a list of integers from 1 to how many days are in the interval. Note, this wont create an index for
 * the final day if it is less than 24 hours. This also includes the first 24 hour period.*/
define function "Interval To Day Numbers"(Period Interval<DateTime> ):
  ( expand { Interval[1, duration in days between start of Period and 
  end of Period]} ) DayExpand
    return 
    end of DayExpand

/**
 * Counts the number of eligible days in an encounter. This simply filters and counts the data built in
 * "Relevant Encounters With Hyperglycemic Event Days".*/
define function "Denominator Observations"(QualifyingEncounter Encounter ):
  singleton from ("Days with Hyperglycemic Events" EncounterWithEventDays
      where EncounterWithEventDays.encounter = QualifyingEncounter
      return Count(EncounterWithEventDays.eligibleEventDays)
  )

/**
 * Counts the number of eligible days with a hyperglycemic event in an encounter. This simply filters and counts the data built in
 * "Relevant Encounters With Hyperglycemic Event Days".*/
 define function "Numerator Observations"(QualifyingEncounter Encounter ):
  singleton from ("Days with Hyperglycemic Events" EncounterWithEventDays
      where EncounterWithEventDays.encounter = QualifyingEncounter
      return Count(EncounterWithEventDays.eligibleEventDays EligibleEventDay
          where EligibleEventDay.hasHyperglycemicEvent
      )
  )
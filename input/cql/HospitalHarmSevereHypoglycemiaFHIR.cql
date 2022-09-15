library HospitalHarmSevereHypoglycemiaFHIR version '0.0.016'

using FHIR version '4.0.1'

include FHIRHelpers version '4.1.000' called FHIRHelpers
include SupplementalDataElementsFHIR4 version '3.0.000' called SDE
include MATGlobalCommonFunctionsFHIR4 version '7.0.000' called Global

valueset "birth date": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.560.100.4' 
valueset "Emergency Department Visit": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.292' 
valueset "Encounter Inpatient": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.307' 
valueset "Glucose Lab Test Mass Per Volume": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1248.34' 
valueset "Hypoglycemics Severe Hypoglycemia": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1196.393' 
valueset "Observation Services": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1111.143' 

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2021-01-01T00:00:00.0, @2022-01-01T00:00:00.0)

context Patient

define "SDE Payer":
  SDE."SDE Payer"

define "SDE Race":
  SDE."SDE Race"

define "SDE Sex":
  SDE."SDE Sex"

define "SDE Ethnicity":
  SDE."SDE Ethnicity"

define "Denominator":
  "Initial Population"

define "Hypoglycemic Medication Administration":
  ["MedicationAdministration": "Hypoglycemics Severe Hypoglycemia"] HypoMedication
    where HypoMedication.status = 'completed'
      and HypoMedication.status != 'not-done'

define "Inpatient Encounter During Measurement Period":
  [Encounter: "Encounter Inpatient"] EncounterInpatient
    where EncounterInpatient.status = 'finished'
      and EncounterInpatient.period ends during day of "Measurement Period"

define "Qualifying Encounter":
  "Inpatient Encounter During Measurement Period" InpatientEncounter
    where AgeInYearsAt(date from start of Global."HospitalizationWithObservation"(InpatientEncounter))>= 18

define "Encounter with Hypoglycemic Medication Administration":
  "Qualifying Encounter" InpatientEncounter
    with "Hypoglycemic Medication Administration" HypoglycemicMedication
      such that Global."Normalize Interval" ( HypoglycemicMedication.effective ) starts during Global.HospitalizationWithObservation ( InpatientEncounter )

define "Initial Population":
  "Encounter with Hypoglycemic Medication Administration"

define "Numerator":
  "Encounter With Severe Hypoglycemic Harm Event"

define "Encounter With Severe Hypoglycemic Harm Event":
  "Denominator" QualifyingEncounter
    where exists ( ["Observation": "Glucose Lab Test Mass Per Volume"] BloodGlucoseLab
        with "Hypoglycemic Medication Administration" HypoglycemicMeds
          such that Global."Normalize Interval" ( HypoglycemicMeds.effective ) starts 24 hours or less on or before start of Global."Normalize Interval" ( BloodGlucoseLab.effective )
            and BloodGlucoseLab.status in { 'final', 'amended', 'corrected' }
            and BloodGlucoseLab.status != 'cancelled'
            and Global."Normalize Interval" ( HypoglycemicMeds.effective ) starts during Global."HospitalizationWithObservation" ( QualifyingEncounter )
        without ["Observation": "Glucose Lab Test Mass Per Volume"] FollowupBloodGlucoseLab
          such that Global."Normalize Interval" ( FollowupBloodGlucoseLab.effective ) starts during Global."HospitalizationWithObservation" ( QualifyingEncounter )
            and Global."Normalize Interval" ( FollowupBloodGlucoseLab.effective ) starts 5 minutes or less after start of Global."Normalize Interval" ( BloodGlucoseLab.effective )
            and FollowupBloodGlucoseLab.status in { 'final', 'amended', 'corrected' }
            and FollowupBloodGlucoseLab.status != 'cancelled'
            and FollowupBloodGlucoseLab.value > 80 'mg/dL'
        where Global."Normalize Interval" ( BloodGlucoseLab.effective ) starts during Global."HospitalizationWithObservation" ( QualifyingEncounter )
          and BloodGlucoseLab.value < 40 'mg/dL'
    )


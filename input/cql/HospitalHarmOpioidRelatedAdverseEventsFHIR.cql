library HospitalHarmOpioidRelatedAdverseEventsFHIR version '0.0.002'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.001' called FHIRHelpers
include SupplementalDataElementsFHIR4 version '2.0.000' called SDE
include MATGlobalCommonFunctionsFHIR4 version '5.0.000' called Global

codesystem "SNOMEDCT": 'http://snomed.info/sct' 
codesystem "HSLOC": 'http://cts.nlm.nih.gov/fhir/cs/hsloc' 

valueset "Emergency Department Visit": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.292' 
valueset "Encounter Inpatient": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.307' 
valueset "Observation Services": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1111.143' 
valueset "Operating Room Suite": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1248.141' 
valueset "Opioid Antagonist": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1248.119' 
valueset "Opioids, All": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1196.226' 

code "Dead": '419099009' from "SNOMEDCT" display 'Dead'
code "Operating Room/Suite": '1096-7' from "HSLOC" display 'Operating Room/Suite'

parameter "Measurement Period" Interval<DateTime>

context Patient

define "SDE Ethnicity":
  SDE."SDE Ethnicity"

define "SDE Payer":
  SDE."SDE Payer"

define "SDE Race":
  SDE."SDE Race"

define "SDE Sex":
  SDE."SDE Sex"

define "Numerator":
  "Encounter With Opioid Antagonist Administration Outside of Operating Room and Within 12 Hrs After Opioid"

define "Denominator":
  "Initial Population"

define "Opioid Administration":
  ["MedicationAdministration": "Opioids, All"] Opioids
    where Opioids.status = 'completed'
      and Opioids.status != 'not-done'

define "Initial Population":
  "Encounter With Opioid Administration"

define "Inpatient Encounter During Measurement Period":
  [Encounter: "Encounter Inpatient"] EncounterInpatient
    where EncounterInpatient.status = 'finished'
      and EncounterInpatient.period ends during day of "Measurement Period"

define "Qualifying Encounter":
  "Inpatient Encounter During Measurement Period" InpatientEncounter
    where AgeInYearsAt(date from start of Global."HospitalizationWithObservation"(InpatientEncounter))>= 18

define "Opioid Antagonist Administration":
  ["MedicationAdministration": "Opioid Antagonist"] AntagonistGiven
    where AntagonistGiven.status = 'completed'
      and AntagonistGiven.status != 'not-done'

define "Encounter With Opioid Administration":
  "Qualifying Encounter" InpatientEncounter
    with "Opioid Administration" OpioidGiven
      such that Global."Normalize Interval" ( OpioidGiven.effective ) starts during Global.HospitalizationWithObservation ( InpatientEncounter )

define "Encounter With Opioid Antagonist Administration Outside of Operating Room and Within 12 Hrs After Opioid":
  // Opioids administered before opioid antagonist AND excludes opioid antagonist administered in operating room 
  from
    "Opioid Antagonist Administration" OpioidAntagonistGiven,
    "Opioid Administration" OpioidGiven,
    "Denominator" EncounterWithQualifyingAge
    where not exists ( EncounterWithQualifyingAge.location EncounterLocation
        where Global.GetLocation ( EncounterLocation.location ).type in "Operating Room Suite"
          and Global."Normalize Interval" ( OpioidAntagonistGiven.effective ) starts during EncounterLocation.period
    )
      and ( Global."Normalize Interval" ( OpioidAntagonistGiven.effective ) starts during Global."HospitalizationWithObservation" ( EncounterWithQualifyingAge )
          and Global."Normalize Interval" ( OpioidGiven.effective ) starts during Global."HospitalizationWithObservation" ( EncounterWithQualifyingAge )
          and Global."Normalize Interval" ( OpioidGiven.effective ) ends 12 hours or less before start of Global."Normalize Interval" ( OpioidAntagonistGiven.effective )
      )
    return EncounterWithQualifyingAge


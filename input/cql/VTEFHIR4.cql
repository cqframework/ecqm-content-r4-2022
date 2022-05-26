/*
@update:
Refresh from 2022AU
*/
library VTEFHIR4 version '6.0.000'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.002' called FHIRHelpers
include FHIRCommon version '4.0.002' called FHIRCommon
include MATGlobalCommonFunctionsFHIR4 version '7.0.000' called Global
include TJCOverallFHIR4 version '6.0.000' called TJC

valueset "Obstetrics": 'urn:oid:2.16.840.1.113883.3.117.1.7.1.263'
valueset "Obstetrics VTE": 'urn:oid:2.16.840.1.113883.3.117.1.7.1.264'
valueset "Venous Thromboembolism": 'urn:oid:2.16.840.1.113883.3.117.1.7.1.279'

parameter "Measurement Period" Interval<DateTime>
  default Interval[@2019-01-01T00:00:00.0, @2020-01-01T00:00:00.0)

context Patient

define "Admission without VTE or Obstetrical Conditions":
  Global."Inpatient Encounter" InpatientEncounter
    where not exists (
      [Condition: category ~ FHIRCommon."encounter-diagnosis"] C
        where FHIRHelpers.reference(C) in InpatientEncounter.diagnosis.condition
          and (C.code in "Obstetrics" or C.code in "Venous Thromboembolism" or C.code in "Obstetrics VTE")
    )

define "Encounter with Age Range and without VTE Diagnosis or Obstetrical Conditions":
  ( Global."Inpatient Encounter" InpatientEncounter
      where AgeInYearsAt(date from start of InpatientEncounter.period) >= 18
  )
    intersect "Admission without VTE or Obstetrical Conditions"

define function "StartOfFirstICU"(Encounter FHIR.Encounter ):
  start of "FirstICULocationPeriod"(Encounter)

define function "FirstICULocationPeriod"(Encounter FHIR.Encounter ):
  Global."FirstInpatientIntensiveCareUnit"(Encounter).period

define function "CalendarDayOfOrDayAfter"(StartValue DateTime ):
  Interval[date from ( StartValue ), date from ( StartValue ) + 1 day]

define function "FromDayOfStartOfHospitalizationToDayAfterAdmission"(Encounter "Encounter" ):
  Interval[TJC."TruncateTime" ( start of Global."HospitalizationWithObservation" ( Encounter ) ), TJC."TruncateTime" ( start of Encounter.period + 2 days ) )

define function "FromDayOfStartOfHospitalizationToDayAfterFirstICU"(Encounter "Encounter" ):
  Interval[TJC."TruncateTime" ( start of Global."HospitalizationWithObservation" ( Encounter ) ), TJC."TruncateTime" ( StartOfFirstICU(Encounter)+ 2 days ) )

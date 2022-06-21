/*
@update: 2022-05-24: Refresh for 2022 AU content
*/
library AdvancedIllnessandFrailtyExclusionECQMFHIR4 version '7.0.000'

using FHIR version '4.0.1'

include FHIRHelpers version '4.1.000' called FHIRHelpers
include FHIRCommon version '1.1.000' called FHIRCommon
include MATGlobalCommonFunctionsFHIR4 version '7.0.000' called Global
include CumulativeMedicationDurationFHIR4 version '2.0.000' called CMD

valueset "Acute Inpatient": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1083'
valueset "Advanced Illness": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.110.12.1082'
valueset "Dementia Medications": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.196.12.1510'
valueset "Emergency Department Visit": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1010'
valueset "Frailty Device": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.118.12.1300'
valueset "Frailty Diagnosis": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.113.12.1074'
valueset "Frailty Encounter": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1088'
valueset "Frailty Symptom": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.113.12.1075'
valueset "Nonacute Inpatient": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1084'
valueset "Observation": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1086'
valueset "Outpatient": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1087'

code "Housing status": '71802-3' from FHIRCommon."LOINC" display 'Housing status'
code "Lives in a nursing home (finding)": '160734000' from FHIRCommon."SNOMEDCT" display 'Lives in a nursing home (finding)'
code "Medical equipment used": '98181-1' from FHIRCommon."LOINC" display 'Medical equipment used'

parameter "Measurement Period" Interval<DateTime>

context Patient

define "Is Age 66 or Older with Advanced Illness and Frailty":
  (AgeInYearsAt(date from end of "Measurement Period") >= 66
    and "Has Criteria Indicating Frailty"
    and ("Has Two Outpatient Encounters with Advanced Illness on Different Dates of Service"
      or "Has Inpatient Encounter with Advanced Illness"
      or "Has Dementia Medications in Year Before or During Measurement Period"
    )
  )

define "Has Dementia Medications in Year Before or During Measurement Period":
  exists ([MedicationRequest: "Dementia Medications"] DementiaMedication
    where DementiaMedication.status = 'active'
      and DementiaMedication.intent = 'order'
      and CMD.MedicationPeriod(DementiaMedication) overlaps Interval[start of "Measurement Period" - 1 year, end of "Measurement Period"]
  )

define "Has Inpatient Encounter with Advanced Illness":
  exists (
    ([Encounter: "Acute Inpatient"] AcuteInpatient
      where AcuteInpatient.status = 'finished'
    ) InpatientEncounter
      with [Condition: "Advanced Illness"] AdvancedIllnessDiagnosis
        such that AdvancedIllnessDiagnosis in Global.EncounterDiagnosis(InpatientEncounter)
          and Global."Normalize Interval"(InpatientEncounter.period) starts during day of Interval[start of "Measurement Period" - 1 year, 
          end of "Measurement Period"]
  )

define "Outpatient Encounters with Advanced Illness":
  (([Encounter: "Outpatient"]
      union [Encounter: "Observation"]
      union [Encounter: "Emergency Department Visit"]
      union [Encounter: "Nonacute Inpatient"]
    ) Outpatient
    where Outpatient.status = 'finished'
  ) OutpatientEncounter
    with [Condition: "Advanced Illness"] AdvancedIllnessDiagnosis
      such that AdvancedIllnessDiagnosis in Global.EncounterDiagnosis(OutpatientEncounter)
        and Global."Normalize Interval"(OutpatientEncounter.period) starts during day of Interval[start of "Measurement Period" - 1 year, 
          end of "Measurement Period"]

define "Has Two Outpatient Encounters with Advanced Illness on Different Dates of Service":
  exists (
    from
        "Outpatient Encounters with Advanced Illness" OutpatientEncounter1,
        "Outpatient Encounters with Advanced Illness" OutpatientEncounter2
      where OutpatientEncounter2.period ends 1 day or more after day of end of OutpatientEncounter1.period
      return OutpatientEncounter1
  )

define "Is Age 66 or Older Living Long Term in a Nursing Home":
  (AgeInYearsAt(date from end of "Measurement Period") >= 66)
    and ((Last([Observation: "Housing status"] HousingStatus
          where HousingStatus.status = 'final'
            and Global."Normalize Interval"(HousingStatus.effective) ends on or before end of "Measurement Period"
          sort by end of Global."Normalize Interval"(effective) asc
      )) LastHousingStatus
        where LastHousingStatus.value ~ "Lives in a nursing home (finding)"
    ) is not null

define "Has Criteria Indicating Frailty":
  exists ([DeviceRequest: "Frailty Device"] FrailtyDeviceOrder
    where FrailtyDeviceOrder.status in { 'active', 'on-hold', 'completed' }
      and FrailtyDeviceOrder.intent = 'order'
      and Global."Normalize Interval"(FrailtyDeviceOrder.authoredOn) during day of "Measurement Period"
  )
    or exists ([Observation: "Medical equipment used"] EquipmentUsed
        where EquipmentUsed.value in "Frailty Device"
          and EquipmentUsed.status in { 'final', 'amended', 'corrected' }
          and Global."Normalize Interval"(EquipmentUsed.effective) ends during day of "Measurement Period"
    )
    or exists  ([Condition: "Frailty Diagnosis"] FrailtyDiagnosis
        where Global."Prevalence Period"(FrailtyDiagnosis) overlaps "Measurement Period"
    )
    or exists ( [Encounter: "Frailty Encounter"] FrailtyEncounter
      where FrailtyEncounter.status = 'finished'
        and Global."Normalize Interval"(FrailtyEncounter.period) overlaps "Measurement Period"
    )
    or exists ([Observation: "Frailty Symptom"] FrailtySymptom
      where FrailtySymptom.status in { 'preliminary', 'final', 'amended', 'corrected' }
        and Global."Normalize Interval"(FrailtySymptom.effective) overlaps "Measurement Period"
    )

define "Is Age 66 to 80 with Advanced Illness and Frailty or Is Age 81 or Older with Frailty":
  (AgeInYearsAt(date from end of "Measurement Period") in Interval[66, 80]
    and "Has Criteria Indicating Frailty"
    and ( "Has Two Outpatient Encounters with Advanced Illness on Different Dates of Service"
      or "Has Inpatient Encounter with Advanced Illness"
      or "Has Dementia Medications in Year Before or During Measurement Period"
    )
  )
    or (AgeInYearsAt(date from end of "Measurement Period") >= 81
      and "Has Criteria Indicating Frailty"
    )

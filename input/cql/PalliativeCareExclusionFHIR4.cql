/*
@update: Refresh from 2022AU
*/
library PalliativeCareExclusionFHIR4 version '2.0.000'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.002' called FHIRHelpers
include FHIRCommon version '4.0.002' called FHIRCommon
include MATGlobalCommonFunctionsFHIR4 version '7.0.000' called Global

valueset "Palliative Care Encounter": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1090'
valueset "Palliative Care Intervention": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.464.1003.198.12.1135'

code "Encounter for palliative care": 'Z51.5' from FHIRCommon."ICD10CM" display 'Encounter for palliative care'
code "Functional Assessment of Chronic Illness Therapy - Palliative Care Questionnaire (FACIT-Pal)": '71007-9' from FHIRCommon."LOINC" display 'Functional Assessment of Chronic Illness Therapy - Palliative Care Questionnaire (FACIT-Pal)'

parameter "Measurement Period" Interval<DateTime>

context Patient

define "Palliative Care in the Measurement Period":
  exists (
    [Observation: "Functional Assessment of Chronic Illness Therapy - Palliative Care Questionnaire (FACIT-Pal)"] PalliativeAssessment
      where PalliativeAssessment.status in { 'final', 'amended', 'corrected' }
        and exists ( PalliativeAssessment.category PalliativeAssessmentCategory
            where PalliativeAssessmentCategory ~ FHIRCommon.survey
        )
        and Global."Normalize Interval"(PalliativeAssessment.effective) overlaps "Measurement Period"
  )
    or exists (
      [Condition: "Encounter for palliative care"] PalliativeCondition
        where Global."Prevalence Period"(PalliativeCondition) overlaps "Measurement Period"
    )
    or exists (
      [Encounter: "Palliative Care Encounter"] PalliativeEncounter
        where PalliativeEncounter.status = 'finished'
          and Global."Normalize Interval"(PalliativeEncounter.period) overlaps "Measurement Period"
    )
    or exists (
      [Procedure: "Palliative Care Intervention"] PalliativeIntervention
        where PalliativeIntervention.status in { 'completed', 'in-progress' }
          and Global."Normalize Interval"(PalliativeIntervention.performed) overlaps "Measurement Period"
    )

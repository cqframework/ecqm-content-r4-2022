/*
@update: Refresh from 2022AU
*/
library HospiceFHIR4 version '4.0.000'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.002' called FHIRHelpers
include FHIRCommon version '4.0.002' called FHIRCommon
include MATGlobalCommonFunctionsFHIR4 version '7.0.000' called Global

valueset "Encounter Inpatient": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.307'
valueset "Hospice care ambulatory": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1108.15'
valueset "Hospice Encounter": 'urn:oid:2.16.840.1.113883.3.464.1003.1003'

code "Discharge to healthcare facility for hospice care (procedure)": '428371000124100' from FHIRCommon."SNOMEDCT" display 'Discharge to healthcare facility for hospice care (procedure)'
code "Discharge to home for hospice care (procedure)": '428361000124107' from FHIRCommon."SNOMEDCT" display 'Discharge to home for hospice care (procedure)'
code "Hospice care [Minimum Data Set]": '45755-6' from FHIRCommon."LOINC" display 'Hospice care [Minimum Data Set]'
code "Yes (qualifier value)": '373066001' from FHIRCommon."SNOMEDCT" display 'Yes (qualifier value)'

parameter "Measurement Period" Interval<DateTime>

context Patient

define "Has Hospice":
  exists (
    [Encounter: "Encounter Inpatient"] DischargeHospice
			where DischargeHospice.status = 'finished'
		    and (
	        DischargeHospice.hospitalization.dischargeDisposition ~ "Discharge to home for hospice care (procedure)"
				    or DischargeHospice.hospitalization.dischargeDisposition ~ "Discharge to healthcare facility for hospice care (procedure)"
	    	)
				and DischargeHospice.period ends during "Measurement Period"
	)
    or exists (
      [Encounter: "Hospice Encounter"] HospiceEncounter
        where HospiceEncounter.status = 'finished'
          and HospiceEncounter.period overlaps "Measurement Period"
    )
    or exists (
      ["Observation": "Hospice care [Minimum Data Set]"] HospiceAssessment
        where HospiceAssessment.value ~ "Yes (qualifier value)"
          and Global."Normalize Interval"(HospiceAssessment.effective) overlaps "Measurement Period"
    )
    or exists (
      [ServiceRequest: "Hospice care ambulatory"] HospiceOrder
        where HospiceOrder.status in {'active', 'completed'}
          and HospiceOrder.intent = 'order'
          and Global."Normalize Interval"(HospiceOrder.authoredOn) during "Measurement Period"
    )
    or exists (
      [Procedure: "Hospice care ambulatory"] HospicePerformed
        where HospicePerformed.status = 'completed'
          and Global."Normalize Interval"(HospicePerformed.performed) overlaps "Measurement Period"
    )

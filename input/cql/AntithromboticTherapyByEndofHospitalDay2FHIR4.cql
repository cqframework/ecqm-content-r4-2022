library AntithromboticTherapyByEndofHospitalDay2FHIR4 version '0.2.002'

using FHIR version '4.0.1'

include MATGlobalCommonFunctionsFHIR4 version '7.0.000' called Global
include FHIRHelpers version '4.1.000' called FHIRHelpers
include FHIRCommon version '1.1.000' called FHIRCommon
include TJCOverallFHIR4 version '6.0.000' called TJC
include SupplementalDataElementsFHIR4 version '3.0.000' called SDE

valueset "Antithrombotic Therapy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1110.62' 
valueset "INR": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.213' 
valueset "Intravenous or Intra arterial Thrombolytic (tPA) Therapy Prior to Arrival": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1110.21' 
valueset "Intravenous or Intra-arterial Thrombolytic (t-PA) Therapy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.21' 
valueset "Medical Reason": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.473' 
valueset "Patient Refusal": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.93' 
valueset "Pharmacological Contraindications For Antithrombotic Therapy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1110.52' 
valueset "Thrombolytic (t-PA) Therapy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.226' 

parameter "Measurement Period" Interval<DateTime>

context Patient

define "Initial Population":
  TJC."Encounter with Principal Diagnosis and Age"

define "No Antithrombotic Ordered or Administered":
  "Reason for Not Ordering Antithrombotic"
    union "Reason for Not Administering Antithrombotic"

define "Reason for Not Administering Antithrombotic":
  ["MedicationAdministration": medication in "Antithrombotic Therapy"] NoAntithromboticAdmin
    where  NoAntithromboticAdmin.status = 'not-done' 
        and (NoAntithromboticAdmin.statusReason in "Medical Reason"
             or NoAntithromboticAdmin.statusReason in "Patient Refusal")
                return {id: NoAntithromboticAdmin.id, authoredOn: start of Global."Normalize Interval"(NoAntithromboticAdmin.effective)}

define "Reason for Not Ordering Antithrombotic":
  ["MedicationRequest": "Antithrombotic Therapy"] NoAntithromboticOrder
    where NoAntithromboticOrder.status = 'completed' 
        and NoAntithromboticOrder.doNotPerform is true 
        and (NoAntithromboticOrder.reasonCode in "Medical Reason"
         or NoAntithromboticOrder.reasonCode in "Patient Refusal")
            return {id: NoAntithromboticOrder.id, authoredOn: NoAntithromboticOrder.authoredOn}

define "Numerator":
  "Encounter with Antithrombotic Therapy"

define "SDE Ethnicity":
  SDE."SDE Ethnicity"

define "SDE Payer":
  SDE."SDE Payer"

define "SDE Race":
  SDE."SDE Race"

define "SDE Sex":
  SDE."SDE Sex"

define "Encounter with Thrombolytic Therapy Given Prior To Arrival Or During Hospitalization":
  "Encounter with Thrombolytic Therapy Medication or Procedures"
    union "Encounter with Thrombolytic Therapy Prior to Arrival"
    union "Encounter with Thrombolytic Therapy Documented As Already Given"

define "Denominator":
  TJC."Ischemic Stroke Encounter"

define "Denominator Exceptions":
  "No Antithrombotic Ordered or Administered Day Of or Day After Hospital Arrival"
      union "Encounter with Pharmacological Contraindications for Antithrombotic Therapy Given Day Of or Day After Hospital Arrival"
      union "Encounter with An INR Greater Than 3.5"

define "Denominator Exclusions":
  "Encounter Less Than Two Days"
    union "Encounter with Comfort Measures during Day of or Day After Arrival"
    union "Encounter with Thrombolytic Therapy Given Prior To Arrival Or During Hospitalization"

define "Encounter with Pharmacological Contraindications for Antithrombotic Therapy Given Day Of or Day After Hospital Arrival":
  TJC."Ischemic Stroke Encounter" IschemicStrokeEncounter
    with ["MedicationAdministration": "Pharmacological Contraindications For Antithrombotic Therapy"] PharmacologicalContraindications
        such that PharmacologicalContraindications.status in { 'in-progress', 'completed' }
        and Global."Normalize Interval" ( PharmacologicalContraindications.effective) starts during day of TJC."CalendarDayOfOrDayAfter" ( start of Global."HospitalizationWithObservation" ( IschemicStrokeEncounter ) )
          //          and date from (start of Global."Normalize Interval" ( PharmacologicalContraindications.effective))  during TJC."CalendarDayOfOrDayAfter" ( start of Global."HospitalizationWithObservation" ( IschemicStrokeEncounter ) )

define "Encounter with Antithrombotic Therapy":
  TJC."Ischemic Stroke Encounter" IschemicStrokeEncounter
     with ["MedicationAdministration": "Antithrombotic Therapy"] Antithrombotic
        such that Antithrombotic.status in { 'in-progress', 'completed' }
            and Global."Normalize Interval" ( Antithrombotic.effective) starts during day of TJC."CalendarDayOfOrDayAfter" ( start of Global."HospitalizationWithObservation" ( IschemicStrokeEncounter ) )
          //          and date from (start of Global."Normalize Interval" ( Antithrombotic.effective)) during TJC."CalendarDayOfOrDayAfter" ( start of Global."HospitalizationWithObservation" ( IschemicStrokeEncounter ) )

define "Thrombolytic Therapy Medication or Procedures":
  (["MedicationAdministration": "Thrombolytic (t-PA) Therapy"] ThrombolyticMedication
              	where ThrombolyticMedication.status in { 'in-progress', 'completed' }
                  	return "Observation" { id: ThrombolyticMedication.id, effective: ThrombolyticMedication.effective })
                	union (["Procedure": "Intravenous or Intra-arterial Thrombolytic (t-PA) Therapy"] ThrombolyticProcedure
                		where ThrombolyticProcedure.status = 'completed'
                    		return "Observation" { id: ThrombolyticProcedure.id, effective: ThrombolyticProcedure.performed }
                  )

define "Encounter with Thrombolytic Therapy Medication or Procedures":
  TJC."Ischemic Stroke Encounter" IschemicStrokeEncounter
                    with "Thrombolytic Therapy Medication or Procedures" ThrombolyticTherapy
                        such that Global."Normalize Interval" ( ThrombolyticTherapy.effective ) starts during Interval[start of Global."HospitalizationWithObservation" ( IschemicStrokeEncounter ) - 24 hours, 
                            end of Global."HospitalizationWithObservation" ( IschemicStrokeEncounter ) )

define "Encounter Less Than Two Days":
  TJC."Ischemic Stroke Encounter" IschemicStrokeEncounter
        where Global."LengthInDays" (Global."HospitalizationWithObservation" ( IschemicStrokeEncounter )) < 2

define "Encounter with Thrombolytic Therapy Prior to Arrival":
  TJC."Ischemic Stroke Encounter" IschemicStrokeEncounter
                    where exists ((Global."EncounterDiagnosis"(IschemicStrokeEncounter)) EncounterDiagnosis
                        where (EncounterDiagnosis.code in "Intravenous or Intra arterial Thrombolytic (tPA) Therapy Prior to Arrival")
                   )

define "Encounter with Thrombolytic Therapy Documented As Already Given":
  TJC."Ischemic Stroke Encounter" IschemicStrokeEncounter
        with [Condition: "Intravenous or Intra arterial Thrombolytic (tPA) Therapy Prior to Arrival"] PriorTPA
            such that PriorTPA.recordedDate during Global."HospitalizationWithObservation" ( IschemicStrokeEncounter )
                and (FHIRHelpers.ToConcept(PriorTPA.clinicalStatus) ~ FHIRCommon."active"
                            or FHIRHelpers.ToConcept(PriorTPA.clinicalStatus) ~ FHIRCommon."recurrence"
              			  or FHIRHelpers.ToConcept(PriorTPA.clinicalStatus) ~  FHIRCommon."relapse" )
                            and FHIRHelpers.ToConcept(PriorTPA.verificationStatus) ~ FHIRCommon."confirmed"

define "Encounter with Comfort Measures during Day of or Day After Arrival":
  TJC."Ischemic Stroke Encounter" IschemicStrokeEncounter
             with TJC."Intervention Comfort Measures" ComfortMeasure
                        such that Coalesce(start of Global."Normalize Interval"(ComfortMeasure.performed), ComfortMeasure.authoredOn) during day of TJC."CalendarDayOfOrDayAfter" ( start of Global."HospitalizationWithObservation" ( IschemicStrokeEncounter ) )
          //              such that date from(Coalesce(start of Global."Normalize Interval"(ComfortMeasure.performed), ComfortMeasure.authoredOn)) during TJC."CalendarDayOfOrDayAfter" ( start of Global."HospitalizationWithObservation" ( IschemicStrokeEncounter ) )

define "Encounter with An INR Greater Than 3.5":
  TJC."Ischemic Stroke Encounter" IschemicStrokeEncounter
                with ["Observation": "INR"] INR
                    such that INR.issued during day of TJC."CalendarDayOfOrDayAfter" ( start of Global."HospitalizationWithObservation" ( IschemicStrokeEncounter ) )
                        and INR.value as Quantity > 3.5
                        and INR.status in { 'final', 'amended', 'corrected' }
        //            such that date from (INR.issued) during TJC."CalendarDayOfOrDayAfter" ( start of Global."HospitalizationWithObservation" ( IschemicStrokeEncounter ) )

define "No Antithrombotic Ordered or Administered Day Of or Day After Hospital Arrival":
  TJC."Ischemic Stroke Encounter" IschemicStrokeEncounter
            with "No Antithrombotic Ordered or Administered" NoAntithrombotic
              such that NoAntithrombotic.authoredOn during day of TJC."CalendarDayOfOrDayAfter"(start of Global."HospitalizationWithObservation"(IschemicStrokeEncounter) )
              // such that date from NoAntithrombotic.authoredOn during TJC."CalendarDayOfOrDayAfter"(start of Global."HospitalizationWithObservation"(IschemicStrokeEncounter))


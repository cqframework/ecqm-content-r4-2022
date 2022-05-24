/*
@author: Bryn Rhodes
@description: This library defines functions to expose extensions defined
in QICore as functions in CQL, as well as common terminology and functions
used in writing CQL with FHIR and QICore profiles.

NOTE: The source for this is the QICoreCommon library published as part of QICore 4.1.1
That library specified these functions as fluent functions, whereas the functions
specified here are non-fluent versions.
*/
library QICoreCommon version '4.1.002'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.002'

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "RoleCode": 'http://terminology.hl7.org/CodeSystem/v3-RoleCode'
codesystem "Diagnosis Role": 'http://terminology.hl7.org/CodeSystem/diagnosis-role'
codesystem "RequestIntent": 'http://terminology.hl7.org/CodeSystem/request-intent'
codesystem "MedicationRequestCategory": 'http://terminology.hl7.org/CodeSystem/medicationrequest-category'
codesystem "ConditionClinicalStatusCodes": 'http://terminology.hl7.org/CodeSystem/condition-clinical'
codesystem "ConditionVerificationStatusCodes": 'http://terminology.hl7.org/CodeSystem/condition-ver-status'
codesystem "AllergyIntoleranceClinicalStatusCodes": 'http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical'
codesystem "AllergyIntoleranceVerificationStatusCodes": 'http://terminology.hl7.org/CodeSystem/allergyintolerance-verification'

code "Birthdate": '21112-8' from "LOINC" display 'Birth date'
code "Dead": '419099009' from "SNOMEDCT" display 'Dead'
code "ER": 'ER' from "RoleCode" display 'Emergency room'
code "ICU": 'ICU' from "RoleCode" display 'Intensive care unit'
code "Billing": 'billing' from "Diagnosis Role" display 'Billing'

// Condition Clinical Status Codes - Consider value sets for these
code "active": 'active' from "ConditionClinicalStatusCodes"
code "recurrence": 'recurrence' from "ConditionClinicalStatusCodes"
code "relapse": 'relapse' from "ConditionClinicalStatusCodes"
code "inactive": 'inactive' from "ConditionClinicalStatusCodes"
code "remission": 'remission' from "ConditionClinicalStatusCodes"
code "resolved": 'resolved' from "ConditionClinicalStatusCodes"

// Condition Verification Status Codes - Consider value sets for these
code "unconfirmed": 'unconfirmed' from ConditionVerificationStatusCodes
code "provisional": 'provisional' from ConditionVerificationStatusCodes
code "differential": 'differential' from ConditionVerificationStatusCodes
code "confirmed": 'confirmed' from ConditionVerificationStatusCodes
code "refuted": 'refuted' from ConditionVerificationStatusCodes
code "entered-in-error": 'entered-in-error' from ConditionVerificationStatusCodes

code "allergy-active": 'active' from "AllergyIntoleranceClinicalStatusCodes"
code "allergy-inactive": 'inactive' from "AllergyIntoleranceClinicalStatusCodes"
code "allergy-resolved": 'resolved' from "AllergyIntoleranceClinicalStatusCodes"

// Allergy/Intolerance Verification Status Codes - Consider value sets for these
code "allergy-unconfirmed": 'unconfirmed' from AllergyIntoleranceVerificationStatusCodes
code "allergy-confirmed": 'confirmed' from AllergyIntoleranceVerificationStatusCodes
code "allergy-refuted": 'refuted' from AllergyIntoleranceVerificationStatusCodes

// MedicationRequest Category Codes
code "Community": 'community' from "MedicationRequestCategory" display 'Community'
code "Discharge": 'discharge' from "MedicationRequestCategory" display 'Discharge'

// Diagnosis Role Codes
code "AD": 'AD' from "Diagnosis Role" display 'Admission diagnosis'
code "DD": 'DD' from "Diagnosis Role" display 'Discharge diagnosis'
code "CC": 'CC' from "Diagnosis Role" display 'Chief complaint'
code "CM": 'CM' from "Diagnosis Role" display 'Comorbidity diagnosis'
code "pre-op": 'pre-op' from "Diagnosis Role" display 'pre-op diagnosis'
code "post-op": 'post-op' from "Diagnosis Role" display 'post-op diagnosis'
code "billing": 'billing' from "Diagnosis Role" display 'billing diagnosis'

context Patient

/* Candidates for FHIRCommon */

/*
@description: Returns true if the given MedicationRequest has a category of Community
*/
define function IsCommunity(medicationRequest MedicationRequest):
  exists (medicationRequest.category C
    where C ~ Community
  )

/*
@description: Returns true if the given MedicationRequest has a category of Discharge
*/
define function IsDischarge(medicationRequest MedicationRequest):
  exists (medicationRequest.category C
    where C ~ Discharge
  )

/*
@description: Normalizes a value that is a choice of timing-valued types to an equivalent interval
@comment: Normalizes a choice type of FHIR.dateTime, FHIR.Period, FHIR.Timing, FHIR.instance, FHIR.string, FHIR.Age, or FHIR.Range types
to an equivalent interval. This selection of choice types is a superset of the majority of choice types that are used as possible
representations for timing-valued elements in FHIR, allowing this function to be used across any resource. NOTE: Due to the
complexity of determining a single interval from a Timing or String type, this function will throw a run-time exception if it is used
with a Timing or String.
*/
define function ToInterval(choice Choice<FHIR.dateTime, FHIR.Period, FHIR.Timing, FHIR.instant, FHIR.string, FHIR.Age, FHIR.Range>):
  case
    when choice is FHIR.dateTime then
      Interval[FHIRHelpers.ToDateTime(choice as FHIR.dateTime), FHIRHelpers.ToDateTime(choice as FHIR.dateTime)]
    when choice is FHIR.Period then
      FHIRHelpers.ToInterval(choice as FHIR.Period)
    when choice is FHIR.instant then
      Interval[FHIRHelpers.ToDateTime(choice as FHIR.instant), FHIRHelpers.ToDateTime(choice as FHIR.instant)]
    when choice is FHIR.Age then
      Interval[FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity(choice as FHIR.Age),
        FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity(choice as FHIR.Age) + 1 year)
    when choice is FHIR.Range then
      Interval[FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity((choice as FHIR.Range).low),
        FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity((choice as FHIR.Range).high) + 1 year)
    when choice is FHIR.Timing then
      Message(null as Interval<DateTime>, true, '1', 'Error', 'Cannot compute a single interval from a Timing type')
    when choice is FHIR.string then
      Message(null as Interval<DateTime>, true, '1', 'Error', 'Cannot compute an interval from a String value')
    else
      null as Interval<DateTime>
  end

/*
@description: Returns an interval representing the normalized Abatement of a given Condition resource.
@comment: NOTE: Due to the complexity of determining an interval from a String, this function will throw
a run-time exception if used with a Condition instance that has a String as the abatement value.
*/
define function AbatementInterval(condition Condition):
  if condition.abatement is FHIR.dateTime then
    Interval[FHIRHelpers.ToDateTime(condition.abatement as FHIR.dateTime), FHIRHelpers.ToDateTime(condition.abatement as FHIR.dateTime)]
  else if condition.abatement is FHIR.Period then
    FHIRHelpers.ToInterval(condition.abatement as FHIR.Period)
  else if condition.abatement is FHIR.string then
    Message(null as Interval<DateTime>, true, '1', 'Error', 'Cannot compute an interval from a String value')
  else if condition.abatement is FHIR.Age then
    Interval[FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity(condition.abatement as FHIR.Age),
      FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity(condition.abatement as FHIR.Age) + 1 year)
  else if condition.abatement is FHIR.Range then
    Interval[FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity((condition.abatement as FHIR.Range).low),
      FHIRHelpers.ToDate(Patient.birthDate) + FHIRHelpers.ToQuantity((condition.abatement as FHIR.Range).high) + 1 year)
  else if condition.abatement is FHIR.boolean then
    Interval[end of ToInterval(condition.onset), condition.recordedDate)
  else null

/*
@description: Returns an interval representing the normalized prevalence period of a given Condition resource.
@comment: Uses the ToInterval and ToAbatementInterval functions to determine the widest potential interval from
onset to abatement as specified in the given Condition.
*/
define function PrevalenceInterval(condition Condition):
  if condition.clinicalStatus ~ "active"
    or condition.clinicalStatus ~ "recurrence"
    or condition.clinicalStatus ~ "relapse" then
    Interval[start of ToInterval(condition.onset), end of AbatementInterval(condition)]
  else
    Interval[start of ToInterval(condition.onset), end of AbatementInterval(condition))

/* FHIR Extensions */

/*
@description: Returns any extensions defined on the given resource with the specified url.
@comment: NOTE: Extensions are not the preferred approach, but are used as a way to access
content that is defined by extensions but not yet surfaced in the
CQL model info.
*/
define function Extensions(domainResource DomainResource, url String):
  domainResource.extension E
	  where E.url = url
		return E

/*
@description: Returns the single extension (if present) on the given resource with the specified url.
@comment: This function uses singleton from to ensure that a run-time exception is thrown if there
is more than one extension on the given resource with the specified url.
*/
define function Extension(domainResource DomainResource, url String):
  singleton from Extensions(domainResource, url)

/*
@description: Returns any extensions defined on the given element with the specified url.
@comment: NOTE: Extensions are not the preferred approach, but are used as a way to access
content that is defined by extensions but not yet surfaced in the CQL model info.
*/
define function Extensions(element Element, url String):
  element.extension E
	  where E.url = url
		return E

/*
@description: Returns the single extension (if present) on the given element with the specified url.
@comment: This function uses singleton from to ensure that a run-time exception is thrown if there
is more than one extension on the given resource with the specified url.
*/
define function Extension(element Element, url String):
  singleton from Extensions(element, url)

/*
@description: Returns any modifier extensions defined on the given resource with the specified url.
@comment: NOTE: Extensions are not the preferred approach, but are used as a way to access
content that is defined by extensions but not yet surfaced in the
CQL model info.
*/
define function ModifierExtensions(domainResource DomainResource, url String):
  domainResource.modifierExtension E
	  where E.url = url
		return E

/*
@description: Returns the single modifier extension (if present) on the given resource with the specified url.
@comment: This function uses singleton from to ensure that a run-time exception is thrown if there
is more than one extension on the given resource with the specified url.
*/
define function ModifierExtension(domainResource DomainResource, url String):
  singleton from ModifierExtensions(domainResource, url)

/*
@description: Returns any modifier extensions defined on the given element with the specified url.
@comment: NOTE: Extensions are not the preferred approach, but are used as a way to access
content that is defined by extensions but not yet surfaced in the CQL model info.
*/
define function ModifierExtensions(element BackboneElement, url String):
  element.modifierExtension E
	  where E.url = url
		return E

/*
@description: Returns the single modifier extension (if present) on the given element with the specified url.
@comment: This function uses singleton from to ensure that a run-time exception is thrown if there
is more than one extension on the given resource with the specified url.
*/
define function ModifierExtension(element BackboneElement, url String):
  singleton from ModifierExtensions(element, url)

/*
@description: Surfaces the [resolutionAge](http://hl7.org/fhir/StructureDefinition/allergyintolerance-resolutionAge)
extension defined in FHIR.
@comment: This function returns the value of the extension as an Age.
@extension: http://hl7.org/fhir/StructureDefinition/allergyintolerance-resolutionAge
*/
define function ResolutionAge(allergyIntolerance AllergyIntolerance):
  Extension(allergyIntolerance, 'http://hl7.org/fhir/StructureDefinition/allergyintolerance-resolutionAge').value as Age

/*
@description: Surfaces the [reasonRefuted](http://hl7.org/fhir/StructureDefinition/allergyintolerance-reasonRefuted)
extension defined in FHIR.
@comment: This function returns the value of the extension as a CodeableConcept.
@extension: http://hl7.org/fhir/StructureDefinition/allergyintolerance-reasonRefuted
*/
define function ReasonRefuted(allergyIntolerance AllergyIntolerance):
  Extension(allergyIntolerance, 'http://hl7.org/fhir/StructureDefinition/allergyintolerance-reasonRefuted').value as CodeableConcept

/*
@description: Surfaces the [duration](http://hl7.org/fhir/StructureDefinition/allergyintolerance-duration)
extension defined in FHIR.
@comment: This function returns the value of the extension as a Duration.
@extension: http://hl7.org/fhir/StructureDefinition/allergyintolerance-duration
*/
define function Duration(allergyIntolerance BackboneElement):
  Extension(allergyIntolerance, 'http://hl7.org/fhir/StructureDefinition/allergyintolerance-duration').value as Duration

/*
@description: Surfaces the [dueTo](http://hl7.org/fhir/StructureDefinition/condition-dueTo)
extension defined in FHIR.
@comment: This function returns the value of the extension as a choice of CodeableConcept or Reference.
@extension: http://hl7.org/fhir/StructureDefinition/condition-dueTo
*/
define function DueTo(condition Condition):
  Extension(condition, 'http://hl7.org/fhir/StructureDefinition/condition-dueTo').value as Choice<CodeableConcept, Reference>

/*
@description: Surfaces the [occurredFollowing](http://hl7.org/fhir/StructureDefinition/condition-occurredFollowing)
extension defined in FHIR.
@comment: This function returns the value of the extension as a choice of CodeableConcept or Reference
@extension: http://hl7.org/fhir/StructureDefinition/condition-occurredFollowing
*/
define function OccurredFollowing(condition Condition):
  Extension(condition, 'http://hl7.org/fhir/StructureDefinition/condition-occurredFollowing').value as Choice<CodeableConcept, Reference>

/*
@description: Surfaces the [doNotPerform](http://hl7.org/fhir/5.0/StructureDefinition/extension-DeviceRequest.doNotPerform)
modifier extension defined in FHIR.
@comment: This function returns the value of the modifier extension as a boolean
@extension: http://hl7.org/fhir/StructureDefinition/request-doNotPerform
*/
define function DoNotPerform(requestResource DomainResource):
  ModifierExtension(requestResource, 'http://hl7.org/fhir/5.0/StructureDefinition/extension-DeviceRequest.doNotPerform').value as boolean

/*
@description: Surfaces the [statusReason](http://hl7.org/fhir/StructureDefinition/request-statusReason)
extension defined in FHIR.
@comment: This function returns the value of the extension as a CodeableConcept
@extension: http://hl7.org/fhir/StructureDefinition/request-statusReason
*/
define function StatusReason(requestResource DomainResource):
  Extension(requestResource, 'http://hl7.org/fhir/StructureDefinition/request-statusReason').value as CodeableConcept

/*
@description: Surfaces the [locationPerformed](http://hl7.org/fhir/StructureDefinition/diagnosticReport-locationPerformed)
extension defined in FHIR.
@comment: This function returns the value of the extension as a Reference
@extension: http://hl7.org/fhir/StructureDefinition/diagnosticReport-locationPerformed
*/
define function LocationPerformed(diagnosticReport DiagnosticReport):
  Extension(diagnosticReport, 'http://hl7.org/fhir/StructureDefinition/diagnosticReport-locationPerformed').value as Reference

/*
@description: Surfaces the [abatement](http://hl7.org/fhir/StructureDefinition/familymemberhistory-abatement)
extension defined in FHIR.
@comment: This function returns the value of the extension as a choice of date, Age, or boolean
@extension: http://hl7.org/fhir/StructureDefinition/familymemberhistory-abatement
*/
define function Abatement(familyMemberHistory FamilyMemberHistory):
  Extension(familyMemberHistory, 'http://hl7.org/fhir/StructureDefinition/familymemberhistory-abatement').value as Choice<date, Age, boolean>

/*
@description: Surfaces the [severity](http://hl7.org/fhir/StructureDefinition/familymemberhistory-severity)
extension defined in FHIR.
@comment: This function returns the value of the extension as a CodeableConcept
@extension: http://hl7.org/fhir/StructureDefinition/familymemberhistory-severity
*/
define function Severity(familyMemberHistory FamilyMemberHistory):
  Extension(familyMemberHistory, 'http://hl7.org/fhir/StructureDefinition/familymemberhistory-severity').value as CodeableConcept

/*
@description: Surfaces the [reasonRejected](http://hl7.org/fhir/StructureDefinition/goal-reasonRejected)
extension defined in FHIR.
@comment: This function returns the value of the extension as a CodeableConcept
@extension: http://hl7.org/fhir/StructureDefinition/goal-reasonRejected
*/
define function ReasonRejected(goal Goal):
  Extension(goal, 'http://hl7.org/fhir/StructureDefinition/goal-reasonRejected').value as CodeableConcept

/*
@description: Surfaces the [bodyPosition](http://hl7.org/fhir/StructureDefinition/observation-bodyPosition)
extension defined in FHIR.
@comment: This function returns the value of the extension as a CodeableConcept
@extension: http://hl7.org/fhir/StructureDefinition/observation-bodyPosition
*/
define function BodyPosition(observation Observation):
  Extension(observation, 'http://hl7.org/fhir/StructureDefinition/observation-bodyPosition').value as CodeableConcept

/*
@description: Surfaces the [delta](http://hl7.org/fhir/StructureDefinition/observation-delta)
extension defined in FHIR.
@comment: This function returns the value of the extension as a CodeableConcept
@extension: http://hl7.org/fhir/StructureDefinition/observation-delta
*/
define function Delta(observation Observation):
  Extension(observation, 'http://hl7.org/fhir/StructureDefinition/observation-delta').value as CodeableConcept

/*
@description: Surfaces the [preferred](http://hl7.org/fhir/StructureDefinition/iso21090-preferred) extension defined in USCore.
@comment: This function returns the value of the direct extension as a boolean
@extension: http://hl7.org/fhir/StructureDefinition/iso21090-preferred
*/
define function Preferred(contactPoint ContactPoint):
  Extension(contactPoint, 'http://hl7.org/fhir/StructureDefinition/iso21090-preferred').value as boolean

/*
@description: Surfaces the [approachBodyStructure](http://hl7.org/fhir/StructureDefinition/procedure-approachBodyStructure)
extension defined in FHIR.
@comment: This function returns the value of the extension as a Reference
@extension: http://hl7.org/fhir/StructureDefinition/procedure-approachBodyStructure
*/
define function ApproachBodyStructure(procedure Procedure):
  Extension(procedure, 'http://hl7.org/fhir/StructureDefinition/procedure-approachBodyStructure').value as Reference

/*
@description: Surfaces the [incisionDateTime](http://hl7.org/fhir/StructureDefinition/procedure-incisionDateTime)
extension defined in FHIR.
@comment: This function returns the value of the extension as a dateTime
@extension: http://hl7.org/fhir/StructureDefinition/procedure-incisionDateTime
*/
define function IncisionDateTime(procedure Procedure):
  Extension(procedure, 'http://hl7.org/fhir/StructureDefinition/procedure-incisionDateTime').value as dateTime

/* USCore Extensions */
/*
@description: Surfaces the [ethnicity](http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity)
extension defined in USCore.
@comment: This function returns a tuple with elements for each subextension (ombCategory, detailed, and text).
@extension: http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity
*/
define function Ethnicity(patient Patient):
  patient P
    let ethnicityEx: Extension(P, 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity')
    return
      {
        ombCategory: Extension(ethnicityEx, 'ombCategory').value as Coding,
        detailed:
          (Extensions(ethnicityEx, 'detailed')) E
            return E.value as Coding,
        text: Extension(ethnicityEx, 'text').value as string
      }

/*
@description: Surfaces the [race](http://hl7.org/fhir/us/core/StructureDefinition/us-core-race) extension defined in USCore.
@comment: This function returns a tuple with elements for each subextension (ombCategory, detailed, and text).
@extension: http://hl7.org/fhir/us/core/StructureDefinition/us-core-race
*/
define function Race(patient Patient):
  patient P
    let raceEx: Extension(P, 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race')
    return
      {
        ombCategory:
          (Extensions(raceEx, 'ombCategory')) E
            return E.value as Coding,
        detailed:
          (Extensions(raceEx, 'detailed')) E
            return E.value as Coding,
        text: Extension(raceEx, 'text').value as string
      }

/*
@description: Surfaces the [birthsex](http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex) extension defined in USCore.
@comment: This function returns the value of the birthsex extension as a code
@extension: http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex
*/
define function Birthsex(patient Patient):
  Extension(patient, 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex').value as code

/*
@description: Surfaces the [direct](http://hl7.org/fhir/us/core/StructureDefinition/us-core-direct) extension defined in USCore.
@comment: This function returns the value of the direct extension as a boolean
@extension: http://hl7.org/fhir/us/core/StructureDefinition/us-core-direct
*/
define function Direct(contactPoint ContactPoint):
  Extension(contactPoint, 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-direct').value as boolean

/* QICore Extensions */

/*
@description: Surfaces the [isElective](http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-isElective)
modifier extension defined in QICore.
@comment: This function returns the value of the isElective modifier extension as a boolean.
@extension: http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-isElective
*/
define function IsElective(serviceRequest ServiceRequest):
  ModifierExtension(serviceRequest, 'http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-isElective').value as boolean

/*
@description: Surfaces the [procedure](http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-encounter-procedure)
extension defined in QICore.
@comment: This function returns a tuple with elements for each subextension (type, rank, and procedure).
@extension: http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-encounter-procedure
*/
define function Procedure(encounter Encounter):
  (Extensions(encounter, 'http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-encounter-procedure')) E
    return {
      type: Extension(E, 'type').value as CodeableConcept,
      rank: Extension(E, 'rank').value as positiveInt,
      procedure: Extension(E, 'procedure').value as Reference
    }

/*
@description: Surfaces the [doNotPerform](http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-doNotPerformReason)
extension defined in QICore.
@comment: This function returns the value of the extension as a CodeableConcept
@extension: http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-doNotPerformReason
*/
define function DoNotPerformReason(requestResource DomainResource):
  Extension(requestResource, 'http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-doNotPerformReason').value as CodeableConcept

/*
@description: Surfaces the [recorded](http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-recorded)
extension defined in QICore.
@comment: This function returns the value of the extension as a dateTime
@extension: http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-recorded
*/
define function Recorded(domainResource DomainResource):
  Extension(domainResource, 'http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-recorded').value as dateTime

/*
@description: Surfaces the [notDone](http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-notDone)
modifier extension defined in QICore.
@comment: This function returns the value of the modifier extension as a boolean
@extension: http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-notDone
*/
define function NotDone(eventResource DomainResource):
  ModifierExtension(eventResource, 'http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-notDone').value as boolean

/*
@description: Surfaces the [notDoneReason](http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-notDoneReason)
extension defined in QICore.
@comment: This function returns the value of the extension as a CodeableConcept
@extension: http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-notDoneReason
*/
define function NotDoneReason(eventResource DomainResource):
  Extension(eventResource, 'http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-notDoneReason').value as CodeableConcept

/*
@description: Surfaces the [notDoneValueSet](http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-notDoneValueSet)
extension defined in QICore.
@comment: This function returns the value of the extension as a canonical
@extension: http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-notDoneValueSet
*/
define function NotDoneValueSet(concept CodeableConcept):
  Extension(concept, 'http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-notDoneValueSet').value as canonical

/*
@description: Surfaces the [presentOnAdmission](http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-encounter-diagnosisPresentOnAdmission)
extension defined in QICore.
@comment: This function returns the value of the extension as a CodeableConcept
@extension: http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-encounter-diagnosisPresentOnAdmission
*/
define function PresentOnAdmission(element Element):
  Extension(element, 'http://hl7.org/fhir/us/qicore/StructureDefinition/qicore-encounter-diagnosisPresentOnAdmission').value as CodeableConcept

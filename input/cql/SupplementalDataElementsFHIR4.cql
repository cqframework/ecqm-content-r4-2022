/*
@update: BTR 2020-03-31 ->
Incremented version to 2.0.0

@update: BTR 2022-05-26 ->
Updated FHIR version to 4.0.1
Updated FHIRHelpers version to 4.0.002
Updated for AU 2022 Content
*/

library SupplementalDataElementsFHIR4 version '3.0.000'

using FHIR version '4.0.1'

include FHIRHelpers version '4.1.000' called FHIRHelpers
include QICoreCommon version '1.0.000' called QICore

valueset "Ethnicity": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.837'
valueset "ONC Administrative Sex": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1'
valueset "Payer": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.3591'
valueset "Race": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.836'

context Patient

/*
@description: returns the ethnicity for the patient in context as a FHIR CodeableConcept
*/
define "SDE Ethnicity":
  (QICore.Ethnicity(Patient)) E
    return FHIR.CodeableConcept {
      coding: { E.ombCategory } union E.detailed,
      text: E.text
    }

/*
@description: returns the payers and associated coverage period for each coverage record for the patient in context
*/
define "SDE Payer":
  [Coverage: type in "Payer"] Payer
    return {
      code: Payer.type,
      period: Payer.period
    }

/*
@description: returns the race for the patient in context as a FHIR CodeableConcept
*/
define "SDE Race":
  (QICore.Race(Patient)) R
    return FHIR.CodeableConcept {
      coding: R.ombCategory union R.detailed,
      text: R.text
    }

/*
@description: returns the administrative sex for the patient in context as a Code
*/
define "SDE Sex":
  case
      when Patient.gender = 'male' then Code { code: 'M', system: 'http://hl7.org/fhir/v3/AdministrativeGender', display: 'Male' }
      when Patient.gender = 'female' then Code { code: 'F', system: 'http://hl7.org/fhir/v3/AdministrativeGender', display: 'Female' }
      else null
    end

library HybridHospitalWideReadmissionFHIR version '0.0.001'

/*Specifications based on QDM CMS529v3.1*/

using FHIR version '4.0.1'

include FHIRHelpers version '4.1.000' called FHIRHelpers
include SupplementalDataElementsFHIR4 version '3.0.000' called SDE
include MATGlobalCommonFunctionsFHIR4 version '7.0.000' called Global
include FHIRCommon version '1.1.000' called FHIRCommon
include QICoreCommon version '1.0.000' called QICoreCommon

codesystem "LOINC:2.69": 'http://loinc.org' version '2.69'

valueset "Acute care hospital Inpatient Encounter": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.2289' 
valueset "Bicarbonate lab test": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.139' 
valueset "Body temperature": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.152' 
valueset "Body weight": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.159' 
valueset "Creatinine lab test": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.2363' 
valueset "Emergency Department Visit": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.292' 
valueset "Encounter Inpatient": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.307' 
valueset "Ethnicity": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.837' 
valueset "Glucose lab test": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.134' 
valueset "Heart Rate": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.149' 
valueset "Hematocrit lab test": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.114' 
valueset "Medicare payer": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1104.10' 
valueset "Observation Services": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1111.143' 
valueset "ONC Administrative Sex": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1' 
valueset "Oxygen Saturation by Pulse Oximetry": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.151' 
valueset "Payer": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.3591' 
valueset "Potassium lab test": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.117' 
valueset "Race": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.836' 
valueset "Respiratory Rate": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.130' 
valueset "Sodium lab test": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.119' 
valueset "Systolic Blood Pressure": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.163' 
valueset "White blood cells count lab test": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1045.129' 

code "Birth date": '21112-8' from "LOINC:2.69" display 'Birth date'

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

define "Initial Population":
  "Inpatient Encounters"

define "Inpatient Encounters":
  from
   ["Encounter": "Encounter Inpatient"] InpatientEncounter,
        ["Coverage": "Medicare payer"] Payer 
        where InpatientEncounter.status='finished'
                and Global."LengthInDays" (Global."HospitalizationWithObservation" ( InpatientEncounter )) < 365
            and InpatientEncounter.period ends during day of "Measurement Period"
            and AgeInYearsAt(date from start of InpatientEncounter.period)>= 65
            return InpatientEncounter

define "Results":
  flatten{
     // First physical exams (vital signs)
          "FirstPhysicalExamWithEncounterId"([Observation: "Heart Rate"], 'FirstHeartRate'),
           "FirstPhysicalExamWithEncounterId"([Observation: "Systolic Blood Pressure"], 'FirstSystolicBP'),
          "FirstPhysicalExamWithEncounterId"([Observation: "Respiratory Rate"], 'FirstRespRate'),
          "FirstPhysicalExamWithEncounterId"([Observation: "Body temperature"],  'FirstTemperature'),
          "FirstPhysicalExamWithEncounterId"([Observation: "Oxygen Saturation by Pulse Oximetry"], 'FirstO2Saturation'),
                                                                                          
      // First weight using lab test timing
           "FirstPhysicalExamWithEncounterIdUsingLabTiming"([Observation: "Body weight"], 'FirstWeight'), 
       //First lab tests
           "FirstLabTestWithEncounterId"([Observation: "Hematocrit lab test"], 'FirstHematocrit'),
            "FirstLabTestWithEncounterId"([Observation: "White blood cells count lab test"], 'FirstWhiteBloodCell'),
            "FirstLabTestWithEncounterId"([Observation: "Potassium lab test"], 'FirstPotassium'),
             "FirstLabTestWithEncounterId"([Observation: "Sodium lab test"], 'FirstSodium'),
              "FirstLabTestWithEncounterId"([Observation: "Bicarbonate lab test"], 'FirstBicarbonate'),
               "FirstLabTestWithEncounterId"([Observation: "Creatinine lab test"], 'FirstCreatinine'),
               "FirstLabTestWithEncounterId"([Observation: "Glucose lab test"], 'FirstGlucose')
    }

define function "FirstPhysicalExamWithEncounterId"(ExamList List<FHIR.Observation>, CCDE String ):
  "Inpatient Encounters" Encounter
  let firstexam: First(ExamList Exam
      where start of Global."Normalize Interval"(Exam.effective) is not null and start of Global."Normalize Interval"(Exam.effective) during Interval[start of Encounter.period - 1440 minutes, start of Encounter.period + 120 minutes]
      and Exam.status in {'final', 'amended', 'preliminary'}
      and Exam.value is not null
      sort by start of Global."Normalize Interval"(effective) )
  return '\r\n' & CCDE & ',' & Encounter.id & ',' & (ToString(firstexam.value as FHIR.Quantity)) & ',' & ToString(start of Global."Normalize Interval" (firstexam.effective))

define function "FirstPhysicalExamWithEncounterIdUsingLabTiming"(ExamList List<FHIR.Observation>, CCDE String ):
  "Inpatient Encounters" Encounter
  let firstexamwithlabtiming: First(ExamList Exam
      where start of Global."Normalize Interval"(Exam.effective) is not null and start of Global."Normalize Interval"(Exam.effective) during Interval[start of Encounter.period - 1440 minutes, start of Encounter.period + 1440 minutes]
  and Exam.status in {'final', 'amended', 'preliminary'}
  and Exam.value is not null
  sort by start of Global."Normalize Interval"(effective) )
  return '\r\n' & CCDE & ',' & Encounter.id & ',' & (ToString(firstexamwithlabtiming.value as FHIR.Quantity)) & ',' & ToString(start of Global."Normalize Interval" (firstexamwithlabtiming.effective))

define function "FirstLabTestWithEncounterId"(LabList List<FHIR.Observation>, CCDE String ):
  "Inpatient Encounters" Encounter
  let firstlab: First(LabList Lab
   where Lab.issued is not null and Lab.issued during Interval[start of Encounter.period - 1440 minutes, start of Encounter.period + 1440 minutes]   and Lab.status in {'final', 'amended', 'preliminary'} and Lab.value is not null 
     sort by issued )
  return '\r\n' & CCDE & ',' & Encounter.id & ',' & (ToString(firstlab.value as FHIR.Quantity)) & ',' & ToString(firstlab.issued)


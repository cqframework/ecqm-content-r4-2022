# ecqm-content-r4-2022
eCQM Draft Measure Content (2022 AU Content, using FHIR R4 v4.0.1)

This repository contains the draft measure artifacts for FHIR based eCQMs. These specifications are based on the 2022 AU versions of CMS program measures.

Commits to this repository will automatically trigger a build of the continuous integration build, available here:

https://build.fhir.org/ig/cqframework/ecqm-content-r4-2022

## Content Index

The following table provides an index to the currently available library content in this implementation guide:

### Shared Libraries

|Library|Version|Status|
|----|----|----|
|[AdultOutpatientEncountersFHIR4](input/cql/AdultOutpatientEncountersFHIR4.cql)|3.0.000|Active|
|[AdvancedIllnessandFrailtyExclusionECQMFHIR4](input/cql/AdvancedIllnessandFrailtyExclusionECQMFHIR4.cql)|7.0.000|Active|
|[CumulativeMedicationDurationFHIR4](input/cql/CumulativeMedicationDurationFHIR4.cql)|2.0.000|Active|
|[FHIRHelpers](input/cql/FHIRHelpers.cql)|4.0.002|Active|
|TODO: [HospiceFHIR4](input/cql/HospiceFHIR4.cql)|2.3.000|Active|
|[MATGlobalCommonFunctionsFHIR4](input/cql/MATGlobalCommonFunctionsFHIR4.cql)|7.0.000|Active|
|TODO: [PalliativeCareFHIR](input/cql/PalliativeCareFHIR.cql)|0.6.000|Active|
|[QICoreCommon](input/cql/QICoreCommon.cql)|4.1.2|Active|
|[SupplementalDataElementsFHIR4](input/cql/SupplementalDataElementsFHIR4.cql)|3.0.000|Active|
|TODO: [TJCOverallFHIR](input/cql/TJCOverallFHIR.cql)|1.8.000|Active|
|TODO: [VTEFHIR4](input/cql/VTEFHIR4.cql)|4.8.000|Active|

### Measure Libraries

|Library|Version|Status|
|----|----|----|

### Measures

|Measure|Description|
|----|----|

## Repository Structure
It is setup like any HL7 FHIR IG project but also includes the CQL files and test data which means the file structure will be as follows:

```
   |-- _genonce.bat
   |-- _genonce.sh
   |-- _refresh.bat
   |-- _refresh.sh
   |-- _updatePublisher.bat
   |-- _updatePublisher.sh
   |-- _updateCQFTooling.bat
   |-- _updateCQFTooling.sh
   |-- ig.ini
   |-- bundles
       |-- mat
           |--<mat export bundles>
       |-- measure
           |--EXM124
   |-- input
       |-- ecqm-content-r4-2022.xml
       |-- cql
           |-- EXM124.cql
       |-- resources
           |-- library
               |-- EXM124.json
           |-- measure
               |-- EXM124.json
       |-- tests
           |-- measure
               |-- EXM124
       |-- vocabulary
           |-- valueset
```

## Refresh IG Processing

The CQF Tooling provides support for refreshing measure and library resources based on
the content of the CQL libraries, as well as packaging the measures as artifacts that
include dependencies and test cases.

To run this tooling, make sure it is available locally using the _updateCQFTooling script,
then run the _refresh script. This script should be run whenever CQL content changes,
and prior to the publishing process.

## Extracting MAT Packages

The CQF Tooling provides support for extracting a MAT exported package into the
directories of this repository so that the measure is included in the published
implementation guide. To do this, place the MAT export files (unzipped) in a
directory in the `bundles\mat` directory, and then run the following tooling
command:

```
[tooling-jar] -ExtractMatBundle bundles\mat\[bundle-directory]\[bundle-file]
```

For example:

```
input-cache\tooling-1.4.1-SNAPSHOT-jar-with-dependencies.jar -ExtractMATBundle bundles\mat\CLONE124_v6_03-Artifacts\measure-json-bundle.json
```

Then run the `_refresh` command to refresh the implementation guide content with
the new content, and then run `_genonce` to publish the implementation guide.

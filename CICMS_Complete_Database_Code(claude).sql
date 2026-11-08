/* =====================================================================
   CICMS - Crime Investigation & Case Management System
   Database : CrimeInvestigationDB          Platform : Microsoft SQL Server (SSMS)

   What this script does (run it top to bottom, once, with F5):
     1. Drops and recreates the CrimeInvestigationDB database, so it can be re-run safely.
     2. Creates 49 tables with named primary keys, foreign keys, defaults and checks.
     3. Creates indexes and one view.
     4. Loads lookup data and a complete set of made-up sample records.
     5. Runs 400 numbered practice queries (Query 1 to Query 400).

   Tips
     * Every query prints its number in the Messages tab, so you can see which grid is which.
     * 400 result grids is a lot. In SSMS: Query > Query Options > Results > Grid >
       "Discard results after execution" lets you check for errors without opening every grid.
       Or select a single query and press F5 to run just that one.
     * Queries 381-400 are quality checks. Several are labelled "expect 0 rows";
       an empty result there means the data is healthy.

   All people, case numbers, FIR numbers, hashes, phone numbers and documents are fictional
   and exist only for learning. Legal provisions are placeholders, not real section numbers.
   ===================================================================== */

USE master;
GO

IF DB_ID(N'CrimeInvestigationDB') IS NOT NULL
BEGIN
    ALTER DATABASE CrimeInvestigationDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CrimeInvestigationDB;
END
GO

CREATE DATABASE CrimeInvestigationDB COLLATE SQL_Latin1_General_CP1_CI_AS;
GO

USE CrimeInvestigationDB;
GO

-- =====================================================================
-- STEP 1: TABLES
-- =====================================================================

-- ---- Location and police structure ----

CREATE TABLE dbo.States
(
    StateID INT IDENTITY(1,1) CONSTRAINT PK_States PRIMARY KEY,
    StateName NVARCHAR(100) NOT NULL CONSTRAINT UQ_States_StateName UNIQUE,
    StateCode CHAR(2) NOT NULL CONSTRAINT UQ_States_StateCode UNIQUE
);

CREATE TABLE dbo.Districts
(
    DistrictID INT IDENTITY(1,1) CONSTRAINT PK_Districts PRIMARY KEY,
    StateID INT NOT NULL CONSTRAINT FK_Districts_StateID REFERENCES dbo.States(StateID),
    DistrictName NVARCHAR(100) NOT NULL,
    DistrictCode VARCHAR(10) NOT NULL CONSTRAINT UQ_Districts_DistrictCode UNIQUE,
    CONSTRAINT UQ_District_State_Name UNIQUE(StateID, DistrictName)
);

CREATE TABLE dbo.PoliceStations
(
    PoliceStationID INT IDENTITY(1,1) CONSTRAINT PK_PoliceStations PRIMARY KEY,
    DistrictID INT NOT NULL CONSTRAINT FK_PoliceStations_DistrictID REFERENCES dbo.Districts(DistrictID),
    PoliceStationName NVARCHAR(150) NOT NULL,
    StationCode VARCHAR(20) NOT NULL CONSTRAINT UQ_PoliceStations_StationCode UNIQUE,
    StationAddress NVARCHAR(300) NOT NULL,
    ContactPhone VARCHAR(20) NULL,
    EmailAddress VARCHAR(254) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_PoliceStations_IsActive DEFAULT 1,
    CONSTRAINT UQ_Station_District_Name UNIQUE(DistrictID, PoliceStationName)
);

CREATE TABLE dbo.PoliceUnits
(
    PoliceUnitID INT IDENTITY(1,1) CONSTRAINT PK_PoliceUnits PRIMARY KEY,
    PoliceStationID INT NOT NULL CONSTRAINT FK_PoliceUnits_PoliceStationID REFERENCES dbo.PoliceStations(PoliceStationID),
    UnitName NVARCHAR(120) NOT NULL,
    UnitType NVARCHAR(60) NOT NULL,
    UnitDescription NVARCHAR(500) NULL,
    CONSTRAINT UQ_Unit_Station_Name UNIQUE(PoliceStationID, UnitName)
);

CREATE TABLE dbo.PoliceRanks
(
    PoliceRankID INT IDENTITY(1,1) CONSTRAINT PK_PoliceRanks PRIMARY KEY,
    RankName NVARCHAR(80) NOT NULL CONSTRAINT UQ_PoliceRanks_RankName UNIQUE,
    RankLevel TINYINT NOT NULL CONSTRAINT UQ_PoliceRanks_RankLevel UNIQUE
);

CREATE TABLE dbo.PoliceOfficers
(
    PoliceOfficerID INT IDENTITY(1,1) CONSTRAINT PK_PoliceOfficers PRIMARY KEY,
    ServiceNumber VARCHAR(30) NOT NULL CONSTRAINT UQ_PoliceOfficers_ServiceNumber UNIQUE,
    FirstName NVARCHAR(80) NOT NULL,
    MiddleName NVARCHAR(80) NULL,
    LastName NVARCHAR(80) NOT NULL,
    PoliceRankID INT NOT NULL CONSTRAINT FK_PoliceOfficers_PoliceRankID REFERENCES dbo.PoliceRanks(PoliceRankID),
    WorkPhone VARCHAR(20) NULL,
    WorkEmail VARCHAR(254) NULL,
    DateOfJoining DATE NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_PoliceOfficers_IsActive DEFAULT 1
);

CREATE TABLE dbo.OfficerAssignments
(
    OfficerAssignmentID INT IDENTITY(1,1) CONSTRAINT PK_OfficerAssignments PRIMARY KEY,
    PoliceOfficerID INT NOT NULL CONSTRAINT FK_OfficerAssignments_PoliceOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    PoliceStationID INT NOT NULL CONSTRAINT FK_OfficerAssignments_PoliceStationID REFERENCES dbo.PoliceStations(PoliceStationID),
    PoliceUnitID INT NULL CONSTRAINT FK_OfficerAssignments_PoliceUnitID REFERENCES dbo.PoliceUnits(PoliceUnitID),
    AssignmentStartDate DATE NOT NULL,
    AssignmentEndDate DATE NULL,
    IsPrimaryAssignment BIT NOT NULL CONSTRAINT DF_OfficerAssignments_IsPrimaryAssignment DEFAULT 0,
    CONSTRAINT CK_OfficerAssignment_Dates CHECK(AssignmentEndDate IS NULL OR AssignmentEndDate >= AssignmentStartDate)
);

-- ---- People ----

CREATE TABLE dbo.Persons
(
    PersonID INT IDENTITY(1,1) CONSTRAINT PK_Persons PRIMARY KEY,
    GivenName NVARCHAR(80) NOT NULL,
    MiddleName NVARCHAR(80) NULL,
    FamilyName NVARCHAR(80) NOT NULL,
    DateOfBirth DATE NULL,
    Gender NVARCHAR(30) NULL,
    PreferredLanguage NVARCHAR(50) NULL,
    PersonNotes NVARCHAR(1000) NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Persons_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Person_DateOfBirth CHECK(DateOfBirth IS NULL OR DateOfBirth <= CONVERT(date, GETDATE()))
);

CREATE TABLE dbo.PersonAddresses
(
    PersonAddressID INT IDENTITY(1,1) CONSTRAINT PK_PersonAddresses PRIMARY KEY,
    PersonID INT NOT NULL CONSTRAINT FK_PersonAddresses_PersonID REFERENCES dbo.Persons(PersonID),
    AddressType NVARCHAR(30) NOT NULL,
    AddressLine1 NVARCHAR(150) NOT NULL,
    AddressLine2 NVARCHAR(150) NULL,
    Locality NVARCHAR(100) NULL,
    CityOrTown NVARCHAR(100) NOT NULL,
    DistrictID INT NULL CONSTRAINT FK_PersonAddresses_DistrictID REFERENCES dbo.Districts(DistrictID),
    StateID INT NULL CONSTRAINT FK_PersonAddresses_StateID REFERENCES dbo.States(StateID),
    PostalCode VARCHAR(12) NULL,
    ValidFrom DATE NULL,
    ValidTo DATE NULL,
    CONSTRAINT CK_PersonAddress_Dates CHECK(ValidTo IS NULL OR ValidFrom IS NULL OR ValidTo >= ValidFrom)
);

CREATE TABLE dbo.PersonContactMethods
(
    PersonContactMethodID INT IDENTITY(1,1) CONSTRAINT PK_PersonContactMethods PRIMARY KEY,
    PersonID INT NOT NULL CONSTRAINT FK_PersonContactMethods_PersonID REFERENCES dbo.Persons(PersonID),
    ContactType NVARCHAR(30) NOT NULL,
    ContactValue NVARCHAR(254) NOT NULL,
    IsPreferred BIT NOT NULL CONSTRAINT DF_PersonContactMethods_IsPreferred DEFAULT 0,
    IsVerified BIT NOT NULL CONSTRAINT DF_PersonContactMethods_IsVerified DEFAULT 0
);

CREATE TABLE dbo.PersonIdentifiers
(
    PersonIdentifierID INT IDENTITY(1,1) CONSTRAINT PK_PersonIdentifiers PRIMARY KEY,
    PersonID INT NOT NULL CONSTRAINT FK_PersonIdentifiers_PersonID REFERENCES dbo.Persons(PersonID),
    IdentifierType NVARCHAR(40) NOT NULL,
    IdentifierValueEncryptedOrMasked NVARCHAR(150) NOT NULL,
    IssuingAuthority NVARCHAR(120) NULL,
    VerificationStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_PersonIdentifiers_VerificationStatus DEFAULT 'Unverified',
    CONSTRAINT CK_PersonIdentifier_Status CHECK(VerificationStatus IN ('Unverified','Pending','Verified','Rejected'))
);

-- ---- Complaints ----

CREATE TABLE dbo.ComplaintSources
(
    ComplaintSourceID INT IDENTITY(1,1) CONSTRAINT PK_ComplaintSources PRIMARY KEY,
    SourceName NVARCHAR(80) NOT NULL CONSTRAINT UQ_ComplaintSources_SourceName UNIQUE,
    SourceDescription NVARCHAR(300) NULL
);

CREATE TABLE dbo.Complaints
(
    ComplaintID INT IDENTITY(1,1) CONSTRAINT PK_Complaints PRIMARY KEY,
    ComplaintNumber VARCHAR(30) NOT NULL CONSTRAINT UQ_Complaints_ComplaintNumber UNIQUE,
    PoliceStationID INT NOT NULL CONSTRAINT FK_Complaints_PoliceStationID REFERENCES dbo.PoliceStations(PoliceStationID),
    SubmittedByPersonID INT NULL CONSTRAINT FK_Complaints_SubmittedByPersonID REFERENCES dbo.Persons(PersonID),
    ComplaintSourceID INT NOT NULL CONSTRAINT FK_Complaints_ComplaintSourceID REFERENCES dbo.ComplaintSources(ComplaintSourceID),
    ReceivedAt DATETIME2 NOT NULL,
    IncidentDateTime DATETIME2 NULL,
    IncidentLocation NVARCHAR(300) NOT NULL,
    ComplaintSummary NVARCHAR(1000) NOT NULL,
    ComplaintDetails NVARCHAR(MAX) NULL,
    UrgencyLevel NVARCHAR(20) NOT NULL CONSTRAINT DF_Complaints_UrgencyLevel DEFAULT 'Normal',
    ComplaintStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_Complaints_ComplaintStatus DEFAULT 'Received',
    AssignedOfficerID INT NULL CONSTRAINT FK_Complaints_AssignedOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    IsAnonymous BIT NOT NULL CONSTRAINT DF_Complaints_IsAnonymous DEFAULT 0,
    CONSTRAINT CK_Complaint_Urgency CHECK(UrgencyLevel IN ('Low','Normal','High','Critical')),
    CONSTRAINT CK_Complaint_Status CHECK(ComplaintStatus IN ('Received','Under Review','Referred','Registered as FIR','Closed','Declined'))
);

CREATE TABLE dbo.ComplaintUpdates
(
    ComplaintUpdateID INT IDENTITY(1,1) CONSTRAINT PK_ComplaintUpdates PRIMARY KEY,
    ComplaintID INT NOT NULL CONSTRAINT FK_ComplaintUpdates_ComplaintID REFERENCES dbo.Complaints(ComplaintID),
    UpdatedAt DATETIME2 NOT NULL CONSTRAINT DF_ComplaintUpdates_UpdatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedByOfficerID INT NULL CONSTRAINT FK_ComplaintUpdates_UpdatedByOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    PreviousStatus NVARCHAR(30) NULL,
    NewStatus NVARCHAR(30) NOT NULL,
    UpdateNotes NVARCHAR(1000) NULL
);

-- ---- Cases, offences and people involved ----

CREATE TABLE dbo.CrimeCategories
(
    CrimeCategoryID INT IDENTITY(1,1) CONSTRAINT PK_CrimeCategories PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL CONSTRAINT UQ_CrimeCategories_CategoryName UNIQUE,
    CategoryDescription NVARCHAR(500) NULL,
    ParentCategoryID INT NULL CONSTRAINT FK_CrimeCategories_ParentCategoryID REFERENCES dbo.CrimeCategories(CrimeCategoryID),
    IsActive BIT NOT NULL CONSTRAINT DF_CrimeCategories_IsActive DEFAULT 1
);

CREATE TABLE dbo.LegalProvisions
(
    LegalProvisionID INT IDENTITY(1,1) CONSTRAINT PK_LegalProvisions PRIMARY KEY,
    LegislationName NVARCHAR(150) NOT NULL,
    LegislationShortCode NVARCHAR(20) NOT NULL,
    ProvisionNumber NVARCHAR(30) NOT NULL,
    ProvisionTitle NVARCHAR(250) NULL,
    ProvisionSummary NVARCHAR(1000) NULL,
    EffectiveFrom DATE NULL,
    EffectiveTo DATE NULL,
    IsCurrent BIT NOT NULL CONSTRAINT DF_LegalProvisions_IsCurrent DEFAULT 1,
    CONSTRAINT UQ_LegalProvision UNIQUE(LegislationShortCode, ProvisionNumber, EffectiveFrom)
);

CREATE TABLE dbo.CriminalCases
(
    CriminalCaseID INT IDENTITY(1,1) CONSTRAINT PK_CriminalCases PRIMARY KEY,
    CaseNumber VARCHAR(40) NOT NULL CONSTRAINT UQ_CriminalCases_CaseNumber UNIQUE,
    PoliceStationID INT NOT NULL CONSTRAINT FK_CriminalCases_PoliceStationID REFERENCES dbo.PoliceStations(PoliceStationID),
    FIRNumber VARCHAR(40) NULL,
    FIRRegisteredAt DATETIME2 NULL,
    ComplaintID INT NULL CONSTRAINT FK_CriminalCases_ComplaintID REFERENCES dbo.Complaints(ComplaintID),
    CaseTitle NVARCHAR(200) NOT NULL,
    IncidentStartAt DATETIME2 NULL,
    IncidentEndAt DATETIME2 NULL,
    IncidentLocation NVARCHAR(300) NOT NULL,
    CaseSummary NVARCHAR(1500) NOT NULL,
    CaseStatus NVARCHAR(40) NOT NULL CONSTRAINT DF_CriminalCases_CaseStatus DEFAULT 'Registered',
    CasePriority NVARCHAR(20) NOT NULL CONSTRAINT DF_CriminalCases_CasePriority DEFAULT 'Medium',
    OpenedAt DATETIME2 NOT NULL CONSTRAINT DF_CriminalCases_OpenedAt DEFAULT SYSUTCDATETIME(),
    ClosedAt DATETIME2 NULL,
    IsSensitiveCase BIT NOT NULL CONSTRAINT DF_CriminalCases_IsSensitiveCase DEFAULT 0,
    CONSTRAINT CK_Case_Status CHECK(CaseStatus IN ('Registered','Under Investigation','Charge Sheet Filed','Under Trial','Disposed','Closed','Reopened','Transferred')),
    CONSTRAINT CK_Case_Priority CHECK(CasePriority IN ('Low','Medium','High','Critical')),
    CONSTRAINT CK_Case_Dates CHECK((IncidentEndAt IS NULL OR IncidentStartAt IS NULL OR IncidentEndAt >= IncidentStartAt) AND (ClosedAt IS NULL OR ClosedAt >= OpenedAt))
);

CREATE TABLE dbo.CaseOffences
(
    CaseOffenceID INT IDENTITY(1,1) CONSTRAINT PK_CaseOffences PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_CaseOffences_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    CrimeCategoryID INT NOT NULL CONSTRAINT FK_CaseOffences_CrimeCategoryID REFERENCES dbo.CrimeCategories(CrimeCategoryID),
    LegalProvisionID INT NULL CONSTRAINT FK_CaseOffences_LegalProvisionID REFERENCES dbo.LegalProvisions(LegalProvisionID),
    OffenceDescription NVARCHAR(1000) NULL,
    IsPrimaryOffence BIT NOT NULL CONSTRAINT DF_CaseOffences_IsPrimaryOffence DEFAULT 0,
    CONSTRAINT UQ_Case_Offence UNIQUE(CriminalCaseID, CrimeCategoryID, LegalProvisionID)
);

CREATE TABLE dbo.CasePersonRoles
(
    CasePersonRoleID INT IDENTITY(1,1) CONSTRAINT PK_CasePersonRoles PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_CasePersonRoles_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    PersonID INT NOT NULL CONSTRAINT FK_CasePersonRoles_PersonID REFERENCES dbo.Persons(PersonID),
    CaseRole NVARCHAR(40) NOT NULL,
    RoleStartDate DATE NULL,
    RoleEndDate DATE NULL,
    IsIdentityVerified BIT NOT NULL CONSTRAINT DF_CasePersonRoles_IsIdentityVerified DEFAULT 0,
    RoleNotes NVARCHAR(1000) NULL,
    CONSTRAINT CK_CasePerson_Role CHECK(CaseRole IN ('Complainant','Victim','Suspect','Accused','Witness','Informant','Missing Person','Next Of Kin','Other')),
    CONSTRAINT UQ_Case_Person_Role UNIQUE(CriminalCaseID, PersonID, CaseRole)
);

-- ---- Investigation work ----

CREATE TABLE dbo.InvestigationAssignments
(
    InvestigationAssignmentID INT IDENTITY(1,1) CONSTRAINT PK_InvestigationAssignments PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_InvestigationAssignments_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    PoliceOfficerID INT NOT NULL CONSTRAINT FK_InvestigationAssignments_PoliceOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    AssignmentRole NVARCHAR(50) NOT NULL,
    AssignedAt DATETIME2 NOT NULL CONSTRAINT DF_InvestigationAssignments_AssignedAt DEFAULT SYSUTCDATETIME(),
    ReleasedAt DATETIME2 NULL,
    AssignedByOfficerID INT NULL CONSTRAINT FK_InvestigationAssignments_AssignedByOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    AssignmentNotes NVARCHAR(500) NULL,
    CONSTRAINT CK_InvestigationAssignment_Dates CHECK(ReleasedAt IS NULL OR ReleasedAt >= AssignedAt)
);

CREATE TABLE dbo.CaseDiaryEntries
(
    CaseDiaryEntryID INT IDENTITY(1,1) CONSTRAINT PK_CaseDiaryEntries PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_CaseDiaryEntries_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    EntryNumber INT NOT NULL,
    EntryDateTime DATETIME2 NOT NULL,
    PoliceOfficerID INT NOT NULL CONSTRAINT FK_CaseDiaryEntries_PoliceOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    ActivityLocation NVARCHAR(300) NULL,
    EntryNarrative NVARCHAR(MAX) NOT NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_CaseDiaryEntries_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_CaseDiary_Entry UNIQUE(CriminalCaseID, EntryNumber)
);

CREATE TABLE dbo.InvestigationActivities
(
    InvestigationActivityID INT IDENTITY(1,1) CONSTRAINT PK_InvestigationActivities PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_InvestigationActivities_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    PoliceOfficerID INT NOT NULL CONSTRAINT FK_InvestigationActivities_PoliceOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    ActivityType NVARCHAR(80) NOT NULL,
    ActivityStartedAt DATETIME2 NOT NULL,
    ActivityEndedAt DATETIME2 NULL,
    ActivityLocation NVARCHAR(300) NULL,
    ActivityOutcome NVARCHAR(1000) NULL,
    RelatedCaseDiaryEntryID INT NULL CONSTRAINT FK_InvestigationActivities_RelatedCaseDiaryEntryID REFERENCES dbo.CaseDiaryEntries(CaseDiaryEntryID),
    CONSTRAINT CK_InvestigationActivity_Dates CHECK(ActivityEndedAt IS NULL OR ActivityEndedAt >= ActivityStartedAt)
);

CREATE TABLE dbo.WitnessStatements
(
    WitnessStatementID INT IDENTITY(1,1) CONSTRAINT PK_WitnessStatements PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_WitnessStatements_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    WitnessPersonID INT NOT NULL CONSTRAINT FK_WitnessStatements_WitnessPersonID REFERENCES dbo.Persons(PersonID),
    RecordedByOfficerID INT NOT NULL CONSTRAINT FK_WitnessStatements_RecordedByOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    StatementRecordedAt DATETIME2 NOT NULL,
    StatementType NVARCHAR(50) NOT NULL,
    StatementSummary NVARCHAR(1500) NULL,
    SecureDocumentReference NVARCHAR(300) NULL,
    InterpreterRequired BIT NOT NULL CONSTRAINT DF_WitnessStatements_InterpreterRequired DEFAULT 0,
    WitnessReviewedStatement BIT NOT NULL CONSTRAINT DF_WitnessStatements_WitnessReviewedStatement DEFAULT 0
);

CREATE TABLE dbo.Interviews
(
    InterviewID INT IDENTITY(1,1) CONSTRAINT PK_Interviews PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_Interviews_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    PersonID INT NOT NULL CONSTRAINT FK_Interviews_PersonID REFERENCES dbo.Persons(PersonID),
    InterviewingOfficerID INT NOT NULL CONSTRAINT FK_Interviews_InterviewingOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    InterviewStartedAt DATETIME2 NOT NULL,
    InterviewEndedAt DATETIME2 NULL,
    InterviewLocation NVARCHAR(250) NULL,
    InterviewPurpose NVARCHAR(500) NOT NULL,
    InterviewSummary NVARCHAR(1500) NULL,
    RecordingReference NVARCHAR(300) NULL,
    CONSTRAINT CK_Interview_Dates CHECK(InterviewEndedAt IS NULL OR InterviewEndedAt >= InterviewStartedAt)
);

-- ---- Arrests, custody and searches ----

CREATE TABLE dbo.Arrests
(
    ArrestID INT IDENTITY(1,1) CONSTRAINT PK_Arrests PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_Arrests_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    ArrestedPersonID INT NOT NULL CONSTRAINT FK_Arrests_ArrestedPersonID REFERENCES dbo.Persons(PersonID),
    ArrestingOfficerID INT NOT NULL CONSTRAINT FK_Arrests_ArrestingOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    ArrestedAt DATETIME2 NOT NULL,
    ArrestLocation NVARCHAR(300) NOT NULL,
    ArrestGrounds NVARCHAR(1000) NULL,
    ArrestMemoReference VARCHAR(50) NULL,
    ProducedBeforeCourtAt DATETIME2 NULL,
    ArrestStatus NVARCHAR(40) NOT NULL CONSTRAINT DF_Arrests_ArrestStatus DEFAULT 'In Custody',
    CONSTRAINT CK_Arrest_Status CHECK(ArrestStatus IN ('In Custody','Released','Bailed','Judicial Custody','Police Custody','Transferred'))
);

CREATE TABLE dbo.CustodyRecords
(
    CustodyRecordID INT IDENTITY(1,1) CONSTRAINT PK_CustodyRecords PRIMARY KEY,
    ArrestID INT NOT NULL CONSTRAINT FK_CustodyRecords_ArrestID REFERENCES dbo.Arrests(ArrestID),
    CustodyType NVARCHAR(40) NOT NULL,
    CustodyLocation NVARCHAR(200) NOT NULL,
    CustodyStartedAt DATETIME2 NOT NULL,
    CustodyEndedAt DATETIME2 NULL,
    AuthorizedByOfficerID INT NULL CONSTRAINT FK_CustodyRecords_AuthorizedByOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    ReleaseOrTransferReason NVARCHAR(500) NULL,
    CONSTRAINT CK_Custody_Dates CHECK(CustodyEndedAt IS NULL OR CustodyEndedAt >= CustodyStartedAt)
);

CREATE TABLE dbo.SearchAuthorizations
(
    SearchAuthorizationID INT IDENTITY(1,1) CONSTRAINT PK_SearchAuthorizations PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_SearchAuthorizations_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    AuthorizationType NVARCHAR(60) NOT NULL,
    IssuedByAuthority NVARCHAR(200) NULL,
    AuthorizationReference VARCHAR(80) NULL,
    RequestedAt DATETIME2 NULL,
    AuthorizedAt DATETIME2 NULL,
    ValidUntil DATETIME2 NULL,
    AuthorizationStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_SearchAuthorizations_AuthorizationStatus DEFAULT 'Pending',
    DocumentReference NVARCHAR(300) NULL,
    CONSTRAINT CK_SearchAuthorization_Status CHECK(AuthorizationStatus IN ('Pending','Granted','Denied','Expired','Executed','Cancelled'))
);

CREATE TABLE dbo.SearchOperations
(
    SearchOperationID INT IDENTITY(1,1) CONSTRAINT PK_SearchOperations PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_SearchOperations_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    SearchAuthorizationID INT NULL CONSTRAINT FK_SearchOperations_SearchAuthorizationID REFERENCES dbo.SearchAuthorizations(SearchAuthorizationID),
    LeadOfficerID INT NOT NULL CONSTRAINT FK_SearchOperations_LeadOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    SearchStartedAt DATETIME2 NOT NULL,
    SearchEndedAt DATETIME2 NULL,
    SearchLocation NVARCHAR(300) NOT NULL,
    SearchPurpose NVARCHAR(500) NOT NULL,
    SearchOutcome NVARCHAR(1000) NULL,
    CONSTRAINT CK_SearchOperation_Dates CHECK(SearchEndedAt IS NULL OR SearchEndedAt >= SearchStartedAt)
);

-- ---- Evidence and forensics ----

CREATE TABLE dbo.EvidenceTypes
(
    EvidenceTypeID INT IDENTITY(1,1) CONSTRAINT PK_EvidenceTypes PRIMARY KEY,
    EvidenceTypeName NVARCHAR(100) NOT NULL CONSTRAINT UQ_EvidenceTypes_EvidenceTypeName UNIQUE,
    EvidenceTypeDescription NVARCHAR(500) NULL
);

CREATE TABLE dbo.EvidenceItems
(
    EvidenceItemID INT IDENTITY(1,1) CONSTRAINT PK_EvidenceItems PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_EvidenceItems_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    EvidenceTypeID INT NOT NULL CONSTRAINT FK_EvidenceItems_EvidenceTypeID REFERENCES dbo.EvidenceTypes(EvidenceTypeID),
    ExhibitNumber VARCHAR(40) NOT NULL,
    EvidenceDescription NVARCHAR(1000) NOT NULL,
    CollectedAt DATETIME2 NOT NULL,
    CollectionLocation NVARCHAR(300) NOT NULL,
    CollectedByOfficerID INT NOT NULL CONSTRAINT FK_EvidenceItems_CollectedByOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    InitialCondition NVARCHAR(250) NULL,
    SealNumber VARCHAR(60) NULL,
    StorageLocation NVARCHAR(250) NULL,
    EvidenceStatus NVARCHAR(40) NOT NULL CONSTRAINT DF_EvidenceItems_EvidenceStatus DEFAULT 'In Storage',
    IsDigitalEvidence BIT NOT NULL CONSTRAINT DF_EvidenceItems_IsDigitalEvidence DEFAULT 0,
    DigitalFileHashSHA256 CHAR(64) NULL,
    SecureFileReference NVARCHAR(300) NULL,
    CONSTRAINT UQ_Evidence_Case_Exhibit UNIQUE(CriminalCaseID, ExhibitNumber),
    CONSTRAINT CK_Evidence_Status CHECK(EvidenceStatus IN ('Collected','In Storage','Sent for Forensics','Returned from Forensics','Presented in Court','Released','Disposed','Missing','Under Review')),
    CONSTRAINT CK_Evidence_Hash CHECK(DigitalFileHashSHA256 IS NULL OR (LEN(DigitalFileHashSHA256)=64 AND DigitalFileHashSHA256 NOT LIKE '%[^0-9A-Fa-f]%'))
);

CREATE TABLE dbo.EvidenceCustodyTransfers
(
    EvidenceCustodyTransferID INT IDENTITY(1,1) CONSTRAINT PK_EvidenceCustodyTransfers PRIMARY KEY,
    EvidenceItemID INT NOT NULL CONSTRAINT FK_EvidenceCustodyTransfers_EvidenceItemID REFERENCES dbo.EvidenceItems(EvidenceItemID),
    TransferredAt DATETIME2 NOT NULL,
    TransferredByOfficerID INT NULL CONSTRAINT FK_EvidenceCustodyTransfers_TransferredByOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    ReceivedByOfficerID INT NULL CONSTRAINT FK_EvidenceCustodyTransfers_ReceivedByOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    FromLocation NVARCHAR(250) NULL,
    ToLocation NVARCHAR(250) NOT NULL,
    TransferPurpose NVARCHAR(300) NOT NULL,
    SealCondition NVARCHAR(100) NULL,
    DigitalHashAtTransfer CHAR(64) NULL,
    TransferReceiptReference VARCHAR(80) NULL,
    CONSTRAINT CK_EvidenceTransfer_Hash CHECK(DigitalHashAtTransfer IS NULL OR (LEN(DigitalHashAtTransfer)=64 AND DigitalHashAtTransfer NOT LIKE '%[^0-9A-Fa-f]%'))
);

CREATE TABLE dbo.ForensicLaboratories
(
    ForensicLaboratoryID INT IDENTITY(1,1) CONSTRAINT PK_ForensicLaboratories PRIMARY KEY,
    LaboratoryName NVARCHAR(180) NOT NULL CONSTRAINT UQ_ForensicLaboratories_LaboratoryName UNIQUE,
    LaboratoryType NVARCHAR(80) NOT NULL,
    LaboratoryAddress NVARCHAR(300) NULL,
    ContactEmail VARCHAR(254) NULL,
    ContactPhone VARCHAR(20) NULL
);

CREATE TABLE dbo.ForensicRequests
(
    ForensicRequestID INT IDENTITY(1,1) CONSTRAINT PK_ForensicRequests PRIMARY KEY,
    EvidenceItemID INT NOT NULL CONSTRAINT FK_ForensicRequests_EvidenceItemID REFERENCES dbo.EvidenceItems(EvidenceItemID),
    ForensicLaboratoryID INT NOT NULL CONSTRAINT FK_ForensicRequests_ForensicLaboratoryID REFERENCES dbo.ForensicLaboratories(ForensicLaboratoryID),
    RequestedByOfficerID INT NOT NULL CONSTRAINT FK_ForensicRequests_RequestedByOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    RequestedAt DATETIME2 NOT NULL,
    ExaminationType NVARCHAR(100) NOT NULL,
    ExaminationQuestions NVARCHAR(1000) NULL,
    RequestStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_ForensicRequests_RequestStatus DEFAULT 'Submitted',
    CompletedAt DATETIME2 NULL,
    CONSTRAINT CK_ForensicRequest_Status CHECK(RequestStatus IN ('Draft','Submitted','Accepted','In Progress','Completed','Returned','Cancelled'))
);

CREATE TABLE dbo.ForensicReports
(
    ForensicReportID INT IDENTITY(1,1) CONSTRAINT PK_ForensicReports PRIMARY KEY,
    ForensicRequestID INT NOT NULL CONSTRAINT FK_ForensicReports_ForensicRequestID REFERENCES dbo.ForensicRequests(ForensicRequestID),
    ReportNumber VARCHAR(60) NOT NULL CONSTRAINT UQ_ForensicReports_ReportNumber UNIQUE,
    ReportIssuedAt DATETIME2 NOT NULL,
    ExaminerName NVARCHAR(150) NOT NULL,
    MethodologySummary NVARCHAR(1000) NULL,
    FindingsSummary NVARCHAR(2000) NOT NULL,
    Limitations NVARCHAR(1000) NULL,
    SecureReportReference NVARCHAR(300) NULL,
    ReportStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_ForensicReports_ReportStatus DEFAULT 'Final',
    CONSTRAINT CK_ForensicReport_Status CHECK(ReportStatus IN ('Draft','Peer Review','Final','Amended','Withdrawn'))
);

-- ---- Property and missing persons ----

CREATE TABLE dbo.StolenProperties
(
    StolenPropertyID INT IDENTITY(1,1) CONSTRAINT PK_StolenProperties PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_StolenProperties_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    ReportedByPersonID INT NULL CONSTRAINT FK_StolenProperties_ReportedByPersonID REFERENCES dbo.Persons(PersonID),
    PropertyDescription NVARCHAR(300) NOT NULL,
    PropertyCategory NVARCHAR(80) NOT NULL,
    BrandOrMake NVARCHAR(100) NULL,
    ModelOrVariant NVARCHAR(100) NULL,
    SerialOrRegistrationNumber NVARCHAR(100) NULL,
    EstimatedValueINR DECIMAL(14,2) NULL,
    DateLostOrStolen DATETIME2 NULL,
    PropertyStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_StolenProperties_PropertyStatus DEFAULT 'Not Recovered',
    CONSTRAINT CK_StolenProperty_Value CHECK(EstimatedValueINR IS NULL OR EstimatedValueINR >= 0),
    CONSTRAINT CK_StolenProperty_Status CHECK(PropertyStatus IN ('Not Recovered','Partially Recovered','Recovered','Returned To Owner','Disposed'))
);

CREATE TABLE dbo.PropertyRecoveries
(
    PropertyRecoveryID INT IDENTITY(1,1) CONSTRAINT PK_PropertyRecoveries PRIMARY KEY,
    StolenPropertyID INT NOT NULL CONSTRAINT FK_PropertyRecoveries_StolenPropertyID REFERENCES dbo.StolenProperties(StolenPropertyID),
    RecoveredAt DATETIME2 NOT NULL,
    RecoveryLocation NVARCHAR(300) NOT NULL,
    RecoveredByOfficerID INT NOT NULL CONSTRAINT FK_PropertyRecoveries_RecoveredByOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    RecoveryDescription NVARCHAR(1000) NULL,
    ReturnedToOwnerAt DATETIME2 NULL,
    HandoverReceiptReference VARCHAR(80) NULL
);

CREATE TABLE dbo.MissingPersonReports
(
    MissingPersonReportID INT IDENTITY(1,1) CONSTRAINT PK_MissingPersonReports PRIMARY KEY,
    MissingPersonID INT NOT NULL CONSTRAINT FK_MissingPersonReports_MissingPersonID REFERENCES dbo.Persons(PersonID),
    ReportedByPersonID INT NULL CONSTRAINT FK_MissingPersonReports_ReportedByPersonID REFERENCES dbo.Persons(PersonID),
    PoliceStationID INT NOT NULL CONSTRAINT FK_MissingPersonReports_PoliceStationID REFERENCES dbo.PoliceStations(PoliceStationID),
    RelatedCaseID INT NULL CONSTRAINT FK_MissingPersonReports_RelatedCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    ReportedAt DATETIME2 NOT NULL,
    LastSeenAt DATETIME2 NULL,
    LastSeenLocation NVARCHAR(300) NOT NULL,
    ClothingAndAppearance NVARCHAR(1000) NULL,
    MissingPersonStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_MissingPersonReports_MissingPersonStatus DEFAULT 'Missing',
    FoundAt DATETIME2 NULL,
    CONSTRAINT CK_MissingPerson_Status CHECK(MissingPersonStatus IN ('Missing','Located','Closed','Under Review'))
);

-- ---- Prosecution and courts ----

CREATE TABLE dbo.ChargeSheets
(
    ChargeSheetID INT IDENTITY(1,1) CONSTRAINT PK_ChargeSheets PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_ChargeSheets_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    ChargeSheetNumber VARCHAR(50) NOT NULL CONSTRAINT UQ_ChargeSheets_ChargeSheetNumber UNIQUE,
    PreparedByOfficerID INT NOT NULL CONSTRAINT FK_ChargeSheets_PreparedByOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    PreparedAt DATETIME2 NOT NULL,
    FiledAt DATETIME2 NULL,
    FilingCourtName NVARCHAR(180) NULL,
    ChargeSheetType NVARCHAR(30) NOT NULL CONSTRAINT DF_ChargeSheets_ChargeSheetType DEFAULT 'Final',
    SummaryOfFindings NVARCHAR(2000) NULL,
    DocumentReference NVARCHAR(300) NULL,
    CONSTRAINT CK_ChargeSheet_Type CHECK(ChargeSheetType IN ('Final','Supplementary','Interim'))
);

CREATE TABLE dbo.ProsecutionTeams
(
    ProsecutionTeamID INT IDENTITY(1,1) CONSTRAINT PK_ProsecutionTeams PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_ProsecutionTeams_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    ProsecutorName NVARCHAR(150) NOT NULL,
    ProsecutorRole NVARCHAR(80) NOT NULL,
    OfficeName NVARCHAR(180) NULL,
    ContactEmail VARCHAR(254) NULL,
    AssignedAt DATE NOT NULL,
    ReleasedAt DATE NULL,
    CONSTRAINT CK_ProsecutionTeam_Dates CHECK(ReleasedAt IS NULL OR ReleasedAt >= AssignedAt)
);

CREATE TABLE dbo.CourtCases
(
    CourtCaseID INT IDENTITY(1,1) CONSTRAINT PK_CourtCases PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_CourtCases_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    CourtName NVARCHAR(180) NOT NULL,
    CourtCaseNumber VARCHAR(60) NOT NULL,
    CourtType NVARCHAR(80) NULL,
    PresidingJudgeName NVARCHAR(150) NULL,
    CaseFiledAt DATE NULL,
    CourtCaseStatus NVARCHAR(40) NOT NULL CONSTRAINT DF_CourtCases_CourtCaseStatus DEFAULT 'Pending',
    CONSTRAINT UQ_CourtCase UNIQUE(CourtName, CourtCaseNumber),
    CONSTRAINT CK_CourtCase_Status CHECK(CourtCaseStatus IN ('Pending','Under Trial','Stayed','Disposed','Appeal Filed','Transferred'))
);

CREATE TABLE dbo.CourtHearings
(
    CourtHearingID INT IDENTITY(1,1) CONSTRAINT PK_CourtHearings PRIMARY KEY,
    CourtCaseID INT NOT NULL CONSTRAINT FK_CourtHearings_CourtCaseID REFERENCES dbo.CourtCases(CourtCaseID),
    HearingDateTime DATETIME2 NOT NULL,
    HearingPurpose NVARCHAR(250) NULL,
    HearingOutcome NVARCHAR(1000) NULL,
    NextHearingDateTime DATETIME2 NULL,
    PresidingJudgeName NVARCHAR(150) NULL,
    CONSTRAINT CK_CourtHearing_NextDate CHECK(NextHearingDateTime IS NULL OR NextHearingDateTime >= HearingDateTime)
);

CREATE TABLE dbo.CourtOrders
(
    CourtOrderID INT IDENTITY(1,1) CONSTRAINT PK_CourtOrders PRIMARY KEY,
    CourtCaseID INT NOT NULL CONSTRAINT FK_CourtOrders_CourtCaseID REFERENCES dbo.CourtCases(CourtCaseID),
    CourtHearingID INT NULL CONSTRAINT FK_CourtOrders_CourtHearingID REFERENCES dbo.CourtHearings(CourtHearingID),
    OrderReference VARCHAR(60) NOT NULL CONSTRAINT UQ_CourtOrders_OrderReference UNIQUE,
    OrderDate DATE NOT NULL,
    OrderType NVARCHAR(80) NOT NULL,
    OrderSummary NVARCHAR(1500) NOT NULL,
    SecureDocumentReference NVARCHAR(300) NULL
);

CREATE TABLE dbo.BailOrders
(
    BailOrderID INT IDENTITY(1,1) CONSTRAINT PK_BailOrders PRIMARY KEY,
    ArrestID INT NOT NULL CONSTRAINT FK_BailOrders_ArrestID REFERENCES dbo.Arrests(ArrestID),
    CourtCaseID INT NULL CONSTRAINT FK_BailOrders_CourtCaseID REFERENCES dbo.CourtCases(CourtCaseID),
    OrderReference VARCHAR(60) NOT NULL CONSTRAINT UQ_BailOrders_OrderReference UNIQUE,
    DecisionDate DATE NOT NULL,
    BailDecision NVARCHAR(20) NOT NULL,
    BailConditions NVARCHAR(1500) NULL,
    BondAmountINR DECIMAL(14,2) NULL,
    ReleaseEffectiveAt DATETIME2 NULL,
    CONSTRAINT CK_Bail_Decision CHECK(BailDecision IN ('Granted','Rejected','Cancelled','Modified')),
    CONSTRAINT CK_Bail_Amount CHECK(BondAmountINR IS NULL OR BondAmountINR >= 0)
);

CREATE TABLE dbo.CaseOutcomes
(
    CaseOutcomeID INT IDENTITY(1,1) CONSTRAINT PK_CaseOutcomes PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_CaseOutcomes_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    CourtCaseID INT NULL CONSTRAINT FK_CaseOutcomes_CourtCaseID REFERENCES dbo.CourtCases(CourtCaseID),
    OutcomeDate DATE NOT NULL,
    OutcomeType NVARCHAR(60) NOT NULL,
    OutcomeSummary NVARCHAR(1500) NOT NULL,
    AppealFiled BIT NOT NULL CONSTRAINT DF_CaseOutcomes_AppealFiled DEFAULT 0,
    AppealFiledDate DATE NULL,
    CONSTRAINT CK_CaseOutcome_Type CHECK(OutcomeType IN ('Conviction','Acquittal','Discharged','Compounded','Withdrawn','Untraced','Closure Report Accepted','Other')),
    CONSTRAINT CK_CaseOutcome_Appeal CHECK(AppealFiled = 1 OR AppealFiledDate IS NULL)
);

-- ---- Victim support, users and audit ----

CREATE TABLE dbo.VictimSupportServices
(
    VictimSupportServiceID INT IDENTITY(1,1) CONSTRAINT PK_VictimSupportServices PRIMARY KEY,
    CriminalCaseID INT NOT NULL CONSTRAINT FK_VictimSupportServices_CriminalCaseID REFERENCES dbo.CriminalCases(CriminalCaseID),
    VictimPersonID INT NOT NULL CONSTRAINT FK_VictimSupportServices_VictimPersonID REFERENCES dbo.Persons(PersonID),
    ServiceType NVARCHAR(100) NOT NULL,
    ReferredByOfficerID INT NULL CONSTRAINT FK_VictimSupportServices_ReferredByOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    ReferralDate DATE NOT NULL,
    ServiceProviderName NVARCHAR(180) NULL,
    ServiceStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_VictimSupportServices_ServiceStatus DEFAULT 'Referred',
    FollowUpDate DATE NULL,
    ServiceNotes NVARCHAR(1000) NULL,
    CONSTRAINT CK_VictimSupport_Status CHECK(ServiceStatus IN ('Referred','Accepted','In Progress','Completed','Declined','Unable To Contact'))
);

CREATE TABLE dbo.SystemUsers
(
    SystemUserID INT IDENTITY(1,1) CONSTRAINT PK_SystemUsers PRIMARY KEY,
    PoliceOfficerID INT NULL CONSTRAINT FK_SystemUsers_PoliceOfficerID REFERENCES dbo.PoliceOfficers(PoliceOfficerID),
    Username NVARCHAR(80) NOT NULL CONSTRAINT UQ_SystemUsers_Username UNIQUE,
    PasswordHash VARBINARY(256) NOT NULL,
    IsEnabled BIT NOT NULL CONSTRAINT DF_SystemUsers_IsEnabled DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_SystemUsers_CreatedAt DEFAULT SYSUTCDATETIME(),
    LastLoginAt DATETIME2 NULL
);

CREATE TABLE dbo.SystemRoles
(
    SystemRoleID INT IDENTITY(1,1) CONSTRAINT PK_SystemRoles PRIMARY KEY,
    RoleName NVARCHAR(60) NOT NULL CONSTRAINT UQ_SystemRoles_RoleName UNIQUE,
    RoleDescription NVARCHAR(300) NULL
);

CREATE TABLE dbo.SystemUserRoles
(
    SystemUserRoleID INT IDENTITY(1,1) CONSTRAINT PK_SystemUserRoles PRIMARY KEY,
    SystemUserID INT NOT NULL CONSTRAINT FK_SystemUserRoles_SystemUserID REFERENCES dbo.SystemUsers(SystemUserID),
    SystemRoleID INT NOT NULL CONSTRAINT FK_SystemUserRoles_SystemRoleID REFERENCES dbo.SystemRoles(SystemRoleID),
    GrantedAt DATETIME2 NOT NULL CONSTRAINT DF_SystemUserRoles_GrantedAt DEFAULT SYSUTCDATETIME(),
    GrantedByUserID INT NULL CONSTRAINT FK_SystemUserRoles_GrantedByUserID REFERENCES dbo.SystemUsers(SystemUserID),
    CONSTRAINT UQ_SystemUser_Role UNIQUE(SystemUserID, SystemRoleID)
);

CREATE TABLE dbo.AuditLog
(
    AuditLogID BIGINT IDENTITY(1,1) CONSTRAINT PK_AuditLog PRIMARY KEY,
    SystemUserID INT NULL CONSTRAINT FK_AuditLog_SystemUserID REFERENCES dbo.SystemUsers(SystemUserID),
    EventAt DATETIME2 NOT NULL CONSTRAINT DF_AuditLog_EventAt DEFAULT SYSUTCDATETIME(),
    EntityName SYSNAME NOT NULL,
    EntityRecordID NVARCHAR(100) NULL,
    ActionType NVARCHAR(30) NOT NULL,
    ActionSummary NVARCHAR(1000) NULL,
    ClientAddress NVARCHAR(80) NULL,
    CONSTRAINT CK_AuditLog_Action CHECK(ActionType IN ('INSERT','UPDATE','DELETE','VIEW','LOGIN','LOGOUT','EXPORT','OTHER'))
);


GO

-- =====================================================================
-- STEP 2: INDEXES
-- =====================================================================
-- FIR numbers must be unique per station, but a case may exist without one yet.
-- A filtered unique index allows many NULLs, which a plain UNIQUE constraint would not.
CREATE UNIQUE INDEX UX_CriminalCases_Station_FIR ON dbo.CriminalCases (PoliceStationID, FIRNumber) WHERE FIRNumber IS NOT NULL;

CREATE INDEX IX_PoliceStations_District         ON dbo.PoliceStations (DistrictID);
CREATE INDEX IX_PoliceOfficers_Rank             ON dbo.PoliceOfficers (PoliceRankID);
CREATE INDEX IX_OfficerAssignments_Officer      ON dbo.OfficerAssignments (PoliceOfficerID, PoliceStationID);
CREATE INDEX IX_Complaints_Station_Status       ON dbo.Complaints (PoliceStationID, ComplaintStatus);
CREATE INDEX IX_Complaints_ReceivedAt           ON dbo.Complaints (ReceivedAt);
CREATE INDEX IX_CriminalCases_Station           ON dbo.CriminalCases (PoliceStationID);
CREATE INDEX IX_CriminalCases_Status_OpenedAt   ON dbo.CriminalCases (CaseStatus, OpenedAt);
CREATE INDEX IX_CriminalCases_Complaint         ON dbo.CriminalCases (ComplaintID);
CREATE INDEX IX_CaseOffences_Category           ON dbo.CaseOffences (CrimeCategoryID);
CREATE INDEX IX_CasePersonRoles_Person          ON dbo.CasePersonRoles (PersonID);
CREATE INDEX IX_InvestigationAssignments_Officer ON dbo.InvestigationAssignments (PoliceOfficerID);
CREATE INDEX IX_EvidenceItems_Case              ON dbo.EvidenceItems (CriminalCaseID);
CREATE INDEX IX_EvidenceItems_Type              ON dbo.EvidenceItems (EvidenceTypeID);
CREATE INDEX IX_CustodyTransfers_Item           ON dbo.EvidenceCustodyTransfers (EvidenceItemID, TransferredAt);
CREATE INDEX IX_ForensicRequests_Item           ON dbo.ForensicRequests (EvidenceItemID);
CREATE INDEX IX_ForensicRequests_Lab            ON dbo.ForensicRequests (ForensicLaboratoryID);
CREATE INDEX IX_Arrests_Case                    ON dbo.Arrests (CriminalCaseID);
CREATE INDEX IX_CustodyRecords_Arrest           ON dbo.CustodyRecords (ArrestID);
CREATE INDEX IX_CourtCases_Case                 ON dbo.CourtCases (CriminalCaseID);
CREATE INDEX IX_CourtHearings_CourtCase         ON dbo.CourtHearings (CourtCaseID, HearingDateTime);
CREATE INDEX IX_BailOrders_Arrest               ON dbo.BailOrders (ArrestID);
CREATE INDEX IX_AuditLog_User_EventAt           ON dbo.AuditLog (SystemUserID, EventAt);
GO


-- =====================================================================
-- STEP 4: REFERENCE (LOOKUP) DATA
-- =====================================================================

INSERT INTO dbo.States (StateName, StateCode)
VALUES (N'Telangana',      'TS'),
       (N'Andhra Pradesh', 'AP'),
       (N'Karnataka',      'KA');

INSERT INTO dbo.Districts (StateID, DistrictName, DistrictCode)
SELECT s.StateID, v.DistrictName, v.DistrictCode
FROM (VALUES ('TS', N'Hyderabad',       'TS-HYD'),
             ('TS', N'Rangareddy',      'TS-RRD'),
             ('AP', N'Tirupati',        'AP-TPT'),
             ('KA', N'Bengaluru Urban', 'KA-BLR')) AS v (StateCode, DistrictName, DistrictCode)
JOIN dbo.States AS s ON s.StateCode = v.StateCode;

INSERT INTO dbo.PoliceStations (DistrictID, PoliceStationName, StationCode, StationAddress, ContactPhone, EmailAddress, IsActive)
SELECT d.DistrictID, v.StationName, v.StationCode, v.StationAddress, v.ContactPhone, v.EmailAddress, v.IsActive
FROM (VALUES
    ('TS-HYD', N'Banjara Hills Police Station',  'TS-HYD-BH', N'Road No. 12, Banjara Hills, Hyderabad, Telangana', '040-00000001',  'banjarahills.ps@example.test', 1),
    ('TS-HYD', N'Charminar Police Station',      'TS-HYD-CH', N'Near Charminar, Old City, Hyderabad, Telangana',   '040-00000002',  'charminar.ps@example.test',    1),
    ('TS-HYD', N'Old City Outpost (Closed)',     'TS-HYD-OC', N'Old City, Hyderabad, Telangana',                   NULL,            NULL,                           0),
    ('TS-RRD', N'Gachibowli Police Station',     'TS-RRD-GC', N'Financial District Road, Gachibowli, Rangareddy, Telangana', '040-00000003', 'gachibowli.ps@example.test', 1),
    ('AP-TPT', N'Tirupati East Police Station',  'AP-TPT-TE', N'Near Bus Stand, Tirupati, Andhra Pradesh',         '0877-0000001',  'tirupatieast.ps@example.test', 1)
) AS v (DistrictCode, StationName, StationCode, StationAddress, ContactPhone, EmailAddress, IsActive)
JOIN dbo.Districts AS d ON d.DistrictCode = v.DistrictCode;

INSERT INTO dbo.PoliceUnits (PoliceStationID, UnitName, UnitType, UnitDescription)
SELECT ps.PoliceStationID, v.UnitName, v.UnitType, v.UnitDescription
FROM (VALUES
    ('TS-HYD-BH', N'Investigation Team',  N'Investigation',    N'General crime investigation team'),
    ('TS-HYD-BH', N'Cyber Crime Cell',    N'Cyber',            N'Handles digital and online offences'),
    ('TS-HYD-CH', N'Investigation Team',  N'Investigation',    N'General crime investigation team'),
    ('TS-RRD-GC', N'Investigation Team',  N'Investigation',    N'General crime investigation team'),
    ('TS-RRD-GC', N'Crime Scene Unit',    N'Forensic Support', N'Scene examination and evidence collection support'),
    ('AP-TPT-TE', N'Investigation Team',  N'Investigation',    N'General crime investigation team')
) AS v (StationCode, UnitName, UnitType, UnitDescription)
JOIN dbo.PoliceStations AS ps ON ps.StationCode = v.StationCode;

INSERT INTO dbo.PoliceRanks (RankName, RankLevel)
VALUES (N'Constable', 1),
       (N'Head Constable', 2),
       (N'Assistant Sub-Inspector', 3),
       (N'Sub-Inspector', 4),
       (N'Inspector', 5),
       (N'Deputy Superintendent of Police', 6),
       (N'Assistant Commissioner of Police', 7),
       (N'Deputy Commissioner of Police', 8),
       (N'Superintendent of Police', 9);

INSERT INTO dbo.ComplaintSources (SourceName, SourceDescription)
VALUES (N'Police Station Visit', N'Complaint submitted in person at a police station'),
       (N'Online Portal',        N'Complaint submitted through an official online service'),
       (N'Helpline',             N'Information received through a designated helpline'),
       (N'Written Referral',     N'Complaint referred by another authorized office'),
       (N'Patrol Observation',   N'Incident observed and reported by police personnel');

INSERT INTO dbo.CrimeCategories (CategoryName, CategoryDescription)
VALUES (N'Theft',                    N'Unlawful taking of property; exact legal classification depends on facts and applicable law'),
       (N'Robbery',                  N'Theft or attempted theft involving the legally relevant aggravating circumstances'),
       (N'Burglary / House-Breaking',N'Unlawful entry or house-breaking associated with an alleged offence'),
       (N'Assault',                  N'Alleged physical attack or use of force'),
       (N'Fraud',                    N'Alleged deception or dishonest inducement'),
       (N'Cybercrime',               N'Crime involving computers, communication devices, networks or digital services'),
       (N'Missing Person',           N'Report concerning a person whose whereabouts are unknown'),
       (N'Murder / Homicide',        N'An alleged unlawful killing; classification depends on investigation and law'),
       (N'Domestic Violence',        N'Report of alleged violence or abuse within a domestic relationship'),
       (N'Drug-Related Offence',     N'An alleged offence involving controlled or prohibited substances'),
       (N'Property Damage',          N'Alleged intentional or unlawful damage to property'),
       (N'Sexual Offence',           N'An alleged sexual offence; records must be restricted and handled sensitively');

-- Placeholder legal entries only. Provision numbers are deliberately NOT real section numbers.
INSERT INTO dbo.LegalProvisions
    (LegislationName, LegislationShortCode, ProvisionNumber, ProvisionTitle, ProvisionSummary, EffectiveFrom, EffectiveTo, IsCurrent)
VALUES (N'Bharatiya Nyaya Sanhita, 2023',      N'BNS',    N'REVIEW-REQUIRED-01', N'Illustrative offence provision',
        N'Coursework placeholder. Replace with a verified provision before any real use.', '2024-07-01', NULL,         1),
       (N'Information Technology Act, 2000',   N'IT-ACT', N'REVIEW-REQUIRED-02', N'Illustrative digital offence provision',
        N'Coursework placeholder. Replace with a verified provision before any real use.', '2000-10-17', NULL,         1),
       (N'Indian Penal Code, 1860 (replaced)', N'IPC',    N'REVIEW-REQUIRED-03', N'Illustrative historical provision',
        N'Coursework placeholder for a repealed enactment, kept to show validity dates.',  '1860-10-06', '2024-06-30', 0);

INSERT INTO dbo.EvidenceTypes (EvidenceTypeName, EvidenceTypeDescription)
VALUES (N'CCTV Footage',             N'Video captured by a surveillance system'),
       (N'Photograph',               N'Photographic record of a scene, person, object or injury'),
       (N'Fingerprint',              N'Latent or recorded fingerprint material'),
       (N'DNA Sample',               N'Biological sample requiring controlled collection and handling'),
       (N'Document',                 N'Paper or scanned document potentially relevant to the case'),
       (N'Mobile Phone',             N'Mobile device collected for authorized examination'),
       (N'Computer / Storage Device',N'Computer, drive, memory card or other storage medium'),
       (N'Weapon',                   N'Object suspected to have been used in an offence'),
       (N'Clothing',                 N'Clothing collected as potential physical evidence'),
       (N'Financial Record',         N'Banking, transaction or account-related record'),
       (N'Recovered Property',       N'Property recovered during an investigation'),
       (N'Other Physical Evidence',  N'Other physical item collected and documented');

INSERT INTO dbo.ForensicLaboratories (LaboratoryName, LaboratoryType, LaboratoryAddress, ContactEmail, ContactPhone)
VALUES (N'Telangana Regional Forensic Unit (Demo)', N'Regional Forensic Laboratory', N'Training address, Hyderabad, Telangana', 'regional.lab@example.test',  '040-22220001'),
       (N'Digital Evidence Examination Unit (Demo)',N'Digital Forensics',            N'Training address, Hyderabad, Telangana', 'digital.lab@example.test',   '040-22220002'),
       (N'Cyber Forensic Support Cell (Demo)',      N'Digital Forensics',            N'Training address, Secunderabad, Telangana', NULL,                      NULL);

INSERT INTO dbo.SystemRoles (RoleName, RoleDescription)
VALUES (N'Administrator',         N'Manages accounts, roles and approved system configuration'),
       (N'Station Officer',       N'Oversees station-level records and case allocation'),
       (N'Investigating Officer', N'Updates assigned case investigation records'),
       (N'Forensic Examiner',     N'Accesses assigned forensic requests and records reports'),
       (N'Prosecutor',            N'Accesses permitted prosecution and court case information'),
       (N'Read Only Auditor',     N'Reviews authorized records and audit history without editing');
GO

-- =====================================================================
-- STEP 5: VIEW
-- =====================================================================
CREATE VIEW dbo.vw_CaseRegisterSummary AS
SELECT cc.CriminalCaseID,
       cc.CaseNumber,
       cc.FIRNumber,
       cc.CaseTitle,
       cc.CaseStatus,
       cc.CasePriority,
       cc.OpenedAt,
       cc.ClosedAt,
       ps.PoliceStationName,
       d.DistrictName,
       s.StateName
FROM dbo.CriminalCases AS cc
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = cc.PoliceStationID
JOIN dbo.Districts      AS d  ON d.DistrictID       = ps.DistrictID
JOIN dbo.States         AS s  ON s.StateID          = d.StateID;
GO

-- =====================================================================
-- STEP 6: SAMPLE DATA (all people, events and references are made up)
-- =====================================================================

-- ---------- Police officers and their postings ----------
INSERT INTO dbo.PoliceOfficers
    (ServiceNumber, FirstName, MiddleName, LastName, PoliceRankID, WorkPhone, WorkEmail, DateOfJoining, IsActive)
SELECT v.ServiceNumber, v.FirstName, v.MiddleName, v.LastName, r.PoliceRankID, v.WorkPhone, v.WorkEmail, v.DateOfJoining, v.IsActive
FROM (VALUES
    ('DEMO-1001', N'Arjun',   NULL,      N'Sharma',   N'Inspector',                       '040-11110001', 'arjun.sharma@example.test',   '2014-06-15', 1),
    ('DEMO-1002', N'Priya',   NULL,      N'Nair',     N'Sub-Inspector',                   '040-11110002', 'priya.nair@example.test',     '2017-08-21', 1),
    ('DEMO-1003', N'Karthik', NULL,      N'Reddy',    N'Sub-Inspector',                   '040-11110003', 'karthik.reddy@example.test',  '2018-02-10', 1),
    ('DEMO-1004', N'Meera',   NULL,      N'Kulkarni', N'Assistant Sub-Inspector',         '040-11110004', 'meera.kulkarni@example.test', '2019-11-04', 1),
    ('DEMO-1005', N'Vikram',  NULL,      N'Patel',    N'Inspector',                       '040-11110005', 'vikram.patel@example.test',   '2012-03-19', 1),
    ('DEMO-1006', N'Sana',    NULL,      N'Hashmi',   N'Head Constable',                  '040-11110006', 'sana.hashmi@example.test',    '2020-01-13', 1),
    ('DEMO-1007', N'Rohit',   NULL,      N'Varma',    N'Constable',                       '040-11110007', 'rohit.varma@example.test',    '2021-07-01', 1),
    ('DEMO-1008', N'Divya',   NULL,      N'Iyer',     N'Deputy Superintendent of Police', '040-11110008', 'divya.iyer@example.test',     '2010-09-09', 1),
    ('DEMO-1009', N'Naveen',  N'Kumar',  N'Chowdary', N'Inspector',                       '0877-1110009', 'naveen.chowdary@example.test','2013-05-27', 1),
    ('DEMO-1010', N'Lalitha', NULL,      N'Murthy',   N'Head Constable',                  NULL,           NULL,                          NULL,         0)
) AS v (ServiceNumber, FirstName, MiddleName, LastName, RankName, WorkPhone, WorkEmail, DateOfJoining, IsActive)
JOIN dbo.PoliceRanks AS r ON r.RankName = v.RankName;

INSERT INTO dbo.OfficerAssignments
    (PoliceOfficerID, PoliceStationID, PoliceUnitID, AssignmentStartDate, AssignmentEndDate, IsPrimaryAssignment)
SELECT o.PoliceOfficerID, ps.PoliceStationID, pu.PoliceUnitID, v.StartDate, v.EndDate, v.IsPrimary
FROM (VALUES
    ('DEMO-1001', 'TS-HYD-BH', N'Investigation Team', '2024-01-01', NULL,         1),
    ('DEMO-1002', 'TS-HYD-BH', N'Cyber Crime Cell',   '2024-01-01', NULL,         1),
    ('DEMO-1003', 'TS-HYD-CH', N'Investigation Team', '2024-01-01', NULL,         1),
    ('DEMO-1004', 'TS-RRD-GC', N'Investigation Team', '2024-01-01', NULL,         1),
    ('DEMO-1005', 'TS-RRD-GC', N'Investigation Team', '2024-01-01', NULL,         1),
    ('DEMO-1006', 'TS-HYD-BH', N'Investigation Team', '2024-01-01', NULL,         1),
    ('DEMO-1007', 'TS-HYD-CH', N'Investigation Team', '2024-01-01', NULL,         1),
    ('DEMO-1008', 'TS-RRD-GC', N'Crime Scene Unit',   '2024-01-01', NULL,         1),
    ('DEMO-1009', 'AP-TPT-TE', N'Investigation Team', '2024-01-01', NULL,         1),
    ('DEMO-1010', 'TS-HYD-CH', N'Investigation Team', '2024-01-01', '2025-06-30', 1),
    ('DEMO-1003', 'TS-HYD-BH', N'Investigation Team', '2020-01-01', '2023-12-31', 0),
    ('DEMO-1006', 'TS-HYD-CH', N'Investigation Team', '2020-06-01', '2023-12-31', 0)
) AS v (ServiceNumber, StationCode, UnitName, StartDate, EndDate, IsPrimary)
JOIN dbo.PoliceOfficers AS o  ON o.ServiceNumber = v.ServiceNumber
JOIN dbo.PoliceStations AS ps ON ps.StationCode  = v.StationCode
LEFT JOIN dbo.PoliceUnits AS pu ON pu.PoliceStationID = ps.PoliceStationID AND pu.UnitName = v.UnitName;

-- ---------- People ----------
INSERT INTO dbo.Persons (GivenName, MiddleName, FamilyName, DateOfBirth, Gender, PreferredLanguage, PersonNotes)
VALUES
(N'Ananya',  NULL,      N'Reddy',       '1998-04-12', N'Female', N'Telugu',    N'Complainant and victim in a phone-theft case'),
(N'Rahul',   N'Anand',  N'Verma',       '1993-09-08', N'Male',   N'Hindi',     N'Witness'),
(N'Suresh',  NULL,      N'Kumar',       '1988-01-22', N'Male',   N'Telugu',    N'Named as a suspect; this is an allegation only, not a finding'),
(N'Lakshmi', NULL,      N'Prasad',      '1981-06-17', N'Female', N'Telugu',    N'Complainant in an online payment fraud case'),
(N'Imran',   NULL,      N'Ahmed',       '1995-12-03', N'Male',   N'Urdu',      N'Witness'),
(N'Neha',    NULL,      N'Singh',       '2000-02-28', N'Female', N'Hindi',     N'Victim in an assault report'),
(N'Ravi',    NULL,      N'Kiran',       '1990-07-19', N'Male',   N'Telugu',    N'Named as a suspect; allegation only'),
(N'Pooja',   N'Lakshmi',N'Menon',       '1997-10-05', N'Female', N'Malayalam', N'Witness'),
(N'Farhan',  NULL,      N'Ali',         '1986-03-14', N'Male',   N'Urdu',      N'Complainant'),
(N'Kavya',   NULL,      N'Rao',         '1999-11-26', N'Female', N'Telugu',    N'Subject of a missing person report'),
(N'Mahesh',  NULL,      N'Naidu',       '1979-08-30', N'Male',   N'Telugu',    N'Next of kin of a missing person'),
(N'Swathi',  NULL,      N'Reddy',       '1992-05-11', N'Female', N'Telugu',    N'Complainant'),
(N'Ajay',    NULL,      N'Bose',        '1989-12-21', N'Male',   N'Bengali',   N'Witness'),
(N'Nisha',   NULL,      N'Patel',       '1996-06-02', N'Female', N'Hindi',     N'Victim in a property damage report'),
(N'Gopal',   NULL,      N'Krishna',     '1984-02-16', N'Male',   N'Telugu',    N'Named as a suspect and later accused; allegation only'),
(N'Keerthi', NULL,      N'Sharma',      '2001-01-09', N'Female', N'Hindi',     N'Witness'),
(N'Mohan',   NULL,      N'Das',         '1975-04-29', N'Male',   N'Odia',      N'Owner of the reported stolen motorcycle'),
(N'Zoya',    NULL,      N'Begum',       '1994-09-15', N'Female', N'Urdu',      N'Complainant in two separate reports'),
(N'Venkat',  NULL,      N'Rao',         '1987-07-07', N'Male',   N'Telugu',    N'Witness'),
(N'Sanjana', NULL,      N'Pillai',      '1998-03-25', N'Female', N'Tamil',     N'Victim in a 2025 case and complainant in a 2026 complaint'),
(N'Rekha',   NULL,      N'Joshi',       '1989-03-03', N'Female', N'Hindi',     N'Complainant; complaint still awaiting review'),
(N'Harish',  NULL,      N'Goud',        '1985-10-10', N'Male',   N'Telugu',    N'Named as a suspect and later accused; allegation only'),
(N'Sunitha', NULL,      N'Varma',       '1983-12-01', N'Female', N'Telugu',    N'Victim and complainant; restricted handling applies'),
(N'Dev',     NULL,      N'Malhotra',    NULL,         N'Male',   N'Hindi',     N'Date of birth not recorded; subject of a located-person report'),
(N'Latha',   NULL,      N'Subramaniam', '1991-08-18', N'Female', N'Tamil',     N'Complainant; matter referred elsewhere'),
(N'Irfan',   NULL,      N'Sheikh',      '1992-04-04', N'Male',   N'Urdu',      N'Informant'),
(N'Prakash', NULL,      N'Rathod',      '1980-05-05', N'Male',   N'Hindi',     N'Named as a suspect; allegation only'),
(N'Arvind',  NULL,      N'Hegde',       '1978-11-23', N'Male',   N'Kannada',   N'Named as a suspect; allegation only'),
(N'Bhaskar', NULL,      N'Raju',        '1982-09-09', N'Male',   N'Telugu',    N'Accused in a 2025 case that has gone to court');

INSERT INTO dbo.PersonAddresses
    (PersonID, AddressType, AddressLine1, Locality, CityOrTown, DistrictID, StateID, PostalCode, ValidFrom, ValidTo)
SELECT p.PersonID, v.AddressType, v.AddressLine1, v.Locality, v.CityOrTown, d.DistrictID, d.StateID, v.PostalCode, v.ValidFrom, v.ValidTo
FROM (VALUES
    (N'Ananya',  N'Reddy',   N'Residential',          N'Flat 12, Sunrise Residency',  N'Banjara Hills', N'Hyderabad',  'TS-HYD', '500034', '2023-01-01', NULL),
    (N'Ananya',  N'Reddy',   N'Previous Residential', N'4-5-67, Gandhi Road',         N'Kukatpally',    N'Hyderabad',  'TS-HYD', '500072', '2018-06-01', '2022-12-31'),
    (N'Rahul',   N'Verma',   N'Residential',          N'House 8, Lake View Colony',   N'Jubilee Hills', N'Hyderabad',  'TS-HYD', '500033', '2021-04-01', NULL),
    (N'Suresh',  N'Kumar',   N'Residential',          N'22, Market Street',           N'Begum Bazar',   N'Hyderabad',  'TS-HYD', '500012', '2019-01-01', NULL),
    (N'Lakshmi', N'Prasad',  N'Residential',          N'Flat 301, Green Heights',     N'Charminar',     N'Hyderabad',  'TS-HYD', '500002', '2020-07-01', NULL),
    (N'Imran',   N'Ahmed',   N'Residential',          N'15, Mir Alam Lane',           N'Charminar',     N'Hyderabad',  'TS-HYD', '500002', '2022-02-01', NULL),
    (N'Neha',    N'Singh',   N'Residential',          N'Flat 5B, Palm Court',         N'Shalibanda',    N'Hyderabad',  'TS-HYD', '500065', '2024-03-01', NULL),
    (N'Ravi',    N'Kiran',   N'Residential',          N'9, Temple Road',              N'Falaknuma',     N'Hyderabad',  'TS-HYD', '500053', '2017-05-01', NULL),
    (N'Pooja',   N'Menon',   N'Residential',          N'Flat 14, Orchid Apartments',  N'Gachibowli',    N'Hyderabad',  'TS-RRD', '500032', '2023-08-01', NULL),
    (N'Farhan',  N'Ali',     N'Residential',          N'Villa 3, Silver Oak Enclave', N'Gachibowli',    N'Hyderabad',  'TS-RRD', '500032', '2021-11-01', NULL),
    (N'Kavya',   N'Rao',     N'Residential',          N'12-3, Temple Street',         N'Tirupati Town', N'Tirupati',   'AP-TPT', '517501', '2022-01-01', NULL),
    (N'Mahesh',  N'Naidu',   N'Residential',          N'12-3, Temple Street',         N'Tirupati Town', N'Tirupati',   'AP-TPT', '517501', '2015-01-01', NULL),
    (N'Swathi',  N'Reddy',   N'Residential',          N'Flat 12, Sunrise Residency',  N'Banjara Hills', N'Hyderabad',  'TS-HYD', '500034', '2023-01-01', NULL),
    (N'Zoya',    N'Begum',   N'Residential',          N'7, Railway Colony',           N'Tirupati Town', N'Tirupati',   'AP-TPT', '517501', '2020-09-01', NULL),
    (N'Zoya',    N'Begum',   N'Work',                 N'Office 2, Trade Centre',      N'Charminar',     N'Hyderabad',  'TS-HYD', '500002', '2025-01-01', NULL),
    (N'Mohan',   N'Das',     N'Residential',          N'Plot 44, Industrial Layout',  N'Gachibowli',    N'Hyderabad',  'TS-RRD', '500032', '2016-02-01', NULL),
    (N'Gopal',   N'Krishna', N'Residential',          N'31, Canal Road',              N'Serilingampally',N'Hyderabad', 'TS-RRD', '500019', '2018-10-01', NULL),
    (N'Nisha',   N'Patel',   N'Residential',          N'Flat 2A, Hill View',          N'Banjara Hills', N'Hyderabad',  'TS-HYD', '500034', '2022-06-01', NULL),
    (N'Sunitha', N'Varma',   N'Residential',          N'Address withheld (sensitive)',N'Banjara Hills', N'Hyderabad',  'TS-HYD', '500034', '2024-01-01', NULL),
    (N'Harish',  N'Goud',    N'Residential',          N'18, Bazaar Lane',             N'Charminar',     N'Hyderabad',  'TS-HYD', '500002', '2019-05-01', NULL),
    (N'Sanjana', N'Pillai',  N'Residential',          N'Flat 9, Lotus Residency',     N'Gachibowli',    N'Hyderabad',  'TS-RRD', '500032', '2023-04-01', NULL)
) AS v (GivenName, FamilyName, AddressType, AddressLine1, Locality, CityOrTown, DistrictCode, PostalCode, ValidFrom, ValidTo)
JOIN dbo.Persons   AS p ON p.GivenName = v.GivenName AND p.FamilyName = v.FamilyName
JOIN dbo.Districts AS d ON d.DistrictCode = v.DistrictCode;

-- Everyone except Dev Malhotra has an email address on file
INSERT INTO dbo.PersonContactMethods (PersonID, ContactType, ContactValue, IsPreferred, IsVerified)
SELECT PersonID, N'Email', LOWER(GivenName + N'.' + FamilyName + N'@example.test'), 1,
       CASE WHEN PersonID % 3 = 0 THEN 1 ELSE 0 END
FROM dbo.Persons
WHERE GivenName <> N'Dev';

-- Phone numbers use the unassigned 00000 prefix so they can never ring a real person.
-- Ananya and Swathi live at the same address and share one household number on purpose.
INSERT INTO dbo.PersonContactMethods (PersonID, ContactType, ContactValue, IsPreferred, IsVerified)
SELECT p.PersonID, N'Phone', v.PhoneNumber, 0, v.IsVerified
FROM (VALUES
    (N'Ananya',  N'Reddy',   N'+91-00000-00101', 1),
    (N'Swathi',  N'Reddy',   N'+91-00000-00101', 0),
    (N'Rahul',   N'Verma',   N'+91-00000-00102', 1),
    (N'Lakshmi', N'Prasad',  N'+91-00000-00103', 1),
    (N'Farhan',  N'Ali',     N'+91-00000-00104', 0),
    (N'Neha',    N'Singh',   N'+91-00000-00105', 1),
    (N'Mahesh',  N'Naidu',   N'+91-00000-00106', 1),
    (N'Zoya',    N'Begum',   N'+91-00000-00107', 0),
    (N'Mohan',   N'Das',     N'+91-00000-00108', 1),
    (N'Sunitha', N'Varma',   N'+91-00000-00109', 0)
) AS v (GivenName, FamilyName, PhoneNumber, IsVerified)
JOIN dbo.Persons AS p ON p.GivenName = v.GivenName AND p.FamilyName = v.FamilyName;

INSERT INTO dbo.PersonIdentifiers (PersonID, IdentifierType, IdentifierValueEncryptedOrMasked, IssuingAuthority, VerificationStatus)
SELECT PersonID,
       N'Demo Reference',
       N'DEMO-' + RIGHT('0000' + CAST(PersonID AS VARCHAR(4)), 4),
       N'Project sample data',
       CASE WHEN PersonID IN (1, 2, 4, 6) THEN N'Verified'
            WHEN PersonID IN (3, 9)       THEN N'Pending'
            WHEN PersonID = 7             THEN N'Rejected'
            ELSE N'Unverified' END
FROM dbo.Persons
WHERE PersonID <= 12;

-- ---------- Complaints ----------
INSERT INTO dbo.Complaints
    (ComplaintNumber, PoliceStationID, SubmittedByPersonID, ComplaintSourceID, ReceivedAt, IncidentDateTime,
     IncidentLocation, ComplaintSummary, ComplaintDetails, UrgencyLevel, ComplaintStatus, AssignedOfficerID, IsAnonymous)
SELECT v.ComplaintNumber, ps.PoliceStationID, p.PersonID, src.ComplaintSourceID, v.ReceivedAt, v.IncidentDateTime,
       v.IncidentLocation, v.ComplaintSummary, v.ComplaintDetails, v.UrgencyLevel, v.ComplaintStatus, o.PoliceOfficerID, v.IsAnonymous
FROM (VALUES
 ('CMP-2026-0001','TS-HYD-BH',N'Ananya',N'Reddy',N'Police Station Visit','2026-01-12T10:30:00','2026-01-11T20:15:00',N'Banjara Hills, Hyderabad',
    N'Mobile phone reported stolen', N'Complainant says her phone was snatched near a shopping complex while she was walking home.', N'Normal', N'Registered as FIR','DEMO-1001',0),
 ('CMP-2026-0002','TS-HYD-CH',N'Lakshmi',N'Prasad',N'Online Portal','2026-02-03T14:20:00','2026-02-03T12:10:00',N'Charminar, Hyderabad',
    N'Online payment fraud reported', N'Complainant reports an unauthorised transfer after sharing a one-time code with a caller.', N'High', N'Registered as FIR','DEMO-1003',0),
 ('CMP-2026-0003','TS-RRD-GC',N'Farhan',N'Ali',N'Helpline','2026-02-17T09:05:00','2026-02-16T23:45:00',N'Gachibowli, Hyderabad',
    N'Attempted house break-in', N'Complainant found the rear door forced open on returning home and some items missing.', N'High', N'Registered as FIR','DEMO-1005',0),
 ('CMP-2026-0004','AP-TPT-TE',N'Zoya',N'Begum',N'Police Station Visit','2026-03-01T11:00:00','2026-02-28T18:00:00',N'Tirupati, Andhra Pradesh',
    N'Personal property reported missing', N'A handbag with personal items was left in an auto-rickshaw and not found afterwards.', N'Normal', N'Registered as FIR','DEMO-1009',0),
 ('CMP-2026-0005','TS-HYD-BH',N'Swathi',N'Reddy',N'Online Portal','2026-03-14T16:45:00','2026-03-14T15:30:00',N'Banjara Hills, Hyderabad',
    N'Suspicious account access', N'Complainant received login alerts for her email account from an unknown device.', N'Critical', N'Registered as FIR','DEMO-1002',0),
 ('CMP-2026-0006','TS-HYD-CH',N'Neha',N'Singh',N'Police Station Visit','2026-03-20T21:00:00','2026-03-20T19:00:00',N'Market road near Charminar, Hyderabad',
    N'Assault reported outside a market', N'Complainant alleges she was pushed and hit during an argument outside a market stall.', N'High', N'Registered as FIR','DEMO-1003',0),
 ('CMP-2026-0007','TS-RRD-GC',N'Mohan',N'Das',N'Helpline','2026-04-01T22:30:00','2026-04-01T21:00:00',N'Gachibowli, Hyderabad',
    N'Motorcycle reported stolen', N'Owner reports his motorcycle missing from a parking area where it was left locked.', N'High', N'Registered as FIR','DEMO-1005',0),
 ('CMP-2026-0008','AP-TPT-TE',N'Mahesh',N'Naidu',N'Police Station Visit','2026-04-09T20:00:00','2026-04-09T18:00:00',N'Tirupati bus station area',
    N'Family member reported missing', N'Complainant reports that his relative left home in the morning and has not returned or answered calls.', N'Critical', N'Registered as FIR','DEMO-1009',0),
 ('CMP-2026-0009','TS-HYD-BH',NULL,NULL,N'Patrol Observation','2026-04-17T22:45:00','2026-04-17T22:00:00',N'Banjara Hills, Hyderabad',
    N'Property damage seen by patrol', N'Patrol staff noticed damaged shutters and a broken signboard at a closed shop.', N'Low', N'Registered as FIR','DEMO-1002',0),
 ('CMP-2026-0010','TS-HYD-CH',N'Zoya',N'Begum',N'Online Portal','2026-04-29T12:00:00','2026-04-29T10:00:00',N'Charminar, Hyderabad',
    N'Financial fraud against a small business', N'Complainant says payments for a bulk order were collected and the goods were never delivered.', N'High', N'Registered as FIR','DEMO-1003',0),
 ('CMP-2026-0011','TS-HYD-BH',NULL,NULL,N'Online Portal','2026-05-06T08:15:00',NULL,N'Near a school gate, Banjara Hills',
    N'Anonymous tip about suspicious gathering', NULL, N'Normal', N'Under Review',NULL,1),
 ('CMP-2026-0012','TS-RRD-GC',N'Rekha',N'Joshi',N'Helpline','2026-05-20T13:10:00','2026-05-19T00:00:00',N'Gachibowli, Hyderabad',
    N'Repeated harassing phone calls', N'Complainant reports several late-night calls from numbers she does not recognise.', N'High', N'Received','DEMO-1004',0),
 ('CMP-2026-0013','TS-HYD-CH',N'Latha',N'Subramaniam',N'Written Referral','2026-06-02T10:00:00',NULL,N'Old City, Hyderabad',
    N'Property boundary dispute', N'Referred by another office; looks like a civil dispute and has been sent for civil remedy.', N'Low', N'Referred','DEMO-1003',0),
 ('CMP-2026-0014','TS-HYD-BH',N'Pooja',N'Menon',N'Police Station Visit','2026-06-18T15:30:00','2026-06-18T11:00:00',N'Banjara Hills, Hyderabad',
    N'Lost wallet', N'Wallet lost in a taxi; it was returned by the driver the next day, so the complaint was closed.', N'Low', N'Closed','DEMO-1006',0),
 ('CMP-2026-0015','AP-TPT-TE',N'Sanjana',N'Pillai',N'Online Portal','2026-07-04T09:40:00',NULL,N'Tirupati, Andhra Pradesh',
    N'Civil money-lending dispute', N'Complainant asks police to recover a private loan; not a police matter, so the complaint was declined.', N'Low', N'Declined','DEMO-1009',0),
 ('CMP-2026-0016','TS-HYD-BH',N'Sunitha',N'Varma',N'Helpline','2026-08-12T13:20:00','2026-08-11T22:00:00',N'Banjara Hills, Hyderabad',
    N'Domestic violence reported', N'Complaint received through the helpline; access to the file is restricted.', N'High', N'Registered as FIR','DEMO-1001',0)
) AS v (ComplaintNumber, StationCode, GivenName, FamilyName, SourceName, ReceivedAt, IncidentDateTime, IncidentLocation,
        ComplaintSummary, ComplaintDetails, UrgencyLevel, ComplaintStatus, OfficerService, IsAnonymous)
JOIN dbo.PoliceStations    AS ps  ON ps.StationCode  = v.StationCode
JOIN dbo.ComplaintSources  AS src ON src.SourceName  = v.SourceName
LEFT JOIN dbo.Persons          AS p ON p.GivenName = v.GivenName AND p.FamilyName = v.FamilyName
LEFT JOIN dbo.PoliceOfficers   AS o ON o.ServiceNumber = v.OfficerService;

-- Every complaint gets a first "Received" entry; anything that has moved on gets a second entry.
INSERT INTO dbo.ComplaintUpdates (ComplaintID, UpdatedAt, UpdatedByOfficerID, PreviousStatus, NewStatus, UpdateNotes)
SELECT ComplaintID, ReceivedAt, AssignedOfficerID, NULL, N'Received', N'Complaint logged at the station desk'
FROM dbo.Complaints;

INSERT INTO dbo.ComplaintUpdates (ComplaintID, UpdatedAt, UpdatedByOfficerID, PreviousStatus, NewStatus, UpdateNotes)
SELECT ComplaintID, DATEADD(hour, 2, ReceivedAt), AssignedOfficerID, N'Received', ComplaintStatus,
       N'Status changed after the first review of the complaint'
FROM dbo.Complaints
WHERE ComplaintStatus <> N'Received';

-- ---------- Criminal cases ----------
INSERT INTO dbo.CriminalCases
    (CaseNumber, PoliceStationID, FIRNumber, FIRRegisteredAt, ComplaintID, CaseTitle, IncidentStartAt, IncidentEndAt,
     IncidentLocation, CaseSummary, CaseStatus, CasePriority, OpenedAt, ClosedAt, IsSensitiveCase)
SELECT v.CaseNumber, ps.PoliceStationID, v.FIRNumber, v.FIRRegisteredAt, co.ComplaintID, v.CaseTitle, v.IncidentStartAt, v.IncidentEndAt,
       v.IncidentLocation, v.CaseSummary, v.CaseStatus, v.CasePriority, v.OpenedAt, v.ClosedAt, v.IsSensitiveCase
FROM (VALUES
 ('CICMS-2025-0001','TS-RRD-GC','FIR-GC-2025-014','2025-06-10T10:00:00',NULL,N'Warehouse stock theft',
    '2025-06-08T22:00:00','2025-06-09T05:00:00',N'Warehouse area, Gachibowli',
    N'Stock reported missing from a locked warehouse; legacy record migrated into the system.', N'Disposed', N'High','2025-06-10T10:00:00','2025-12-15T16:00:00',0),
 ('CICMS-2025-0002','TS-HYD-CH','FIR-CH-2025-031','2025-09-01T11:30:00',NULL,N'Cheque misuse complaint',
    '2025-08-28T10:00:00','2025-08-28T11:00:00',N'Charminar, Hyderabad',
    N'Complaint about a forged cheque presented at a bank; legacy record migrated into the system.', N'Closed', N'Medium','2025-09-01T11:30:00','2025-12-30T15:00:00',0),
 ('CICMS-2026-0001','TS-HYD-BH','FIR-BH-001','2026-01-12T11:15:00','CMP-2026-0001',N'Mobile phone theft near a commercial complex',
    '2026-01-11T20:00:00','2026-01-11T20:30:00',N'Banjara Hills, Hyderabad',
    N'Phone snatched from a pedestrian near a shopping complex; CCTV from nearby shops being reviewed.', N'Under Investigation', N'Medium','2026-01-12T11:15:00',NULL,0),
 ('CICMS-2026-0002','TS-HYD-CH','FIR-CH-002','2026-02-04T09:10:00','CMP-2026-0002',N'Online payment fraud complaint',
    '2026-02-03T11:30:00','2026-02-03T12:30:00',N'Charminar, Hyderabad',
    N'Unauthorised online transfer after a phishing-style call; bank records requested.', N'Under Investigation', N'High','2026-02-04T09:10:00',NULL,0),
 ('CICMS-2026-0003','TS-RRD-GC','FIR-GC-003','2026-02-17T10:20:00','CMP-2026-0003',N'House break-in at a residential villa',
    '2026-02-16T23:30:00','2026-02-17T00:00:00',N'Gachibowli, Hyderabad',
    N'Forced entry through a rear door with some household items missing.', N'Under Investigation', N'High','2026-02-17T10:20:00',NULL,0),
 ('CICMS-2026-0004','AP-TPT-TE','FIR-TE-004','2026-03-02T10:00:00','CMP-2026-0004',N'Missing personal property in Tirupati',
    '2026-02-28T17:30:00','2026-02-28T18:30:00',N'Tirupati, Andhra Pradesh',
    N'Handbag left in an auto-rickshaw; part of the contents later traced.', N'Registered', N'Low','2026-03-02T10:00:00',NULL,0),
 ('CICMS-2026-0005','TS-HYD-BH','FIR-BH-005','2026-03-15T09:30:00','CMP-2026-0005',N'Suspicious account access incident',
    '2026-03-14T15:00:00','2026-03-14T16:00:00',N'Banjara Hills, Hyderabad',
    N'Unauthorised access to an email account; device and account logs need examination.', N'Under Investigation', N'Critical','2026-03-15T09:30:00',NULL,0),
 ('CICMS-2026-0006','TS-HYD-CH','FIR-CH-006','2026-03-21T12:00:00','CMP-2026-0006',N'Reported assault outside a market',
    '2026-03-20T19:00:00','2026-03-20T19:30:00',N'Charminar, Hyderabad',
    N'Assault allegation after an argument at a market; an allegation is not a finding.', N'Registered', N'Medium','2026-03-21T12:00:00',NULL,0),
 ('CICMS-2026-0007','TS-RRD-GC','FIR-GC-007','2026-04-02T15:00:00','CMP-2026-0007',N'Reported motorcycle theft',
    '2026-04-01T21:00:00','2026-04-01T22:00:00',N'Gachibowli, Hyderabad',
    N'Motorcycle taken from a parking area; vehicle later recovered and charge sheet filed.', N'Charge Sheet Filed', N'High','2026-04-02T15:00:00',NULL,0),
 ('CICMS-2026-0008','AP-TPT-TE','FIR-TE-008','2026-04-10T10:30:00','CMP-2026-0008',N'Reported missing person',
    '2026-04-09T17:00:00','2026-04-09T19:00:00',N'Tirupati, Andhra Pradesh',
    N'Adult reported missing after leaving home; last seen near the bus station.', N'Under Investigation', N'High','2026-04-10T10:30:00',NULL,0),
 ('CICMS-2026-0009','TS-HYD-BH','FIR-BH-009','2026-04-18T09:00:00','CMP-2026-0009',N'Reported property damage at a shop',
    '2026-04-17T22:00:00','2026-04-17T22:30:00',N'Banjara Hills, Hyderabad',
    N'Shutters and signboard damaged; parties later settled the matter.', N'Closed', N'Low','2026-04-18T09:00:00','2026-05-30T16:00:00',0),
 ('CICMS-2026-0010','TS-HYD-CH','FIR-CH-010','2026-05-01T10:00:00','CMP-2026-0010',N'Financial fraud against a small business',
    '2026-04-29T10:00:00','2026-04-29T11:00:00',N'Charminar, Hyderabad',
    N'Advance payments taken for a bulk order that was never supplied; trial in progress.', N'Under Trial', N'High','2026-05-01T10:00:00',NULL,0),
 ('CICMS-2026-0011','TS-HYD-BH','FIR-BH-011','2026-08-12T15:00:00','CMP-2026-0016',N'Domestic violence complaint',
    '2026-08-11T22:00:00','2026-08-11T23:00:00',N'Banjara Hills, Hyderabad',
    N'Complaint received through the helpline. File access is restricted to assigned staff.', N'Under Investigation', N'High','2026-08-12T15:00:00',NULL,1),
 ('CICMS-2026-0012','TS-RRD-GC',NULL,NULL,NULL,N'Suspicious substance report (preliminary enquiry)',
    '2026-09-04T20:00:00','2026-09-04T21:00:00',N'Gachibowli, Hyderabad',
    N'Informant tip about suspicious packages; preliminary enquiry before any FIR is registered.', N'Registered', N'Medium','2026-09-05T09:00:00',NULL,0)
) AS v (CaseNumber, StationCode, FIRNumber, FIRRegisteredAt, ComplaintNumber, CaseTitle, IncidentStartAt, IncidentEndAt,
        IncidentLocation, CaseSummary, CaseStatus, CasePriority, OpenedAt, ClosedAt, IsSensitiveCase)
JOIN dbo.PoliceStations AS ps ON ps.StationCode = v.StationCode
LEFT JOIN dbo.Complaints AS co ON co.ComplaintNumber = v.ComplaintNumber;

INSERT INTO dbo.CaseOffences (CriminalCaseID, CrimeCategoryID, LegalProvisionID, OffenceDescription, IsPrimaryOffence)
SELECT c.CriminalCaseID, cat.CrimeCategoryID, lp.LegalProvisionID, v.OffenceDescription, v.IsPrimary
FROM (VALUES
    ('CICMS-2025-0001', N'Theft',                     'REVIEW-REQUIRED-03', N'Illustrative classification for academic practice', 1),
    ('CICMS-2025-0002', N'Fraud',                     'REVIEW-REQUIRED-03', N'Illustrative classification for academic practice', 1),
    ('CICMS-2026-0001', N'Theft',                     'REVIEW-REQUIRED-01', N'Illustrative classification for academic practice', 1),
    ('CICMS-2026-0002', N'Fraud',                     'REVIEW-REQUIRED-01', N'Illustrative classification for academic practice', 1),
    ('CICMS-2026-0002', N'Cybercrime',                'REVIEW-REQUIRED-02', N'Online element of the transfer',                    0),
    ('CICMS-2026-0003', N'Burglary / House-Breaking', 'REVIEW-REQUIRED-01', N'Illustrative classification for academic practice', 1),
    ('CICMS-2026-0003', N'Property Damage',           NULL,                 N'Damage to the rear door',                           0),
    ('CICMS-2026-0004', N'Theft',                     NULL,                 N'Illustrative classification for academic practice', 1),
    ('CICMS-2026-0005', N'Cybercrime',                'REVIEW-REQUIRED-02', N'Illustrative classification for academic practice', 1),
    ('CICMS-2026-0005', N'Fraud',                     NULL,                 N'Possible misuse of account access',                 0),
    ('CICMS-2026-0006', N'Assault',                   'REVIEW-REQUIRED-01', N'Illustrative classification for academic practice', 1),
    ('CICMS-2026-0007', N'Theft',                     'REVIEW-REQUIRED-01', N'Illustrative classification for academic practice', 1),
    ('CICMS-2026-0008', N'Missing Person',            NULL,                 N'Illustrative classification for academic practice', 1),
    ('CICMS-2026-0009', N'Property Damage',           NULL,                 N'Illustrative classification for academic practice', 1),
    ('CICMS-2026-0010', N'Fraud',                     'REVIEW-REQUIRED-01', N'Illustrative classification for academic practice', 1),
    ('CICMS-2026-0011', N'Domestic Violence',         NULL,                 N'Illustrative classification for academic practice', 1),
    ('CICMS-2026-0011', N'Assault',                   NULL,                 N'Alleged physical element',                          0),
    ('CICMS-2026-0012', N'Drug-Related Offence',      NULL,                 N'Preliminary classification only',                   1)
) AS v (CaseNumber, CategoryName, ProvisionNumber, OffenceDescription, IsPrimary)
JOIN dbo.CriminalCases   AS c   ON c.CaseNumber    = v.CaseNumber
JOIN dbo.CrimeCategories AS cat ON cat.CategoryName = v.CategoryName
LEFT JOIN dbo.LegalProvisions AS lp ON lp.ProvisionNumber = v.ProvisionNumber;

INSERT INTO dbo.CasePersonRoles (CriminalCaseID, PersonID, CaseRole, IsIdentityVerified, RoleNotes)
SELECT c.CriminalCaseID, p.PersonID, v.CaseRole,
       CASE WHEN v.CaseRole IN (N'Complainant', N'Victim') THEN 1 ELSE 0 END,
       N'Sample role entry; a role does not imply guilt'
FROM (VALUES
    ('CICMS-2025-0001', N'Sanjana', N'Pillai',      N'Victim'),
    ('CICMS-2025-0001', N'Bhaskar', N'Raju',        N'Accused'),
    ('CICMS-2025-0002', N'Latha',   N'Subramaniam', N'Complainant'),
    ('CICMS-2026-0001', N'Ananya',  N'Reddy',       N'Victim'),
    ('CICMS-2026-0001', N'Ananya',  N'Reddy',       N'Complainant'),
    ('CICMS-2026-0001', N'Rahul',   N'Verma',       N'Witness'),
    ('CICMS-2026-0001', N'Suresh',  N'Kumar',       N'Suspect'),
    ('CICMS-2026-0002', N'Lakshmi', N'Prasad',      N'Complainant'),
    ('CICMS-2026-0002', N'Imran',   N'Ahmed',       N'Witness'),
    ('CICMS-2026-0002', N'Ravi',    N'Kiran',       N'Suspect'),
    ('CICMS-2026-0003', N'Farhan',  N'Ali',         N'Complainant'),
    ('CICMS-2026-0003', N'Pooja',   N'Menon',       N'Witness'),
    ('CICMS-2026-0003', N'Gopal',   N'Krishna',     N'Suspect'),
    ('CICMS-2026-0004', N'Zoya',    N'Begum',       N'Complainant'),
    ('CICMS-2026-0004', N'Venkat',  N'Rao',         N'Witness'),
    ('CICMS-2026-0005', N'Swathi',  N'Reddy',       N'Complainant'),
    ('CICMS-2026-0005', N'Swathi',  N'Reddy',       N'Victim'),
    ('CICMS-2026-0005', N'Ajay',    N'Bose',        N'Witness'),
    ('CICMS-2026-0006', N'Neha',    N'Singh',       N'Victim'),
    ('CICMS-2026-0006', N'Keerthi', N'Sharma',      N'Witness'),
    ('CICMS-2026-0006', N'Prakash', N'Rathod',      N'Suspect'),
    ('CICMS-2026-0007', N'Mohan',   N'Das',         N'Victim'),
    ('CICMS-2026-0007', N'Mohan',   N'Das',         N'Complainant'),
    ('CICMS-2026-0007', N'Gopal',   N'Krishna',     N'Suspect'),
    ('CICMS-2026-0007', N'Gopal',   N'Krishna',     N'Accused'),
    ('CICMS-2026-0008', N'Kavya',   N'Rao',         N'Missing Person'),
    ('CICMS-2026-0008', N'Mahesh',  N'Naidu',       N'Next Of Kin'),
    ('CICMS-2026-0008', N'Mahesh',  N'Naidu',       N'Complainant'),
    ('CICMS-2026-0009', N'Nisha',   N'Patel',       N'Victim'),
    ('CICMS-2026-0010', N'Zoya',    N'Begum',       N'Complainant'),
    ('CICMS-2026-0010', N'Harish',  N'Goud',        N'Suspect'),
    ('CICMS-2026-0010', N'Harish',  N'Goud',        N'Accused'),
    ('CICMS-2026-0011', N'Sunitha', N'Varma',       N'Victim'),
    ('CICMS-2026-0011', N'Sunitha', N'Varma',       N'Complainant'),
    ('CICMS-2026-0011', N'Arvind',  N'Hegde',       N'Suspect'),
    ('CICMS-2026-0012', N'Irfan',   N'Sheikh',      N'Informant')
) AS v (CaseNumber, GivenName, FamilyName, CaseRole)
JOIN dbo.CriminalCases AS c ON c.CaseNumber = v.CaseNumber
JOIN dbo.Persons       AS p ON p.GivenName = v.GivenName AND p.FamilyName = v.FamilyName;

-- ---------- Investigation work ----------
INSERT INTO dbo.InvestigationAssignments
    (CriminalCaseID, PoliceOfficerID, AssignmentRole, AssignedAt, ReleasedAt, AssignedByOfficerID, AssignmentNotes)
SELECT c.CriminalCaseID, o.PoliceOfficerID, v.AssignmentRole,
       DATEADD(hour, v.HoursAfterOpening, c.OpenedAt),
       CASE WHEN v.DaysUntilRelease IS NULL THEN NULL ELSE DATEADD(day, v.DaysUntilRelease, c.OpenedAt) END,
       sup.PoliceOfficerID, v.AssignmentNotes
FROM (VALUES
    ('CICMS-2025-0001', 'DEMO-1005', N'Lead Investigator',  1, 150,  N'Legacy case; lead officer at the time'),
    ('CICMS-2025-0002', 'DEMO-1003', N'Lead Investigator',  1, 110,  N'Legacy case; lead officer at the time'),
    ('CICMS-2026-0001', 'DEMO-1001', N'Lead Investigator',  1, NULL, N'Initial assignment'),
    ('CICMS-2026-0001', 'DEMO-1002', N'Supporting Officer', 6, NULL, N'Helps with CCTV collection'),
    ('CICMS-2026-0002', 'DEMO-1003', N'Lead Investigator',  1, NULL, N'Initial assignment'),
    ('CICMS-2026-0002', 'DEMO-1007', N'Supporting Officer', 2, 20,   N'Released after the bank records were collected'),
    ('CICMS-2026-0003', 'DEMO-1005', N'Lead Investigator',  1, NULL, N'Initial assignment'),
    ('CICMS-2026-0003', 'DEMO-1004', N'Supporting Officer', 8, NULL, N'Scene and neighbourhood enquiries'),
    ('CICMS-2026-0004', 'DEMO-1009', N'Lead Investigator',  1, NULL, N'Initial assignment'),
    ('CICMS-2026-0005', 'DEMO-1002', N'Lead Investigator',  1, NULL, N'Cyber cell officer'),
    ('CICMS-2026-0005', 'DEMO-1001', N'Supervising Officer',4, NULL, N'Inspector supervising the cyber enquiry'),
    ('CICMS-2026-0006', 'DEMO-1003', N'Lead Investigator',  1, NULL, N'Initial assignment'),
    ('CICMS-2026-0007', 'DEMO-1005', N'Lead Investigator',  1, NULL, N'Initial assignment'),
    ('CICMS-2026-0008', 'DEMO-1009', N'Lead Investigator',  1, NULL, N'Initial assignment'),
    ('CICMS-2026-0009', 'DEMO-1002', N'Lead Investigator',  1, 42,   N'Released after the case was closed'),
    ('CICMS-2026-0010', 'DEMO-1003', N'Lead Investigator',  1, NULL, N'Initial assignment'),
    ('CICMS-2026-0011', 'DEMO-1001', N'Lead Investigator',  1, NULL, N'Restricted case; assigned by name'),
    ('CICMS-2026-0012', 'DEMO-1004', N'Lead Investigator',  1, NULL, N'Preliminary enquiry only')
) AS v (CaseNumber, ServiceNumber, AssignmentRole, HoursAfterOpening, DaysUntilRelease, AssignmentNotes)
JOIN dbo.CriminalCases  AS c ON c.CaseNumber    = v.CaseNumber
JOIN dbo.PoliceOfficers AS o ON o.ServiceNumber = v.ServiceNumber
JOIN dbo.PoliceOfficers AS sup ON sup.ServiceNumber = 'DEMO-1008';

-- Diary entries are written by each case's lead investigator
INSERT INTO dbo.CaseDiaryEntries (CriminalCaseID, EntryNumber, EntryDateTime, PoliceOfficerID, ActivityLocation, EntryNarrative)
SELECT c.CriminalCaseID, 1, DATEADD(hour, 3, c.OpenedAt), ia.PoliceOfficerID, c.IncidentLocation,
       N'First review of the case file and plan of action recorded.'
FROM dbo.CriminalCases AS c
JOIN dbo.InvestigationAssignments AS ia ON ia.CriminalCaseID = c.CriminalCaseID AND ia.AssignmentRole = N'Lead Investigator'
WHERE c.CaseNumber <> 'CICMS-2026-0012';

INSERT INTO dbo.CaseDiaryEntries (CriminalCaseID, EntryNumber, EntryDateTime, PoliceOfficerID, ActivityLocation, EntryNarrative)
SELECT c.CriminalCaseID, 2, DATEADD(day, 2, c.OpenedAt), ia.PoliceOfficerID, c.IncidentLocation,
       N'Follow-up enquiries made and statements arranged.'
FROM dbo.CriminalCases AS c
JOIN dbo.InvestigationAssignments AS ia ON ia.CriminalCaseID = c.CriminalCaseID AND ia.AssignmentRole = N'Lead Investigator'
WHERE c.CaseNumber IN ('CICMS-2026-0001','CICMS-2026-0002','CICMS-2026-0003','CICMS-2026-0005',
                       'CICMS-2026-0007','CICMS-2026-0008','CICMS-2026-0010','CICMS-2026-0011');

INSERT INTO dbo.CaseDiaryEntries (CriminalCaseID, EntryNumber, EntryDateTime, PoliceOfficerID, ActivityLocation, EntryNarrative)
SELECT c.CriminalCaseID, 3, DATEADD(day, 10, c.OpenedAt), ia.PoliceOfficerID, N'Police station',
       N'Evidence reviewed against statements; next steps agreed with the supervising officer.'
FROM dbo.CriminalCases AS c
JOIN dbo.InvestigationAssignments AS ia ON ia.CriminalCaseID = c.CriminalCaseID AND ia.AssignmentRole = N'Lead Investigator'
WHERE c.CaseNumber IN ('CICMS-2026-0001','CICMS-2026-0003','CICMS-2026-0007');

-- Scene visits (linked to diary entry 1) for every case that has a diary
INSERT INTO dbo.InvestigationActivities
    (CriminalCaseID, PoliceOfficerID, ActivityType, ActivityStartedAt, ActivityEndedAt, ActivityLocation, ActivityOutcome, RelatedCaseDiaryEntryID)
SELECT c.CriminalCaseID, d.PoliceOfficerID, N'Scene Visit', DATEADD(hour, 2, c.OpenedAt), DATEADD(hour, 3, c.OpenedAt),
       c.IncidentLocation, N'Scene observed and notes recorded in the case file.', d.CaseDiaryEntryID
FROM dbo.CriminalCases AS c
JOIN dbo.CaseDiaryEntries AS d ON d.CriminalCaseID = c.CriminalCaseID AND d.EntryNumber = 1;

INSERT INTO dbo.InvestigationActivities
    (CriminalCaseID, PoliceOfficerID, ActivityType, ActivityStartedAt, ActivityEndedAt, ActivityLocation, ActivityOutcome, RelatedCaseDiaryEntryID)
SELECT c.CriminalCaseID, d.PoliceOfficerID, N'Witness Canvass', DATEADD(day, 1, c.OpenedAt), DATEADD(minute, 90, DATEADD(day, 1, c.OpenedAt)),
       c.IncidentLocation, N'Nearby residents and shop staff asked what they saw.', d.CaseDiaryEntryID
FROM dbo.CriminalCases AS c
JOIN dbo.CaseDiaryEntries AS d ON d.CriminalCaseID = c.CriminalCaseID AND d.EntryNumber = 2
WHERE c.CaseNumber IN ('CICMS-2026-0001','CICMS-2026-0002','CICMS-2026-0003','CICMS-2026-0008');

INSERT INTO dbo.InvestigationActivities
    (CriminalCaseID, PoliceOfficerID, ActivityType, ActivityStartedAt, ActivityEndedAt, ActivityLocation, ActivityOutcome, RelatedCaseDiaryEntryID)
SELECT c.CriminalCaseID, o.PoliceOfficerID, v.ActivityType, v.StartedAt, v.EndedAt, v.ActivityLocation, v.ActivityOutcome, NULL
FROM (VALUES
    ('CICMS-2026-0001', 'DEMO-1002', N'CCTV Collection',        '2026-01-12T15:00:00', '2026-01-12T16:00:00', N'Shops near the complex, Banjara Hills', N'Footage copied from two cameras.'),
    ('CICMS-2026-0005', 'DEMO-1002', N'Account Log Review',     '2026-03-16T10:00:00', '2026-03-16T13:30:00', N'Cyber Crime Cell',                      N'Login history exported for examination.'),
    ('CICMS-2026-0007', 'DEMO-1005', N'Recovery Operation',     '2026-04-03T07:00:00', '2026-04-03T10:30:00', N'Gachibowli, Hyderabad',                 N'Vehicle located and taken into custody.'),
    ('CICMS-2026-0008', 'DEMO-1009', N'Search of Last Location','2026-04-11T08:00:00', NULL,                  N'Tirupati bus station area',             N'Search is still going on.')
) AS v (CaseNumber, ServiceNumber, ActivityType, StartedAt, EndedAt, ActivityLocation, ActivityOutcome)
JOIN dbo.CriminalCases  AS c ON c.CaseNumber    = v.CaseNumber
JOIN dbo.PoliceOfficers AS o ON o.ServiceNumber = v.ServiceNumber;

INSERT INTO dbo.WitnessStatements
    (CriminalCaseID, WitnessPersonID, RecordedByOfficerID, StatementRecordedAt, StatementType, StatementSummary,
     SecureDocumentReference, InterpreterRequired, WitnessReviewedStatement)
SELECT c.CriminalCaseID, p.PersonID, ia.PoliceOfficerID, DATEADD(day, 1, c.OpenedAt), N'Initial Statement',
       N'Witness described what they recall seeing; summary only, full text kept in the secure store.',
       N'DEMO-STATEMENT-' + c.CaseNumber + N'-' + CAST(p.PersonID AS NVARCHAR(10)),
       CASE WHEN p.PreferredLanguage IN (N'Malayalam', N'Bengali') THEN 1 ELSE 0 END,
       CASE WHEN c.CaseNumber = 'CICMS-2026-0006' THEN 0 ELSE 1 END
FROM dbo.CriminalCases AS c
JOIN dbo.CasePersonRoles AS r ON r.CriminalCaseID = c.CriminalCaseID AND r.CaseRole = N'Witness'
JOIN dbo.Persons AS p ON p.PersonID = r.PersonID
JOIN dbo.InvestigationAssignments AS ia ON ia.CriminalCaseID = c.CriminalCaseID AND ia.AssignmentRole = N'Lead Investigator'
WHERE c.CaseNumber IN ('CICMS-2026-0001','CICMS-2026-0002','CICMS-2026-0003','CICMS-2026-0004','CICMS-2026-0005','CICMS-2026-0006');

INSERT INTO dbo.WitnessStatements
    (CriminalCaseID, WitnessPersonID, RecordedByOfficerID, StatementRecordedAt, StatementType, StatementSummary,
     SecureDocumentReference, InterpreterRequired, WitnessReviewedStatement)
SELECT c.CriminalCaseID, p.PersonID, ia.PoliceOfficerID, '2026-01-20T11:00:00', N'Supplementary Statement',
       N'Witness added a detail about the direction the suspect walked in.',
       N'DEMO-STATEMENT-SUPP-0001', 0, 1
FROM dbo.CriminalCases AS c
JOIN dbo.Persons AS p ON p.GivenName = N'Rahul' AND p.FamilyName = N'Verma'
JOIN dbo.InvestigationAssignments AS ia ON ia.CriminalCaseID = c.CriminalCaseID AND ia.AssignmentRole = N'Lead Investigator'
WHERE c.CaseNumber = 'CICMS-2026-0001';

INSERT INTO dbo.Interviews
    (CriminalCaseID, PersonID, InterviewingOfficerID, InterviewStartedAt, InterviewEndedAt, InterviewLocation,
     InterviewPurpose, InterviewSummary, RecordingReference)
SELECT c.CriminalCaseID, p.PersonID, ia.PoliceOfficerID, DATEADD(day, 2, c.OpenedAt), DATEADD(hour, 1, DATEADD(day, 2, c.OpenedAt)),
       N'Police station interview room', N'Clarify the reported timeline of the incident',
       N'Interview summary only; nothing here concludes guilt.', NULL
FROM dbo.CriminalCases AS c
JOIN dbo.CasePersonRoles AS r ON r.CriminalCaseID = c.CriminalCaseID AND r.CaseRole IN (N'Complainant', N'Victim')
JOIN dbo.Persons AS p ON p.PersonID = r.PersonID
JOIN dbo.InvestigationAssignments AS ia ON ia.CriminalCaseID = c.CriminalCaseID AND ia.AssignmentRole = N'Lead Investigator'
WHERE (c.CaseNumber IN ('CICMS-2026-0001','CICMS-2026-0002','CICMS-2026-0011') AND r.CaseRole = N'Complainant')
   OR (c.CaseNumber = 'CICMS-2026-0006' AND r.CaseRole = N'Victim');

INSERT INTO dbo.Interviews
    (CriminalCaseID, PersonID, InterviewingOfficerID, InterviewStartedAt, InterviewEndedAt, InterviewLocation,
     InterviewPurpose, InterviewSummary, RecordingReference)
SELECT c.CriminalCaseID, p.PersonID, ia.PoliceOfficerID, v.StartedAt, DATEADD(minute, 75, v.StartedAt),
       N'Police station interview room', N'Put the allegation to the named suspect and record the response',
       N'Interview recorded; the suspect denied involvement. This is an allegation, not a finding.', v.RecordingRef
FROM (VALUES
    ('CICMS-2026-0001', N'Suresh', N'Kumar',   '2026-01-19T11:00:00', 'DEMO-REC-0001'),
    ('CICMS-2026-0007', N'Gopal',  N'Krishna', '2026-04-03T11:30:00', 'DEMO-REC-0002')
) AS v (CaseNumber, GivenName, FamilyName, StartedAt, RecordingRef)
JOIN dbo.CriminalCases AS c ON c.CaseNumber = v.CaseNumber
JOIN dbo.Persons AS p ON p.GivenName = v.GivenName AND p.FamilyName = v.FamilyName
JOIN dbo.InvestigationAssignments AS ia ON ia.CriminalCaseID = c.CriminalCaseID AND ia.AssignmentRole = N'Lead Investigator';

-- ---------- Arrests, custody, searches ----------
INSERT INTO dbo.Arrests
    (CriminalCaseID, ArrestedPersonID, ArrestingOfficerID, ArrestedAt, ArrestLocation, ArrestGrounds,
     ArrestMemoReference, ProducedBeforeCourtAt, ArrestStatus)
SELECT c.CriminalCaseID, p.PersonID, o.PoliceOfficerID, v.ArrestedAt, v.ArrestLocation,
       N'Sample record; real legal grounds must always be verified independently.', v.MemoReference, v.ProducedAt, v.ArrestStatus
FROM (VALUES
    ('CICMS-2026-0007', N'Gopal',   N'Krishna', 'DEMO-1005', '2026-04-03T08:30:00', N'Gachibowli, Hyderabad', 'DEMO-ARREST-0001', '2026-04-03T15:30:00', N'Bailed'),
    ('CICMS-2026-0001', N'Suresh',  N'Kumar',   'DEMO-1001', '2026-01-20T07:45:00', N'Begum Bazar, Hyderabad', 'DEMO-ARREST-0002', '2026-01-20T15:00:00', N'Judicial Custody'),
    ('CICMS-2026-0002', N'Ravi',    N'Kiran',   'DEMO-1003', '2026-02-10T06:30:00', N'Falaknuma, Hyderabad',  'DEMO-ARREST-0003', '2026-02-10T14:00:00', N'Police Custody'),
    ('CICMS-2026-0010', N'Harish',  N'Goud',    'DEMO-1003', '2026-05-03T09:00:00', N'Charminar, Hyderabad',  'DEMO-ARREST-0004', '2026-05-03T16:00:00', N'Bailed'),
    ('CICMS-2026-0006', N'Prakash', N'Rathod',  'DEMO-1003', '2026-03-22T10:30:00', N'Charminar, Hyderabad',  'DEMO-ARREST-0005', NULL,                  N'Released')
) AS v (CaseNumber, GivenName, FamilyName, ServiceNumber, ArrestedAt, ArrestLocation, MemoReference, ProducedAt, ArrestStatus)
JOIN dbo.CriminalCases  AS c ON c.CaseNumber    = v.CaseNumber
JOIN dbo.Persons        AS p ON p.GivenName = v.GivenName AND p.FamilyName = v.FamilyName
JOIN dbo.PoliceOfficers AS o ON o.ServiceNumber = v.ServiceNumber;

INSERT INTO dbo.CustodyRecords
    (ArrestID, CustodyType, CustodyLocation, CustodyStartedAt, CustodyEndedAt, AuthorizedByOfficerID, ReleaseOrTransferReason)
SELECT a.ArrestID, v.CustodyType, v.CustodyLocation, v.StartedAt, v.EndedAt, o.PoliceOfficerID, v.Reason
FROM (VALUES
    ('DEMO-ARREST-0001', N'Police Custody',   N'Station custody area',       '2026-04-03T08:30:00', '2026-04-03T14:30:00', 'DEMO-1008', N'Produced before the court and released on bail'),
    ('DEMO-ARREST-0002', N'Police Custody',   N'Station custody area',       '2026-01-20T07:45:00', '2026-01-22T09:00:00', 'DEMO-1008', N'Police remand period ended'),
    ('DEMO-ARREST-0002', N'Judicial Custody', N'District jail (demo)',       '2026-01-22T10:00:00', NULL,                  'DEMO-1008', NULL),
    ('DEMO-ARREST-0003', N'Police Custody',   N'Station custody area',       '2026-02-10T06:30:00', NULL,                  'DEMO-1008', NULL),
    ('DEMO-ARREST-0004', N'Police Custody',   N'Station custody area',       '2026-05-03T09:00:00', '2026-05-03T18:00:00', 'DEMO-1008', N'Released after the bail order'),
    ('DEMO-ARREST-0005', N'Police Custody',   N'Station custody area',       '2026-03-22T10:30:00', '2026-03-22T16:00:00', 'DEMO-1008', N'Released after questioning')
) AS v (MemoReference, CustodyType, CustodyLocation, StartedAt, EndedAt, ServiceNumber, Reason)
JOIN dbo.Arrests        AS a ON a.ArrestMemoReference = v.MemoReference
JOIN dbo.PoliceOfficers AS o ON o.ServiceNumber       = v.ServiceNumber;

INSERT INTO dbo.SearchAuthorizations
    (CriminalCaseID, AuthorizationType, IssuedByAuthority, AuthorizationReference, RequestedAt, AuthorizedAt, ValidUntil, AuthorizationStatus, DocumentReference)
SELECT c.CriminalCaseID, v.AuthType, N'Competent authority (fictional)', v.Reference, v.RequestedAt, v.AuthorizedAt, v.ValidUntil, v.AuthStatus, v.DocRef
FROM (VALUES
    ('CICMS-2026-0003', N'Premises search',        'DEMO-SEARCH-AUTH-0001', '2026-02-18T09:00:00', '2026-02-18T12:00:00', '2026-02-19T12:00:00', N'Executed', N'DEMO-AUTH-DOCUMENT-0001'),
    ('CICMS-2026-0005', N'Digital device search',  'DEMO-SEARCH-AUTH-0002', '2026-03-16T09:00:00', '2026-03-16T10:00:00', '2026-03-23T10:00:00', N'Granted',  N'DEMO-AUTH-DOCUMENT-0002'),
    ('CICMS-2026-0007', N'Vehicle search',         'DEMO-SEARCH-AUTH-0003', '2026-04-02T17:00:00', '2026-04-02T18:00:00', '2026-04-03T18:00:00', N'Executed', N'DEMO-AUTH-DOCUMENT-0003'),
    ('CICMS-2026-0010', N'Premises search',        'DEMO-SEARCH-AUTH-0004', '2026-05-02T11:00:00', NULL,                  NULL,                  N'Pending',  NULL),
    ('CICMS-2026-0002', N'Premises search',        'DEMO-SEARCH-AUTH-0005', '2026-02-06T10:00:00', '2026-02-06T15:00:00', '2026-02-08T15:00:00', N'Expired',  N'DEMO-AUTH-DOCUMENT-0005')
) AS v (CaseNumber, AuthType, Reference, RequestedAt, AuthorizedAt, ValidUntil, AuthStatus, DocRef)
JOIN dbo.CriminalCases AS c ON c.CaseNumber = v.CaseNumber;

INSERT INTO dbo.SearchOperations
    (CriminalCaseID, SearchAuthorizationID, LeadOfficerID, SearchStartedAt, SearchEndedAt, SearchLocation, SearchPurpose, SearchOutcome)
SELECT c.CriminalCaseID, sa.SearchAuthorizationID, o.PoliceOfficerID, v.StartedAt, v.EndedAt, v.SearchLocation, v.SearchPurpose, v.SearchOutcome
FROM (VALUES
    ('CICMS-2026-0003', 'DEMO-SEARCH-AUTH-0001', 'DEMO-1005', '2026-02-18T13:00:00', '2026-02-18T14:30:00', N'Gachibowli, Hyderabad',
        N'Search for items linked to the reported break-in', N'Search completed; items listed in the search record.'),
    ('CICMS-2026-0007', 'DEMO-SEARCH-AUTH-0003', 'DEMO-1005', '2026-04-03T07:30:00', '2026-04-03T09:00:00', N'Gachibowli, Hyderabad',
        N'Search of the recovery site', N'Vehicle and a key found and sealed.'),
    ('CICMS-2026-0001', NULL,                    'DEMO-1001', '2026-01-13T10:00:00', '2026-01-13T10:45:00', N'Commercial complex, Banjara Hills',
        N'Consent-based check of the area with the shop owner', N'Nothing further located.')
) AS v (CaseNumber, AuthReference, ServiceNumber, StartedAt, EndedAt, SearchLocation, SearchPurpose, SearchOutcome)
JOIN dbo.CriminalCases   AS c ON c.CaseNumber    = v.CaseNumber
JOIN dbo.PoliceOfficers  AS o ON o.ServiceNumber = v.ServiceNumber
LEFT JOIN dbo.SearchAuthorizations AS sa ON sa.AuthorizationReference = v.AuthReference;

-- ---------- Evidence and forensics ----------
-- Hash values below are SHA-256 digests of demo text, so they look like real file hashes but belong to no real file.
INSERT INTO dbo.EvidenceItems
    (CriminalCaseID, EvidenceTypeID, ExhibitNumber, EvidenceDescription, CollectedAt, CollectionLocation, CollectedByOfficerID,
     InitialCondition, SealNumber, StorageLocation, EvidenceStatus, IsDigitalEvidence, DigitalFileHashSHA256, SecureFileReference)
SELECT c.CriminalCaseID, et.EvidenceTypeID, v.ExhibitNumber, v.EvidenceDescription, v.CollectedAt, v.CollectionLocation, o.PoliceOfficerID,
       v.InitialCondition, v.SealNumber, v.StorageLocation, v.EvidenceStatus, v.IsDigital, v.FileHash, v.FileReference
FROM (VALUES
 ('CICMS-2026-0001', N'CCTV Footage',        'EX-0001', N'CCTV clip from a nearby shop',                  '2026-01-12T16:00:00', N'Banjara Hills, Hyderabad',    'DEMO-1001', N'Digital copy received',      'SEAL-DEMO-001', N'Digital Evidence Vault',   N'Returned from Forensics', 1, 'C0C66E841786212AFC4FCBDB6EDE749C78A98FA5D42F4609BFB28DE153DC2385', N'DEMO-FILE-CCTV-0001'),
 ('CICMS-2026-0001', N'Fingerprint',         'EX-0002', N'Fingerprint lifted from a display counter',     '2026-01-12T16:30:00', N'Banjara Hills, Hyderabad',    'DEMO-1002', N'Sealed packet',              'SEAL-DEMO-002', N'Evidence Locker A-01',     N'In Storage',              0, NULL,                 N'DEMO-PHYSICAL-EX-0002'),
 ('CICMS-2026-0002', N'Financial Record',    'EX-0003', N'Printed transaction statement',                 '2026-02-04T12:00:00', N'Charminar Police Station',    'DEMO-1003', N'Printed copy in sealed envelope','SEAL-DEMO-003', N'Evidence Locker B-02',  N'In Storage',              0, NULL,                 N'DEMO-FIN-0003'),
 ('CICMS-2026-0005', N'Mobile Phone',        'EX-0004', N'Mobile device submitted for authorized examination','2026-03-15T13:00:00', N'Banjara Hills Police Station','DEMO-1001', N'Sealed device bag',        'SEAL-DEMO-004', N'Digital Evidence Locker',  N'Sent for Forensics',      1, '7FB43DF08E47B9471741BD00F7FF06F67053B813646EF4784B8108FD5351B00D', N'DEMO-DEVICE-0004'),
 ('CICMS-2026-0003', N'Photograph',          'EX-0005', N'Photograph of the forced entry point',          '2026-02-17T11:00:00', N'Gachibowli, Hyderabad',       'DEMO-1005', N'Digital photograph',         'SEAL-DEMO-005', N'Digital Evidence Vault',   N'In Storage',              1, '94C1F630C51752183FF9B89173878DCC294EEEFD2FB153276FADB5DC722A34D3', N'DEMO-PHOTO-0005'),
 ('CICMS-2026-0007', N'Recovered Property',  'EX-0006', N'Motorcycle key recovered with the vehicle',     '2026-04-03T10:00:00', N'Gachibowli, Hyderabad',       'DEMO-1005', N'Bagged and labelled',        'SEAL-DEMO-006', N'Evidence Locker C-01',     N'In Storage',              0, NULL,                 N'DEMO-KEY-0006'),
 ('CICMS-2026-0002', N'Document',            'EX-0007', N'Screenshots of the bank alert messages',        '2026-02-04T13:00:00', N'Charminar Police Station',    'DEMO-1003', N'Digital copy received',      'SEAL-DEMO-007', N'Digital Evidence Vault',   N'In Storage',              1, 'FDE048A6384F21B8EF9117063A831FD9BA7F679043B695123105F02102D52C81', N'DEMO-FILE-SMS-0007'),
 ('CICMS-2026-0003', N'Fingerprint',         'EX-0008', N'Fingerprint lifted from the door frame',        '2026-02-17T11:30:00', N'Gachibowli, Hyderabad',       'DEMO-1004', N'Sealed packet',              'SEAL-DEMO-008', N'Regional Forensic Unit (Demo)', N'Sent for Forensics',  0, NULL,                 N'DEMO-PHYSICAL-EX-0008'),
 ('CICMS-2026-0006', N'Photograph',          'EX-0009', N'Photographs of the market area',                '2026-03-21T15:00:00', N'Charminar, Hyderabad',        'DEMO-1003', N'Digital photograph',         'SEAL-DEMO-009', N'Digital Evidence Vault',   N'In Storage',              1, 'F0741C05F432CEAEC9A434DB6E0F0B3F5A8F06EA4800BF272A2BD9D58C7E4B66', N'DEMO-PHOTO-0009'),
 ('CICMS-2026-0007', N'CCTV Footage',        'EX-0010', N'Parking area CCTV clip',                        '2026-04-02T18:30:00', N'Gachibowli, Hyderabad',       'DEMO-1005', N'Digital copy received',      'SEAL-DEMO-010', N'Fictional Metropolitan Magistrate Court', N'Presented in Court', 1, '86FBB443A65D99595373B6ADC33E8F7E7895658E9B91DEF5207513D90EB08159', N'DEMO-FILE-CCTV-0010'),
 ('CICMS-2026-0008', N'Mobile Phone',        'EX-0011', N'Missing person''s phone left at home',          '2026-04-11T11:00:00', N'Tirupati, Andhra Pradesh',    'DEMO-1009', N'Sealed device bag',          'SEAL-DEMO-011', N'Digital Evidence Locker',  N'Sent for Forensics',      1, 'FD76529C4C6D02D54EBBC0956279B6907283AF55494E3AEC2EA5B3AC79E60D1A', N'DEMO-DEVICE-0011'),
 ('CICMS-2026-0009', N'Photograph',          'EX-0012', N'Photographs of the damaged shutters',           '2026-04-18T11:00:00', N'Banjara Hills, Hyderabad',    'DEMO-1002', N'Digital photograph',         'SEAL-DEMO-012', N'Digital Evidence Vault',   N'Released',                1, '16D2A27EC8BB053AAE0624F4E01FEA0FD48E9E33D69878098AE1E9B3BED12900', N'DEMO-PHOTO-0012'),
 ('CICMS-2026-0010', N'Financial Record',    'EX-0013', N'Order and payment records from the business',   '2026-05-02T12:00:00', N'Charminar, Hyderabad',        'DEMO-1003', N'Printed copies sealed',      'SEAL-DEMO-013', N'Evidence Locker B-03',     N'In Storage',              0, NULL,                 N'DEMO-FIN-0013'),
 ('CICMS-2026-0001', N'Clothing',            'EX-0014', N'Jacket left behind at the scene',               '2026-01-12T17:00:00', N'Banjara Hills, Hyderabad',    'DEMO-1001', N'Bagged, seal pending',       NULL,            NULL,                        N'Collected',               0, NULL,                 NULL)
) AS v (CaseNumber, EvidenceTypeName, ExhibitNumber, EvidenceDescription, CollectedAt, CollectionLocation, ServiceNumber,
        InitialCondition, SealNumber, StorageLocation, EvidenceStatus, IsDigital, FileHash, FileReference)
JOIN dbo.CriminalCases  AS c  ON c.CaseNumber = v.CaseNumber
JOIN dbo.EvidenceTypes  AS et ON et.EvidenceTypeName = v.EvidenceTypeName
JOIN dbo.PoliceOfficers AS o  ON o.ServiceNumber = v.ServiceNumber;

-- Forensic requests and reports are created before the custody transfers, because some transfers depend on them
INSERT INTO dbo.ForensicRequests
    (EvidenceItemID, ForensicLaboratoryID, RequestedByOfficerID, RequestedAt, ExaminationType, ExaminationQuestions, RequestStatus, CompletedAt)
SELECT e.EvidenceItemID, fl.ForensicLaboratoryID, o.PoliceOfficerID, v.RequestedAt, v.ExaminationType, v.ExaminationQuestions, v.RequestStatus, v.CompletedAt
FROM (VALUES
    ('EX-0001', N'Digital Evidence Examination Unit (Demo)', 'DEMO-1001', '2026-01-13T16:00:00', N'Video enhancement and timeline review',
        N'Can the person be seen clearly, and what is the timeline of movements?',            N'Completed',   '2026-01-17T16:00:00'),
    ('EX-0004', N'Telangana Regional Forensic Unit (Demo)',  'DEMO-1001', '2026-03-16T13:00:00', N'Digital device examination',
        N'Does the device hold login or message data relevant to the reported incident?',     N'In Progress', NULL),
    ('EX-0008', N'Telangana Regional Forensic Unit (Demo)',  'DEMO-1005', '2026-02-18T11:30:00', N'Fingerprint comparison',
        N'Can the lifted print be compared with the prints on file?',                         N'In Progress', NULL),
    ('EX-0011', N'Digital Evidence Examination Unit (Demo)', 'DEMO-1009', '2026-04-12T11:00:00', N'Digital device examination',
        N'Is there call or location data that shows where the owner went last?',              N'Submitted',   NULL)
) AS v (ExhibitNumber, LaboratoryName, ServiceNumber, RequestedAt, ExaminationType, ExaminationQuestions, RequestStatus, CompletedAt)
JOIN dbo.EvidenceItems        AS e  ON e.ExhibitNumber  = v.ExhibitNumber
JOIN dbo.ForensicLaboratories AS fl ON fl.LaboratoryName = v.LaboratoryName
JOIN dbo.PoliceOfficers       AS o  ON o.ServiceNumber  = v.ServiceNumber;

INSERT INTO dbo.ForensicReports
    (ForensicRequestID, ReportNumber, ReportIssuedAt, ExaminerName, MethodologySummary, FindingsSummary, Limitations, SecureReportReference, ReportStatus)
SELECT fr.ForensicRequestID, v.ReportNumber, v.IssuedAt, v.ExaminerName, v.Methodology, v.Findings, v.Limitations, v.ReportRef, v.ReportStatus
FROM (VALUES
    ('EX-0001', 'DEMO-FR-0001',   '2026-01-17T16:00:00', N'Dr. Meera Joshi (fictional)', N'Frame-by-frame review of the footage',
        N'Sample report for SQL practice only; it has no evidentiary value.', N'Not a real forensic conclusion.', N'DEMO-FORENSIC-REPORT-0001', N'Final'),
    ('EX-0001', 'DEMO-FR-0001-A', '2026-01-24T10:00:00', N'Dr. Meera Joshi (fictional)', N'Same method, with an added timeline table',
        N'Amended sample report with a corrected timestamp table.',          N'Not a real forensic conclusion.', N'DEMO-FORENSIC-REPORT-0001A', N'Amended'),
    ('EX-0008', 'DEMO-FR-0003',   '2026-02-24T12:00:00', N'S. Rahman (fictional)',       N'Ridge detail comparison',
        N'Draft sample findings waiting for a second examiner to review.',   N'Draft; peer review not finished.',  N'DEMO-FORENSIC-REPORT-0003', N'Peer Review')
) AS v (ExhibitNumber, ReportNumber, IssuedAt, ExaminerName, Methodology, Findings, Limitations, ReportRef, ReportStatus)
JOIN dbo.EvidenceItems    AS e  ON e.ExhibitNumber = v.ExhibitNumber
JOIN dbo.ForensicRequests AS fr ON fr.EvidenceItemID = e.EvidenceItemID;

-- 1) First move of every item into storage (everything except the jacket that is still waiting for a seal)
INSERT INTO dbo.EvidenceCustodyTransfers
    (EvidenceItemID, TransferredAt, TransferredByOfficerID, ReceivedByOfficerID, FromLocation, ToLocation,
     TransferPurpose, SealCondition, DigitalHashAtTransfer, TransferReceiptReference)
SELECT e.EvidenceItemID, DATEADD(hour, 2, e.CollectedAt), e.CollectedByOfficerID, keeper.PoliceOfficerID,
       e.CollectionLocation, ISNULL(e.StorageLocation, N'Station evidence room'),
       N'Initial secured storage transfer', N'Intact', e.DigitalFileHashSHA256, 'DEMO-TRANSFER-' + e.ExhibitNumber
FROM dbo.EvidenceItems AS e
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = e.CriminalCaseID
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = c.PoliceStationID
JOIN (VALUES ('TS-HYD-BH','DEMO-1006'), ('TS-HYD-CH','DEMO-1007'), ('TS-RRD-GC','DEMO-1004'), ('AP-TPT-TE','DEMO-1009'))
     AS k (StationCode, ServiceNumber) ON k.StationCode = ps.StationCode
JOIN dbo.PoliceOfficers AS keeper ON keeper.ServiceNumber = k.ServiceNumber
WHERE e.ExhibitNumber <> 'EX-0014';

-- 2) Items sent to a laboratory
INSERT INTO dbo.EvidenceCustodyTransfers
    (EvidenceItemID, TransferredAt, TransferredByOfficerID, ReceivedByOfficerID, FromLocation, ToLocation,
     TransferPurpose, SealCondition, DigitalHashAtTransfer, TransferReceiptReference)
SELECT e.EvidenceItemID, DATEADD(hour, 4, fr.RequestedAt), fr.RequestedByOfficerID, NULL,
       e.CollectionLocation, fl.LaboratoryName,
       N'Dispatch for forensic examination', N'Intact', e.DigitalFileHashSHA256, 'DEMO-TRANSFER-LAB-' + e.ExhibitNumber
FROM dbo.ForensicRequests AS fr
JOIN dbo.EvidenceItems AS e ON e.EvidenceItemID = fr.EvidenceItemID
JOIN dbo.ForensicLaboratories AS fl ON fl.ForensicLaboratoryID = fr.ForensicLaboratoryID;

-- 3) The completed examination comes back with a laboratory seal
INSERT INTO dbo.EvidenceCustodyTransfers
    (EvidenceItemID, TransferredAt, TransferredByOfficerID, ReceivedByOfficerID, FromLocation, ToLocation,
     TransferPurpose, SealCondition, DigitalHashAtTransfer, TransferReceiptReference)
SELECT e.EvidenceItemID, DATEADD(hour, 6, fr.CompletedAt), NULL, e.CollectedByOfficerID,
       fl.LaboratoryName, e.StorageLocation,
       N'Return after examination', N'Re-sealed by laboratory', e.DigitalFileHashSHA256, 'DEMO-TRANSFER-RET-' + e.ExhibitNumber
FROM dbo.ForensicRequests AS fr
JOIN dbo.EvidenceItems AS e ON e.EvidenceItemID = fr.EvidenceItemID
JOIN dbo.ForensicLaboratories AS fl ON fl.ForensicLaboratoryID = fr.ForensicLaboratoryID
WHERE fr.RequestStatus = N'Completed';

-- 4) Presented in court
INSERT INTO dbo.EvidenceCustodyTransfers
    (EvidenceItemID, TransferredAt, TransferredByOfficerID, ReceivedByOfficerID, FromLocation, ToLocation,
     TransferPurpose, SealCondition, DigitalHashAtTransfer, TransferReceiptReference)
SELECT e.EvidenceItemID, '2026-08-10T09:30:00', e.CollectedByOfficerID, NULL,
       N'Digital Evidence Vault', N'Fictional Metropolitan Magistrate Court',
       N'Produced during trial evidence', N'Intact', e.DigitalFileHashSHA256, 'DEMO-TRANSFER-COURT-' + e.ExhibitNumber
FROM dbo.EvidenceItems AS e
WHERE e.ExhibitNumber = 'EX-0010';

-- ---------- Property and missing persons ----------
INSERT INTO dbo.StolenProperties
    (CriminalCaseID, ReportedByPersonID, PropertyDescription, PropertyCategory, BrandOrMake, ModelOrVariant,
     SerialOrRegistrationNumber, EstimatedValueINR, DateLostOrStolen, PropertyStatus)
SELECT c.CriminalCaseID, p.PersonID, v.PropertyDescription, v.PropertyCategory, v.BrandOrMake, v.ModelOrVariant,
       v.SerialNumber, v.EstimatedValue, v.DateLost, v.PropertyStatus
FROM (VALUES
    ('CICMS-2026-0001', N'Ananya', N'Reddy', N'Smartphone',                      N'Electronics',      N'DemoBrand',  N'Model A', N'DEMO-PHONE-001',   18000, '2026-01-11T20:15:00', N'Not Recovered'),
    ('CICMS-2026-0001', N'Ananya', N'Reddy', N'Wireless earbuds',                N'Electronics',      N'DemoSound',  N'Buds 2',  N'DEMO-EARBUD-001',   3500, '2026-01-11T20:15:00', N'Not Recovered'),
    ('CICMS-2026-0007', N'Mohan',  N'Das',   N'Motorcycle',                      N'Vehicle',          N'Demo Motors',N'Model B', N'DEMO-VEHICLE-007', 85000, '2026-04-01T21:30:00', N'Recovered'),
    ('CICMS-2026-0007', N'Mohan',  N'Das',   N'Riding helmet',                   N'Accessories',      N'DemoGear',   NULL,       NULL,                 2500, '2026-04-01T21:30:00', N'Returned To Owner'),
    ('CICMS-2026-0004', N'Zoya',   N'Begum', N'Handbag containing personal items',N'Personal Property',NULL,        NULL,       N'DEMO-BAG-004',      4500, '2026-02-28T18:00:00', N'Partially Recovered'),
    ('CICMS-2026-0003', N'Farhan', N'Ali',   N'Silver tableware set',            N'Household',        NULL,          NULL,       NULL,                 NULL, '2026-02-16T23:45:00', N'Not Recovered')
) AS v (CaseNumber, GivenName, FamilyName, PropertyDescription, PropertyCategory, BrandOrMake, ModelOrVariant, SerialNumber, EstimatedValue, DateLost, PropertyStatus)
JOIN dbo.CriminalCases AS c ON c.CaseNumber = v.CaseNumber
JOIN dbo.Persons       AS p ON p.GivenName = v.GivenName AND p.FamilyName = v.FamilyName;

INSERT INTO dbo.PropertyRecoveries
    (StolenPropertyID, RecoveredAt, RecoveryLocation, RecoveredByOfficerID, RecoveryDescription, ReturnedToOwnerAt, HandoverReceiptReference)
SELECT sp.StolenPropertyID, v.RecoveredAt, v.RecoveryLocation, o.PoliceOfficerID, v.RecoveryDescription, v.ReturnedAt, v.Receipt
FROM (VALUES
    (N'DEMO-VEHICLE-007', '2026-04-03T10:00:00', N'Gachibowli, Hyderabad',      'DEMO-1005', N'Vehicle found parked and taken into custody',      '2026-04-06T12:00:00', 'DEMO-HANDOVER-007'),
    (N'Riding helmet',    '2026-04-03T10:00:00', N'Gachibowli, Hyderabad',      'DEMO-1005', N'Helmet found with the vehicle',                    '2026-04-06T12:00:00', 'DEMO-HANDOVER-007B'),
    (N'DEMO-BAG-004',     '2026-03-10T15:00:00', N'Auto stand, Tirupati',       'DEMO-1009', N'Bag found without the cash; papers recovered',     NULL,                  NULL)
) AS v (PropertyKey, RecoveredAt, RecoveryLocation, ServiceNumber, RecoveryDescription, ReturnedAt, Receipt)
JOIN dbo.StolenProperties AS sp ON sp.SerialOrRegistrationNumber = v.PropertyKey OR sp.PropertyDescription = v.PropertyKey
JOIN dbo.PoliceOfficers   AS o  ON o.ServiceNumber = v.ServiceNumber;

INSERT INTO dbo.MissingPersonReports
    (MissingPersonID, ReportedByPersonID, PoliceStationID, RelatedCaseID, ReportedAt, LastSeenAt, LastSeenLocation,
     ClothingAndAppearance, MissingPersonStatus, FoundAt)
SELECT mp.PersonID, rp.PersonID, ps.PoliceStationID, c.CriminalCaseID, v.ReportedAt, v.LastSeenAt, v.LastSeenLocation,
       v.Appearance, v.MissingStatus, v.FoundAt
FROM (VALUES
    (N'Kavya', N'Rao',      N'Mahesh', N'Naidu', 'AP-TPT-TE', 'CICMS-2026-0008', '2026-04-10T10:30:00', '2026-04-09T18:00:00', N'Tirupati bus station area',
        N'Description for training only; this is not a real alert.',                          N'Missing', NULL),
    (N'Dev',   N'Malhotra', N'Rekha',  N'Joshi', 'TS-HYD-BH', NULL,               '2026-05-08T09:00:00', '2026-05-07T20:00:00', N'Banjara Hills, Hyderabad',
        N'Adult who left after a family disagreement; found safe and returned home.',         N'Located', '2026-05-10T09:00:00')
) AS v (MissingGiven, MissingFamily, ReporterGiven, ReporterFamily, StationCode, CaseNumber, ReportedAt, LastSeenAt, LastSeenLocation,
        Appearance, MissingStatus, FoundAt)
JOIN dbo.Persons AS mp ON mp.GivenName = v.MissingGiven  AND mp.FamilyName = v.MissingFamily
JOIN dbo.Persons AS rp ON rp.GivenName = v.ReporterGiven AND rp.FamilyName = v.ReporterFamily
JOIN dbo.PoliceStations AS ps ON ps.StationCode = v.StationCode
LEFT JOIN dbo.CriminalCases AS c ON c.CaseNumber = v.CaseNumber;

-- ---------- Prosecution and courts ----------
INSERT INTO dbo.ChargeSheets
    (CriminalCaseID, ChargeSheetNumber, PreparedByOfficerID, PreparedAt, FiledAt, FilingCourtName, ChargeSheetType, SummaryOfFindings, DocumentReference)
SELECT c.CriminalCaseID, v.ChargeSheetNumber, o.PoliceOfficerID, v.PreparedAt, v.FiledAt, v.CourtName, v.SheetType, v.Summary, v.DocRef
FROM (VALUES
    ('CICMS-2025-0001', 'DEMO-CS-2025-0001',   'DEMO-1005', '2025-07-25T10:00:00', '2025-07-30T11:00:00', N'Fictional Metropolitan Magistrate Court', N'Final',         N'Sample charge sheet for the 2025 warehouse case.',        N'DEMO-CHARGESHEET-2025-0001'),
    ('CICMS-2026-0007', 'DEMO-CS-0007',        'DEMO-1005', '2026-05-10T10:00:00', '2026-05-12T11:00:00', N'Fictional Metropolitan Magistrate Court', N'Final',         N'Sample charge sheet record for database practice.',       N'DEMO-CHARGESHEET-0007'),
    ('CICMS-2026-0007', 'DEMO-CS-0007-S1',     'DEMO-1005', '2026-06-18T10:00:00', '2026-06-20T11:00:00', N'Fictional Metropolitan Magistrate Court', N'Supplementary',  N'Supplementary material added after the first hearing.',   N'DEMO-CHARGESHEET-0007-S1'),
    ('CICMS-2026-0010', 'DEMO-CS-0010',        'DEMO-1003', '2026-05-22T10:00:00', '2026-05-25T11:00:00', N'Fictional Metropolitan Magistrate Court', N'Final',         N'Sample charge sheet for the fraud case.',                 N'DEMO-CHARGESHEET-0010'),
    ('CICMS-2026-0001', 'DEMO-CS-0001-I',      'DEMO-1001', '2026-08-20T10:00:00', NULL,                  NULL,                                     N'Interim',       N'Interim draft; not yet filed in court.',                  N'DEMO-CHARGESHEET-0001-I')
) AS v (CaseNumber, ChargeSheetNumber, ServiceNumber, PreparedAt, FiledAt, CourtName, SheetType, Summary, DocRef)
JOIN dbo.CriminalCases  AS c ON c.CaseNumber    = v.CaseNumber
JOIN dbo.PoliceOfficers AS o ON o.ServiceNumber = v.ServiceNumber;

INSERT INTO dbo.ProsecutionTeams (CriminalCaseID, ProsecutorName, ProsecutorRole, OfficeName, ContactEmail, AssignedAt, ReleasedAt)
SELECT c.CriminalCaseID, v.ProsecutorName, v.ProsecutorRole, N'Demo District Prosecution Office', v.Email, v.AssignedAt, v.ReleasedAt
FROM (VALUES
    ('CICMS-2025-0001', N'Advocate Sunil Rao (fictional)',     N'Public Prosecutor',            'sunil.rao@example.test',   '2025-07-30', '2025-12-20'),
    ('CICMS-2026-0007', N'Advocate Ritu Menon (fictional)',    N'Public Prosecutor',            'ritu.menon@example.test',  '2026-05-12', NULL),
    ('CICMS-2026-0010', N'Advocate Anil Bhatt (fictional)',    N'Public Prosecutor',            'anil.bhatt@example.test',  '2026-05-04', NULL),
    ('CICMS-2026-0010', N'Advocate Fatima Zaidi (fictional)',  N'Assistant Public Prosecutor',  'fatima.zaidi@example.test','2026-05-04', '2026-07-15')
) AS v (CaseNumber, ProsecutorName, ProsecutorRole, Email, AssignedAt, ReleasedAt)
JOIN dbo.CriminalCases AS c ON c.CaseNumber = v.CaseNumber;

INSERT INTO dbo.CourtCases (CriminalCaseID, CourtName, CourtCaseNumber, CourtType, PresidingJudgeName, CaseFiledAt, CourtCaseStatus)
SELECT c.CriminalCaseID, N'Fictional Metropolitan Magistrate Court', v.CourtCaseNumber, N'Magistrate Court', v.JudgeName, v.FiledAt, v.CourtStatus
FROM (VALUES
    ('CICMS-2025-0001', 'DEMO-CC-2025-0001', N'Judge P. Naidu (fictional)', '2025-07-30', N'Appeal Filed'),
    ('CICMS-2026-0007', 'DEMO-CC-0007',      N'Judge A. Rao (fictional)',   '2026-05-12', N'Under Trial'),
    ('CICMS-2026-0010', 'DEMO-CC-0010',      N'Judge S. Iyer (fictional)',  '2026-05-04', N'Under Trial')
) AS v (CaseNumber, CourtCaseNumber, JudgeName, FiledAt, CourtStatus)
JOIN dbo.CriminalCases AS c ON c.CaseNumber = v.CaseNumber;

INSERT INTO dbo.CourtHearings (CourtCaseID, HearingDateTime, HearingPurpose, HearingOutcome, NextHearingDateTime, PresidingJudgeName)
SELECT cc.CourtCaseID, v.HearingAt, v.Purpose, v.Outcome, v.NextAt, cc.PresidingJudgeName
FROM (VALUES
    ('DEMO-CC-2025-0001', '2025-08-12T10:30:00', N'Preliminary hearing',        N'Accused appeared; matter listed for framing of charges.',         '2025-10-01T10:30:00'),
    ('DEMO-CC-2025-0001', '2025-10-01T10:30:00', N'Framing of charges',         N'Charges framed; prosecution evidence to begin.',                  '2025-11-20T10:30:00'),
    ('DEMO-CC-2025-0001', '2025-11-20T10:30:00', N'Judgment',                   N'Judgment pronounced after final arguments.',                      NULL),
    ('DEMO-CC-0007',      '2026-06-15T10:30:00', N'Preliminary hearing',        N'Matter listed for the next procedural step.',                     '2026-07-01T10:30:00'),
    ('DEMO-CC-0007',      '2026-07-01T10:30:00', N'Framing of charges',         N'Charges framed; trial dates fixed.',                              '2026-08-10T10:30:00'),
    ('DEMO-CC-0007',      '2026-08-10T10:30:00', N'Prosecution evidence',       N'First prosecution witness examined; evidence item produced.',     '2026-11-12T10:30:00'),
    ('DEMO-CC-0007',      '2026-11-12T10:30:00', N'Prosecution evidence',       NULL,                                                               NULL),
    ('DEMO-CC-0010',      '2026-05-20T10:30:00', N'Appearance of accused',      N'Accused appeared on bail; copies of documents supplied.',         '2026-06-25T10:30:00'),
    ('DEMO-CC-0010',      '2026-06-25T10:30:00', N'Framing of charges',         N'Charges framed; matter adjourned for prosecution evidence.',      '2026-11-20T10:30:00')
) AS v (CourtCaseNumber, HearingAt, Purpose, Outcome, NextAt)
JOIN dbo.CourtCases AS cc ON cc.CourtCaseNumber = v.CourtCaseNumber;

INSERT INTO dbo.CourtOrders (CourtCaseID, CourtHearingID, OrderReference, OrderDate, OrderType, OrderSummary, SecureDocumentReference)
SELECT cc.CourtCaseID, ch.CourtHearingID, v.OrderReference, v.OrderDate, v.OrderType, v.OrderSummary, v.DocRef
FROM (VALUES
    ('DEMO-CC-2025-0001', '2025-11-20T10:30:00', 'DEMO-ORDER-2025-0001', '2025-11-20', N'Judgment',          N'Sample judgment entry used only to show relationships.',     N'DEMO-COURT-ORDER-2025-0001'),
    ('DEMO-CC-0007',      '2026-06-15T10:30:00', 'DEMO-ORDER-0007',      '2026-06-15', N'Procedural Order',  N'Sample procedural order used to show relationships.',        N'DEMO-COURT-ORDER-0007'),
    ('DEMO-CC-0007',      '2026-07-01T10:30:00', 'DEMO-ORDER-0007-B',    '2026-07-01', N'Order on Charges',  N'Sample order recording that charges were framed.',           N'DEMO-COURT-ORDER-0007B'),
    ('DEMO-CC-0010',      '2026-06-25T10:30:00', 'DEMO-ORDER-0010',      '2026-06-25', N'Order on Charges',  N'Sample order recording that charges were framed.',           N'DEMO-COURT-ORDER-0010')
) AS v (CourtCaseNumber, HearingAt, OrderReference, OrderDate, OrderType, OrderSummary, DocRef)
JOIN dbo.CourtCases    AS cc ON cc.CourtCaseNumber = v.CourtCaseNumber
JOIN dbo.CourtHearings AS ch ON ch.CourtCaseID = cc.CourtCaseID AND ch.HearingDateTime = v.HearingAt;

INSERT INTO dbo.BailOrders
    (ArrestID, CourtCaseID, OrderReference, DecisionDate, BailDecision, BailConditions, BondAmountINR, ReleaseEffectiveAt)
SELECT a.ArrestID, cc.CourtCaseID, v.OrderReference, v.DecisionDate, v.BailDecision, v.Conditions, v.BondAmount, v.ReleaseAt
FROM (VALUES
    ('DEMO-ARREST-0001', NULL,           'DEMO-BAIL-0007', '2026-04-04', N'Granted',  N'Sample conditions only; this is not legal advice.',            10000, '2026-04-04T17:00:00'),
    ('DEMO-ARREST-0004', 'DEMO-CC-0010', 'DEMO-BAIL-0010', '2026-05-04', N'Granted',  N'Sample conditions: report weekly and surrender the passport.',  25000, '2026-05-04T16:00:00'),
    ('DEMO-ARREST-0002', NULL,           'DEMO-BAIL-0001', '2026-01-25', N'Rejected', NULL,                                                              NULL, NULL)
) AS v (MemoReference, CourtCaseNumber, OrderReference, DecisionDate, BailDecision, Conditions, BondAmount, ReleaseAt)
JOIN dbo.Arrests AS a ON a.ArrestMemoReference = v.MemoReference
LEFT JOIN dbo.CourtCases AS cc ON cc.CourtCaseNumber = v.CourtCaseNumber;

INSERT INTO dbo.CaseOutcomes
    (CriminalCaseID, CourtCaseID, OutcomeDate, OutcomeType, OutcomeSummary, AppealFiled, AppealFiledDate)
SELECT c.CriminalCaseID, cc.CourtCaseID, v.OutcomeDate, v.OutcomeType, v.OutcomeSummary, v.AppealFiled, v.AppealFiledDate
FROM (VALUES
    ('CICMS-2025-0001', 'DEMO-CC-2025-0001', '2025-11-20', N'Conviction',              N'Sample outcome entry for the legacy warehouse case; not a real judgment.', 1, '2025-12-10'),
    ('CICMS-2025-0002', NULL,                '2025-12-30', N'Closure Report Accepted', N'Matter closed after the closure report was accepted (sample entry).',       0, NULL),
    ('CICMS-2026-0009', NULL,                '2026-05-30', N'Compounded',              N'Parties settled the minor property damage matter (sample entry).',          0, NULL)
) AS v (CaseNumber, CourtCaseNumber, OutcomeDate, OutcomeType, OutcomeSummary, AppealFiled, AppealFiledDate)
JOIN dbo.CriminalCases AS c ON c.CaseNumber = v.CaseNumber
LEFT JOIN dbo.CourtCases AS cc ON cc.CourtCaseNumber = v.CourtCaseNumber;

INSERT INTO dbo.VictimSupportServices
    (CriminalCaseID, VictimPersonID, ServiceType, ReferredByOfficerID, ReferralDate, ServiceProviderName, ServiceStatus, FollowUpDate, ServiceNotes)
SELECT c.CriminalCaseID, p.PersonID, v.ServiceType, o.PoliceOfficerID, v.ReferralDate, v.Provider, v.ServiceStatus, v.FollowUpDate, v.Notes
FROM (VALUES
    ('CICMS-2026-0006', N'Neha',    N'Singh',   N'Information and referral support',   'DEMO-1003', '2026-03-22', N'Demo Victim Support Desk',   N'Accepted',          '2026-04-05', N'Referral only; no sensitive details stored here.'),
    ('CICMS-2026-0001', N'Ananya',  N'Reddy',   N'Help with blocking the lost phone',  'DEMO-1001', '2026-01-13', N'Demo Victim Support Desk',   N'Completed',         NULL,         N'Service finished within a day.'),
    ('CICMS-2026-0007', N'Mohan',   N'Das',     N'Information on vehicle release',     'DEMO-1005', '2026-04-05', N'Demo Legal Aid Cell',        N'Completed',         NULL,         N'Handover completed.'),
    ('CICMS-2026-0011', N'Sunitha', N'Varma',   N'Counselling and legal aid referral', 'DEMO-1001', '2026-08-13', N'Demo Women''s Support Centre',N'Referred',          '2026-09-01', N'Waiting for the centre to confirm an appointment.'),
    ('CICMS-2026-0009', N'Nisha',   N'Patel',   N'Compensation information',           'DEMO-1002', '2026-04-20', N'Demo Victim Support Desk',   N'Declined',          NULL,         N'Victim chose not to take up the service.'),
    ('CICMS-2026-0005', N'Swathi',  N'Reddy',   N'Account recovery guidance',          'DEMO-1002', '2026-03-16', N'Demo Cyber Help Desk',       N'Unable To Contact', '2026-04-10', N'Two follow-up calls went unanswered.')
) AS v (CaseNumber, GivenName, FamilyName, ServiceType, ServiceNumber, ReferralDate, Provider, ServiceStatus, FollowUpDate, Notes)
JOIN dbo.CriminalCases  AS c ON c.CaseNumber    = v.CaseNumber
JOIN dbo.Persons        AS p ON p.GivenName = v.GivenName AND p.FamilyName = v.FamilyName
JOIN dbo.PoliceOfficers AS o ON o.ServiceNumber = v.ServiceNumber;

-- ---------- Users, roles and audit trail ----------
-- The hash values are throw-away SHA-256 digests of demo text. They are NOT a safe way to store passwords.
INSERT INTO dbo.SystemUsers (PoliceOfficerID, Username, PasswordHash, IsEnabled, LastLoginAt)
SELECT o.PoliceOfficerID, v.Username, v.PasswordHash, v.IsEnabled, v.LastLoginAt
FROM (VALUES
    ('DEMO-1008', N'demo.admin',      0x8EB1D3818D825B5BCE7CF0B2F0716F0E01D021FDB356737DFA258E788E5281AB,      1, '2026-10-20T09:00:00'),
    ('DEMO-1001', N'demo.arjun',      0x67F0943BB12872DF802C530245B0A5A708FFEB7D4C128AB1FB03CE28B796035F,      1, '2026-10-22T10:00:00'),
    ('DEMO-1002', N'demo.priya',      0x617C84D7382022CEA532A96EF6E45C03BAF64E3A77EC51C80B6857453FFCB1E5,      1, NULL),
    ('DEMO-1003', N'demo.karthik',    0x8A8235C17779B54B429A9292932EFEA53843550C4A7132BF7685F28FFDE7C598,    1, '2026-10-21T14:30:00'),
    (NULL,        N'demo.auditor',    0xC1B51F6EA75D96E87059D6C9D66AF9F63A87D12EAC3942D52D7208AC388E09F8,    1, '2026-09-30T11:15:00'),
    (NULL,        N'demo.forensics',  0x1F8DE6D1274A3C4C906F5747D8890ADD0BAD8C4F1CF7E02168F429B496EF71AB,  1, '2026-10-15T08:45:00'),
    (NULL,        N'demo.prosecutor', 0x8AF264E506DE7039D7A81CD548E3C408E38E78B335D576C4212D415F0B1243C1, 1, '2026-10-18T16:20:00'),
    ('DEMO-1010', N'demo.retired',    0x8392E62FEA5B2DD3B0AFED6ECE851B9A432A8F0ABA53D6F4C40133E299686C0D,    0, '2025-06-28T17:00:00'),
    (NULL,        N'demo.newuser',    0x5D96970AD5B648043E4FD83C42D92B895307BA26D9FB48DF260D6A47B348D289,    1, NULL)
) AS v (ServiceNumber, Username, PasswordHash, IsEnabled, LastLoginAt)
LEFT JOIN dbo.PoliceOfficers AS o ON o.ServiceNumber = v.ServiceNumber;

INSERT INTO dbo.SystemUserRoles (SystemUserID, SystemRoleID, GrantedAt, GrantedByUserID)
SELECT u.SystemUserID, r.SystemRoleID, v.GrantedAt, adm.SystemUserID
FROM (VALUES
    (N'demo.admin',      N'Administrator',         '2025-01-01T09:00:00'),
    (N'demo.arjun',      N'Investigating Officer', '2025-01-05T09:00:00'),
    (N'demo.priya',      N'Station Officer',       '2025-01-05T09:10:00'),
    (N'demo.karthik',    N'Investigating Officer', '2025-02-01T10:00:00'),
    (N'demo.karthik',    N'Station Officer',       '2025-06-01T10:00:00'),
    (N'demo.auditor',    N'Read Only Auditor',     '2025-03-01T10:00:00'),
    (N'demo.forensics',  N'Forensic Examiner',     '2025-03-01T10:30:00'),
    (N'demo.prosecutor', N'Prosecutor',            '2025-03-01T11:00:00'),
    (N'demo.retired',    N'Investigating Officer', '2024-01-10T09:00:00')
) AS v (Username, RoleName, GrantedAt)
JOIN dbo.SystemUsers AS u   ON u.Username = v.Username
JOIN dbo.SystemRoles AS r   ON r.RoleName = v.RoleName
JOIN dbo.SystemUsers AS adm ON adm.Username = N'demo.admin';

INSERT INTO dbo.AuditLog (SystemUserID, EventAt, EntityName, EntityRecordID, ActionType, ActionSummary, ClientAddress)
SELECT u.SystemUserID, v.EventAt, v.EntityName, v.RecordID, v.ActionType, v.Summary, v.ClientAddress
FROM (VALUES
    (N'demo.arjun',   '2026-10-22T10:00:00', N'Session',          NULL,              N'LOGIN',  N'Signed in',                                   N'192.0.2.10'),
    (N'demo.arjun',   '2026-10-22T10:05:00', N'CriminalCases',    N'CICMS-2026-0001',N'VIEW',   N'Opened the case file',                        N'192.0.2.10'),
    (N'demo.arjun',   '2026-10-22T10:20:00', N'CaseDiaryEntries', N'CICMS-2026-0001',N'INSERT', N'Added diary entry 3',                         N'192.0.2.10'),
    (N'demo.arjun',   '2026-10-22T11:10:00', N'Session',          NULL,              N'LOGOUT', N'Signed out',                                  N'192.0.2.10'),
    (N'demo.karthik', '2026-10-21T14:30:00', N'Session',          NULL,              N'LOGIN',  N'Signed in',                                   N'192.0.2.11'),
    (N'demo.karthik', '2026-10-21T14:40:00', N'Complaints',       N'CMP-2026-0002',  N'UPDATE', N'Updated complaint status',                    N'192.0.2.11'),
    (N'demo.karthik', '2026-10-21T15:05:00', N'EvidenceItems',    N'EX-0003',        N'VIEW',   N'Viewed evidence item',                        N'192.0.2.11'),
    (N'demo.admin',   '2026-10-20T09:00:00', N'Session',          NULL,              N'LOGIN',  N'Signed in',                                   N'192.0.2.1'),
    (N'demo.admin',   '2026-10-20T09:30:00', N'SystemUsers',      N'demo.newuser',   N'INSERT', N'Created a new user account',                  N'192.0.2.1'),
    (N'demo.auditor', '2026-09-30T11:15:00', N'AuditLog',         NULL,              N'EXPORT', N'Exported the audit trail for review',         N'192.0.2.20'),
    (N'demo.forensics','2026-10-15T08:45:00',N'ForensicReports',  N'DEMO-FR-0003',   N'UPDATE', N'Moved a report to peer review',               N'192.0.2.30'),
    (N'demo.prosecutor','2026-10-18T16:20:00',N'CourtCases',      N'DEMO-CC-0007',   N'VIEW',   N'Viewed the court case record',                N'192.0.2.40')
) AS v (Username, EventAt, EntityName, RecordID, ActionType, Summary, ClientAddress)
JOIN dbo.SystemUsers AS u ON u.Username = v.Username;
GO


-- Quick look at what was loaded (not one of the 400 queries)
SELECT t.name AS TableName, SUM(p.rows) AS TotalRows
FROM sys.tables AS t
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY t.name;
GO

-- =====================================================================
-- STEP 7: THE 400 QUERIES
-- =====================================================================
-- ANSI_WARNINGS is switched off only so the harmless "NULL value is eliminated by an
-- aggregate" notice does not clutter the Messages tab. It is switched back on at the end.
SET ANSI_WARNINGS OFF;
GO


-- ---------------------------------------------------------------------
-- Display the data in every table and the view (Queries 1-50)
-- ---------------------------------------------------------------------

-- Query 1: Display all states
PRINT 'Query 1: Display all states';
SELECT *
FROM dbo.States;
GO

-- Query 2: Display all districts
PRINT 'Query 2: Display all districts';
SELECT *
FROM dbo.Districts;
GO

-- Query 3: Display all police stations
PRINT 'Query 3: Display all police stations';
SELECT *
FROM dbo.PoliceStations;
GO

-- Query 4: Display all police units
PRINT 'Query 4: Display all police units';
SELECT *
FROM dbo.PoliceUnits;
GO

-- Query 5: Display all police ranks
PRINT 'Query 5: Display all police ranks';
SELECT *
FROM dbo.PoliceRanks;
GO

-- Query 6: Display all police officers
PRINT 'Query 6: Display all police officers';
SELECT *
FROM dbo.PoliceOfficers;
GO

-- Query 7: Display all officer assignments
PRINT 'Query 7: Display all officer assignments';
SELECT *
FROM dbo.OfficerAssignments;
GO

-- Query 8: Display all persons
PRINT 'Query 8: Display all persons';
SELECT *
FROM dbo.Persons;
GO

-- Query 9: Display all person addresses
PRINT 'Query 9: Display all person addresses';
SELECT *
FROM dbo.PersonAddresses;
GO

-- Query 10: Display all person contact methods
PRINT 'Query 10: Display all person contact methods';
SELECT *
FROM dbo.PersonContactMethods;
GO

-- Query 11: Display all person identifiers
PRINT 'Query 11: Display all person identifiers';
SELECT *
FROM dbo.PersonIdentifiers;
GO

-- Query 12: Display all complaint sources
PRINT 'Query 12: Display all complaint sources';
SELECT *
FROM dbo.ComplaintSources;
GO

-- Query 13: Display all complaints
PRINT 'Query 13: Display all complaints';
SELECT *
FROM dbo.Complaints;
GO

-- Query 14: Display all complaint updates
PRINT 'Query 14: Display all complaint updates';
SELECT *
FROM dbo.ComplaintUpdates;
GO

-- Query 15: Display all crime categories
PRINT 'Query 15: Display all crime categories';
SELECT *
FROM dbo.CrimeCategories;
GO

-- Query 16: Display all legal provisions
PRINT 'Query 16: Display all legal provisions';
SELECT *
FROM dbo.LegalProvisions;
GO

-- Query 17: Display all criminal cases
PRINT 'Query 17: Display all criminal cases';
SELECT *
FROM dbo.CriminalCases;
GO

-- Query 18: Display all case offences
PRINT 'Query 18: Display all case offences';
SELECT *
FROM dbo.CaseOffences;
GO

-- Query 19: Display all case person roles
PRINT 'Query 19: Display all case person roles';
SELECT *
FROM dbo.CasePersonRoles;
GO

-- Query 20: Display all investigation assignments
PRINT 'Query 20: Display all investigation assignments';
SELECT *
FROM dbo.InvestigationAssignments;
GO

-- Query 21: Display all case diary entries
PRINT 'Query 21: Display all case diary entries';
SELECT *
FROM dbo.CaseDiaryEntries;
GO

-- Query 22: Display all investigation activities
PRINT 'Query 22: Display all investigation activities';
SELECT *
FROM dbo.InvestigationActivities;
GO

-- Query 23: Display all witness statements
PRINT 'Query 23: Display all witness statements';
SELECT *
FROM dbo.WitnessStatements;
GO

-- Query 24: Display all interviews
PRINT 'Query 24: Display all interviews';
SELECT *
FROM dbo.Interviews;
GO

-- Query 25: Display all arrests
PRINT 'Query 25: Display all arrests';
SELECT *
FROM dbo.Arrests;
GO

-- Query 26: Display all custody records
PRINT 'Query 26: Display all custody records';
SELECT *
FROM dbo.CustodyRecords;
GO

-- Query 27: Display all search authorizations
PRINT 'Query 27: Display all search authorizations';
SELECT *
FROM dbo.SearchAuthorizations;
GO

-- Query 28: Display all search operations
PRINT 'Query 28: Display all search operations';
SELECT *
FROM dbo.SearchOperations;
GO

-- Query 29: Display all evidence types
PRINT 'Query 29: Display all evidence types';
SELECT *
FROM dbo.EvidenceTypes;
GO

-- Query 30: Display all evidence items
PRINT 'Query 30: Display all evidence items';
SELECT *
FROM dbo.EvidenceItems;
GO

-- Query 31: Display all evidence custody transfers
PRINT 'Query 31: Display all evidence custody transfers';
SELECT *
FROM dbo.EvidenceCustodyTransfers;
GO

-- Query 32: Display all forensic laboratories
PRINT 'Query 32: Display all forensic laboratories';
SELECT *
FROM dbo.ForensicLaboratories;
GO

-- Query 33: Display all forensic requests
PRINT 'Query 33: Display all forensic requests';
SELECT *
FROM dbo.ForensicRequests;
GO

-- Query 34: Display all forensic reports
PRINT 'Query 34: Display all forensic reports';
SELECT *
FROM dbo.ForensicReports;
GO

-- Query 35: Display all stolen properties
PRINT 'Query 35: Display all stolen properties';
SELECT *
FROM dbo.StolenProperties;
GO

-- Query 36: Display all property recoveries
PRINT 'Query 36: Display all property recoveries';
SELECT *
FROM dbo.PropertyRecoveries;
GO

-- Query 37: Display all missing person reports
PRINT 'Query 37: Display all missing person reports';
SELECT *
FROM dbo.MissingPersonReports;
GO

-- Query 38: Display all charge sheets
PRINT 'Query 38: Display all charge sheets';
SELECT *
FROM dbo.ChargeSheets;
GO

-- Query 39: Display all prosecution teams
PRINT 'Query 39: Display all prosecution teams';
SELECT *
FROM dbo.ProsecutionTeams;
GO

-- Query 40: Display all court cases
PRINT 'Query 40: Display all court cases';
SELECT *
FROM dbo.CourtCases;
GO

-- Query 41: Display all court hearings
PRINT 'Query 41: Display all court hearings';
SELECT *
FROM dbo.CourtHearings;
GO

-- Query 42: Display all court orders
PRINT 'Query 42: Display all court orders';
SELECT *
FROM dbo.CourtOrders;
GO

-- Query 43: Display all bail orders
PRINT 'Query 43: Display all bail orders';
SELECT *
FROM dbo.BailOrders;
GO

-- Query 44: Display all case outcomes
PRINT 'Query 44: Display all case outcomes';
SELECT *
FROM dbo.CaseOutcomes;
GO

-- Query 45: Display all victim support services
PRINT 'Query 45: Display all victim support services';
SELECT *
FROM dbo.VictimSupportServices;
GO

-- Query 46: Display system users (password hashes left out on purpose)
PRINT 'Query 46: Display system users (password hashes left out on purpose)';
SELECT SystemUserID, PoliceOfficerID, Username, IsEnabled, CreatedAt, LastLoginAt
FROM dbo.SystemUsers;
GO

-- Query 47: Display all system roles
PRINT 'Query 47: Display all system roles';
SELECT *
FROM dbo.SystemRoles;
GO

-- Query 48: Display all system user roles
PRINT 'Query 48: Display all system user roles';
SELECT *
FROM dbo.SystemUserRoles;
GO

-- Query 49: Display all audit log
PRINT 'Query 49: Display all audit log';
SELECT *
FROM dbo.AuditLog;
GO

-- Query 50: Display the case register summary view
PRINT 'Query 50: Display the case register summary view';
SELECT *
FROM dbo.vw_CaseRegisterSummary;
GO


-- ---------------------------------------------------------------------
-- Filtering data with WHERE (Queries 51-110)
-- ---------------------------------------------------------------------

-- Query 51: Active police stations
PRINT 'Query 51: Active police stations';
SELECT PoliceStationName, StationCode, ContactPhone, EmailAddress
FROM dbo.PoliceStations
WHERE IsActive = 1;
GO

-- Query 52: Inactive police stations
PRINT 'Query 52: Inactive police stations';
SELECT PoliceStationName, StationCode, StationAddress
FROM dbo.PoliceStations
WHERE IsActive = 0;
GO

-- Query 53: Police stations whose address mentions Hyderabad
PRINT 'Query 53: Police stations whose address mentions Hyderabad';
SELECT PoliceStationName, StationAddress
FROM dbo.PoliceStations
WHERE StationAddress LIKE N'%Hyderabad%';
GO

-- Query 54: Active police officers
PRINT 'Query 54: Active police officers';
SELECT ServiceNumber, FirstName, LastName, WorkEmail
FROM dbo.PoliceOfficers
WHERE IsActive = 1;
GO

-- Query 55: Inactive police officers
PRINT 'Query 55: Inactive police officers';
SELECT ServiceNumber, FirstName, LastName
FROM dbo.PoliceOfficers
WHERE IsActive = 0;
GO

-- Query 56: Officers who joined in 2019 or later
PRINT 'Query 56: Officers who joined in 2019 or later';
SELECT ServiceNumber, FirstName, LastName, DateOfJoining
FROM dbo.PoliceOfficers
WHERE DateOfJoining >= '2019-01-01';
GO

-- Query 57: Officers who joined before 2018
PRINT 'Query 57: Officers who joined before 2018';
SELECT ServiceNumber, FirstName, LastName, DateOfJoining
FROM dbo.PoliceOfficers
WHERE DateOfJoining < '2018-01-01';
GO

-- Query 58: Officers with no work email recorded
PRINT 'Query 58: Officers with no work email recorded';
SELECT ServiceNumber, FirstName, LastName
FROM dbo.PoliceOfficers
WHERE WorkEmail IS NULL;
GO

-- Query 59: Officers with no joining date recorded
PRINT 'Query 59: Officers with no joining date recorded';
SELECT ServiceNumber, FirstName, LastName
FROM dbo.PoliceOfficers
WHERE DateOfJoining IS NULL;
GO

-- Query 60: Officers whose first name starts with P
PRINT 'Query 60: Officers whose first name starts with P';
SELECT ServiceNumber, FirstName, LastName
FROM dbo.PoliceOfficers
WHERE FirstName LIKE N'P%';
GO

-- Query 61: Officers whose surname ends with a
PRINT 'Query 61: Officers whose surname ends with a';
SELECT ServiceNumber, FirstName, LastName
FROM dbo.PoliceOfficers
WHERE LastName LIKE N'%a';
GO

-- Query 62: High or critical urgency complaints
PRINT 'Query 62: High or critical urgency complaints';
SELECT ComplaintNumber, ComplaintSummary, UrgencyLevel, ComplaintStatus
FROM dbo.Complaints
WHERE UrgencyLevel IN (N'High', N'Critical');
GO

-- Query 63: Anonymous complaints
PRINT 'Query 63: Anonymous complaints';
SELECT ComplaintNumber, ComplaintSummary, ReceivedAt
FROM dbo.Complaints
WHERE IsAnonymous = 1;
GO

-- Query 64: Complaints received in March 2026
PRINT 'Query 64: Complaints received in March 2026';
SELECT ComplaintNumber, ComplaintSummary, ReceivedAt
FROM dbo.Complaints
WHERE ReceivedAt >= '2026-03-01' AND ReceivedAt < '2026-04-01';
GO

-- Query 65: Complaints still under review
PRINT 'Query 65: Complaints still under review';
SELECT ComplaintNumber, ComplaintSummary, ReceivedAt
FROM dbo.Complaints
WHERE ComplaintStatus = N'Under Review';
GO

-- Query 66: Complaints with no assigned officer
PRINT 'Query 66: Complaints with no assigned officer';
SELECT ComplaintNumber, ComplaintSummary, ComplaintStatus
FROM dbo.Complaints
WHERE AssignedOfficerID IS NULL;
GO

-- Query 67: Complaints with no detailed narrative
PRINT 'Query 67: Complaints with no detailed narrative';
SELECT ComplaintNumber, ComplaintSummary
FROM dbo.Complaints
WHERE ComplaintDetails IS NULL;
GO

-- Query 68: Complaints whose summary mentions fraud
PRINT 'Query 68: Complaints whose summary mentions fraud';
SELECT ComplaintNumber, ComplaintSummary
FROM dbo.Complaints
WHERE ComplaintSummary LIKE N'%fraud%';
GO

-- Query 69: Complaints that are neither closed nor declined
PRINT 'Query 69: Complaints that are neither closed nor declined';
SELECT ComplaintNumber, ComplaintSummary, ComplaintStatus
FROM dbo.Complaints
WHERE ComplaintStatus NOT IN (N'Closed', N'Declined');
GO

-- Query 70: Complaints that arrived through the online portal
PRINT 'Query 70: Complaints that arrived through the online portal';
SELECT ComplaintNumber, ComplaintSummary, ReceivedAt
FROM dbo.Complaints
WHERE ComplaintSourceID = (SELECT ComplaintSourceID FROM dbo.ComplaintSources WHERE SourceName = N'Online Portal');
GO

-- Query 71: Cases under investigation
PRINT 'Query 71: Cases under investigation';
SELECT CaseNumber, CaseTitle, OpenedAt
FROM dbo.CriminalCases
WHERE CaseStatus = N'Under Investigation';
GO

-- Query 72: High or critical priority cases
PRINT 'Query 72: High or critical priority cases';
SELECT CaseNumber, CaseTitle, CasePriority
FROM dbo.CriminalCases
WHERE CasePriority IN (N'High', N'Critical');
GO

-- Query 73: Sensitive cases
PRINT 'Query 73: Sensitive cases';
SELECT CaseNumber, CaseTitle, CaseStatus
FROM dbo.CriminalCases
WHERE IsSensitiveCase = 1;
GO

-- Query 74: Cases that have no FIR number yet
PRINT 'Query 74: Cases that have no FIR number yet';
SELECT CaseNumber, CaseTitle, CaseStatus
FROM dbo.CriminalCases
WHERE FIRNumber IS NULL;
GO

-- Query 75: Cases opened in April 2026
PRINT 'Query 75: Cases opened in April 2026';
SELECT CaseNumber, CaseTitle, OpenedAt
FROM dbo.CriminalCases
WHERE OpenedAt >= '2026-04-01' AND OpenedAt < '2026-05-01';
GO

-- Query 76: Cases opened in the first quarter of 2026
PRINT 'Query 76: Cases opened in the first quarter of 2026';
SELECT CaseNumber, CaseTitle, OpenedAt
FROM dbo.CriminalCases
WHERE OpenedAt >= '2026-01-01' AND OpenedAt < '2026-04-01';
GO

-- Query 77: Closed or disposed cases
PRINT 'Query 77: Closed or disposed cases';
SELECT CaseNumber, CaseTitle, CaseStatus, ClosedAt
FROM dbo.CriminalCases
WHERE CaseStatus IN (N'Closed', N'Disposed');
GO

-- Query 78: Cases that have a closure date
PRINT 'Query 78: Cases that have a closure date';
SELECT CaseNumber, CaseStatus, OpenedAt, ClosedAt
FROM dbo.CriminalCases
WHERE ClosedAt IS NOT NULL;
GO

-- Query 79: Cases that are still open (no closure date)
PRINT 'Query 79: Cases that are still open (no closure date)';
SELECT CaseNumber, CaseTitle, CaseStatus
FROM dbo.CriminalCases
WHERE ClosedAt IS NULL;
GO

-- Query 80: Critical priority cases only
PRINT 'Query 80: Critical priority cases only';
SELECT CaseNumber, CaseTitle
FROM dbo.CriminalCases
WHERE CasePriority = N'Critical';
GO

-- Query 81: Cases that are not low priority
PRINT 'Query 81: Cases that are not low priority';
SELECT CaseNumber, CaseTitle, CasePriority
FROM dbo.CriminalCases
WHERE CasePriority <> N'Low';
GO

-- Query 82: Case titles containing the word reported
PRINT 'Query 82: Case titles containing the word reported';
SELECT CaseNumber, CaseTitle
FROM dbo.CriminalCases
WHERE CaseTitle LIKE N'%reported%';
GO

-- Query 83: Legacy 2025 case numbers
PRINT 'Query 83: Legacy 2025 case numbers';
SELECT CaseNumber, CaseTitle, CaseStatus
FROM dbo.CriminalCases
WHERE CaseNumber LIKE 'CICMS-2025-%';
GO

-- Query 84: Incidents that lasted more than an hour
PRINT 'Query 84: Incidents that lasted more than an hour';
SELECT CaseNumber, IncidentStartAt, IncidentEndAt
FROM dbo.CriminalCases
WHERE DATEDIFF(minute, IncidentStartAt, IncidentEndAt) > 60;
GO

-- Query 85: People whose preferred language is Telugu
PRINT 'Query 85: People whose preferred language is Telugu';
SELECT GivenName, FamilyName, PreferredLanguage
FROM dbo.Persons
WHERE PreferredLanguage = N'Telugu';
GO

-- Query 86: People born in 1996 or later
PRINT 'Query 86: People born in 1996 or later';
SELECT GivenName, FamilyName, DateOfBirth
FROM dbo.Persons
WHERE DateOfBirth >= '1996-01-01';
GO

-- Query 87: People with no date of birth on record
PRINT 'Query 87: People with no date of birth on record';
SELECT PersonID, GivenName, FamilyName, PersonNotes
FROM dbo.Persons
WHERE DateOfBirth IS NULL;
GO

-- Query 88: People whose given name starts with A
PRINT 'Query 88: People whose given name starts with A';
SELECT GivenName, FamilyName
FROM dbo.Persons
WHERE GivenName LIKE N'A%';
GO

-- Query 89: People whose family name contains the letter r
PRINT 'Query 89: People whose family name contains the letter r';
SELECT GivenName, FamilyName
FROM dbo.Persons
WHERE FamilyName LIKE N'%r%';
GO

-- Query 90: People whose given name contains an
PRINT 'Query 90: People whose given name contains an';
SELECT GivenName, FamilyName
FROM dbo.Persons
WHERE GivenName LIKE N'%an%';
GO

-- Query 91: People who have a language recorded
PRINT 'Query 91: People who have a language recorded';
SELECT GivenName, FamilyName, PreferredLanguage
FROM dbo.Persons
WHERE PreferredLanguage IS NOT NULL;
GO

-- Query 92: Case roles recorded as Witness
PRINT 'Query 92: Case roles recorded as Witness';
SELECT CriminalCaseID, PersonID, CaseRole
FROM dbo.CasePersonRoles
WHERE CaseRole = N'Witness';
GO

-- Query 93: Case roles recorded as Suspect
PRINT 'Query 93: Case roles recorded as Suspect';
SELECT CriminalCaseID, PersonID, CaseRole
FROM dbo.CasePersonRoles
WHERE CaseRole = N'Suspect';
GO

-- Query 94: Case roles recorded as Victim
PRINT 'Query 94: Case roles recorded as Victim';
SELECT CriminalCaseID, PersonID, CaseRole
FROM dbo.CasePersonRoles
WHERE CaseRole = N'Victim';
GO

-- Query 95: Case roles recorded as Accused
PRINT 'Query 95: Case roles recorded as Accused';
SELECT CriminalCaseID, PersonID, CaseRole
FROM dbo.CasePersonRoles
WHERE CaseRole = N'Accused';
GO

-- Query 96: Case roles where identity is not yet verified
PRINT 'Query 96: Case roles where identity is not yet verified';
SELECT CriminalCaseID, PersonID, CaseRole
FROM dbo.CasePersonRoles
WHERE IsIdentityVerified = 0;
GO

-- Query 97: Evidence kept in a locker
PRINT 'Query 97: Evidence kept in a locker';
SELECT ExhibitNumber, EvidenceDescription, StorageLocation
FROM dbo.EvidenceItems
WHERE StorageLocation LIKE N'%Locker%';
GO

-- Query 98: Digital evidence items
PRINT 'Query 98: Digital evidence items';
SELECT ExhibitNumber, EvidenceDescription, SecureFileReference
FROM dbo.EvidenceItems
WHERE IsDigitalEvidence = 1;
GO

-- Query 99: Evidence currently with a forensic laboratory
PRINT 'Query 99: Evidence currently with a forensic laboratory';
SELECT ExhibitNumber, EvidenceDescription, EvidenceStatus
FROM dbo.EvidenceItems
WHERE EvidenceStatus = N'Sent for Forensics';
GO

-- Query 100: Evidence that has a SHA-256 hash recorded
PRINT 'Query 100: Evidence that has a SHA-256 hash recorded';
SELECT ExhibitNumber, DigitalFileHashSHA256
FROM dbo.EvidenceItems
WHERE DigitalFileHashSHA256 IS NOT NULL;
GO

-- Query 101: Evidence without a seal number
PRINT 'Query 101: Evidence without a seal number';
SELECT ExhibitNumber, EvidenceDescription, InitialCondition
FROM dbo.EvidenceItems
WHERE SealNumber IS NULL;
GO

-- Query 102: Evidence without a storage location
PRINT 'Query 102: Evidence without a storage location';
SELECT ExhibitNumber, EvidenceDescription, EvidenceStatus
FROM dbo.EvidenceItems
WHERE StorageLocation IS NULL;
GO

-- Query 103: Completed forensic requests
PRINT 'Query 103: Completed forensic requests';
SELECT ForensicRequestID, ExaminationType, RequestedAt, CompletedAt
FROM dbo.ForensicRequests
WHERE RequestStatus = N'Completed';
GO

-- Query 104: Forensic requests still in progress
PRINT 'Query 104: Forensic requests still in progress';
SELECT ForensicRequestID, ExaminationType, RequestedAt
FROM dbo.ForensicRequests
WHERE RequestStatus = N'In Progress';
GO

-- Query 105: Forensic reports marked Final
PRINT 'Query 105: Forensic reports marked Final';
SELECT ReportNumber, ReportIssuedAt, ExaminerName
FROM dbo.ForensicReports
WHERE ReportStatus = N'Final';
GO

-- Query 106: Arrests where the person was later bailed
PRINT 'Query 106: Arrests where the person was later bailed';
SELECT ArrestMemoReference, ArrestedAt, ArrestStatus
FROM dbo.Arrests
WHERE ArrestStatus = N'Bailed';
GO

-- Query 107: Custody records that have ended
PRINT 'Query 107: Custody records that have ended';
SELECT CustodyRecordID, CustodyType, CustodyStartedAt, CustodyEndedAt
FROM dbo.CustodyRecords
WHERE CustodyEndedAt IS NOT NULL;
GO

-- Query 108: Court hearings on or after 1 June 2026
PRINT 'Query 108: Court hearings on or after 1 June 2026';
SELECT CourtHearingID, HearingDateTime, HearingPurpose
FROM dbo.CourtHearings
WHERE HearingDateTime >= '2026-06-01';
GO

-- Query 109: Court cases currently under trial
PRINT 'Query 109: Court cases currently under trial';
SELECT CourtCaseNumber, CourtName, CaseFiledAt
FROM dbo.CourtCases
WHERE CourtCaseStatus = N'Under Trial';
GO

-- Query 110: Bail orders where bail was granted
PRINT 'Query 110: Bail orders where bail was granted';
SELECT OrderReference, DecisionDate, BondAmountINR
FROM dbo.BailOrders
WHERE BailDecision = N'Granted';
GO


-- ---------------------------------------------------------------------
-- Counting and summarising with aggregate functions (Queries 111-160)
-- ---------------------------------------------------------------------

-- Query 111: Total number of criminal cases
PRINT 'Query 111: Total number of criminal cases';
SELECT COUNT(*) AS TotalCases
FROM dbo.CriminalCases;
GO

-- Query 112: Total number of complaints
PRINT 'Query 112: Total number of complaints';
SELECT COUNT(*) AS TotalComplaints
FROM dbo.Complaints;
GO

-- Query 113: Total number of people on record
PRINT 'Query 113: Total number of people on record';
SELECT COUNT(*) AS TotalPersons
FROM dbo.Persons;
GO

-- Query 114: Total number of officers
PRINT 'Query 114: Total number of officers';
SELECT COUNT(*) AS TotalOfficers
FROM dbo.PoliceOfficers;
GO

-- Query 115: Total number of evidence items
PRINT 'Query 115: Total number of evidence items';
SELECT COUNT(*) AS TotalEvidenceItems
FROM dbo.EvidenceItems;
GO

-- Query 116: Total number of forensic reports
PRINT 'Query 116: Total number of forensic reports';
SELECT COUNT(*) AS TotalForensicReports
FROM dbo.ForensicReports;
GO

-- Query 117: Total number of arrests
PRINT 'Query 117: Total number of arrests';
SELECT COUNT(*) AS TotalArrests
FROM dbo.Arrests;
GO

-- Query 118: Total number of court cases
PRINT 'Query 118: Total number of court cases';
SELECT COUNT(*) AS TotalCourtCases
FROM dbo.CourtCases;
GO

-- Query 119: Cases grouped by status
PRINT 'Query 119: Cases grouped by status';
SELECT CaseStatus, COUNT(*) AS CaseCount
FROM dbo.CriminalCases
GROUP BY CaseStatus
ORDER BY CaseCount DESC;
GO

-- Query 120: Cases grouped by priority
PRINT 'Query 120: Cases grouped by priority';
SELECT CasePriority, COUNT(*) AS CaseCount
FROM dbo.CriminalCases
GROUP BY CasePriority
ORDER BY CaseCount DESC;
GO

-- Query 121: Complaints grouped by status
PRINT 'Query 121: Complaints grouped by status';
SELECT ComplaintStatus, COUNT(*) AS ComplaintCount
FROM dbo.Complaints
GROUP BY ComplaintStatus
ORDER BY ComplaintCount DESC;
GO

-- Query 122: Complaints grouped by urgency
PRINT 'Query 122: Complaints grouped by urgency';
SELECT UrgencyLevel, COUNT(*) AS ComplaintCount
FROM dbo.Complaints
GROUP BY UrgencyLevel
ORDER BY ComplaintCount DESC;
GO

-- Query 123: People grouped by preferred language
PRINT 'Query 123: People grouped by preferred language';
SELECT PreferredLanguage, COUNT(*) AS PersonCount
FROM dbo.Persons
GROUP BY PreferredLanguage
ORDER BY PersonCount DESC;
GO

-- Query 124: Case roles grouped by role type
PRINT 'Query 124: Case roles grouped by role type';
SELECT CaseRole, COUNT(*) AS RoleCount
FROM dbo.CasePersonRoles
GROUP BY CaseRole
ORDER BY RoleCount DESC;
GO

-- Query 125: Evidence grouped by status
PRINT 'Query 125: Evidence grouped by status';
SELECT EvidenceStatus, COUNT(*) AS ItemCount
FROM dbo.EvidenceItems
GROUP BY EvidenceStatus
ORDER BY ItemCount DESC;
GO

-- Query 126: Evidence grouped by evidence type id
PRINT 'Query 126: Evidence grouped by evidence type id';
SELECT EvidenceTypeID, COUNT(*) AS ItemCount
FROM dbo.EvidenceItems
GROUP BY EvidenceTypeID
ORDER BY ItemCount DESC;
GO

-- Query 127: Forensic requests grouped by status
PRINT 'Query 127: Forensic requests grouped by status';
SELECT RequestStatus, COUNT(*) AS RequestCount
FROM dbo.ForensicRequests
GROUP BY RequestStatus;
GO

-- Query 128: Arrests grouped by status
PRINT 'Query 128: Arrests grouped by status';
SELECT ArrestStatus, COUNT(*) AS ArrestCount
FROM dbo.Arrests
GROUP BY ArrestStatus;
GO

-- Query 129: Court hearings counted per court case
PRINT 'Query 129: Court hearings counted per court case';
SELECT CourtCaseID, COUNT(*) AS HearingCount
FROM dbo.CourtHearings
GROUP BY CourtCaseID;
GO

-- Query 130: Stolen property grouped by recovery status
PRINT 'Query 130: Stolen property grouped by recovery status';
SELECT PropertyStatus, COUNT(*) AS ItemCount
FROM dbo.StolenProperties
GROUP BY PropertyStatus;
GO

-- Query 131: Average estimated value of stolen property
PRINT 'Query 131: Average estimated value of stolen property';
SELECT AVG(EstimatedValueINR) AS AverageValueINR
FROM dbo.StolenProperties
WHERE EstimatedValueINR IS NOT NULL;
GO

-- Query 132: Highest estimated value of stolen property
PRINT 'Query 132: Highest estimated value of stolen property';
SELECT MAX(EstimatedValueINR) AS HighestValueINR
FROM dbo.StolenProperties
WHERE EstimatedValueINR IS NOT NULL;
GO

-- Query 133: Lowest estimated value of stolen property
PRINT 'Query 133: Lowest estimated value of stolen property';
SELECT MIN(EstimatedValueINR) AS LowestValueINR
FROM dbo.StolenProperties
WHERE EstimatedValueINR IS NOT NULL;
GO

-- Query 134: Total estimated value of stolen property
PRINT 'Query 134: Total estimated value of stolen property';
SELECT SUM(EstimatedValueINR) AS TotalValueINR
FROM dbo.StolenProperties
WHERE EstimatedValueINR IS NOT NULL;
GO

-- Query 135: Average bail bond amount
PRINT 'Query 135: Average bail bond amount';
SELECT AVG(BondAmountINR) AS AverageBondINR
FROM dbo.BailOrders
WHERE BondAmountINR IS NOT NULL;
GO

-- Query 136: Highest bail bond amount
PRINT 'Query 136: Highest bail bond amount';
SELECT MAX(BondAmountINR) AS HighestBondINR
FROM dbo.BailOrders
WHERE BondAmountINR IS NOT NULL;
GO

-- Query 137: Total bail bond amount
PRINT 'Query 137: Total bail bond amount';
SELECT SUM(BondAmountINR) AS TotalBondINR
FROM dbo.BailOrders
WHERE BondAmountINR IS NOT NULL;
GO

-- Query 138: Officers grouped by rank id
PRINT 'Query 138: Officers grouped by rank id';
SELECT PoliceRankID, COUNT(*) AS OfficerCount
FROM dbo.PoliceOfficers
GROUP BY PoliceRankID
ORDER BY PoliceRankID;
GO

-- Query 139: Cases grouped by police station id
PRINT 'Query 139: Cases grouped by police station id';
SELECT PoliceStationID, COUNT(*) AS CaseCount
FROM dbo.CriminalCases
GROUP BY PoliceStationID
ORDER BY CaseCount DESC;
GO

-- Query 140: Police stations that have registered more than one case
PRINT 'Query 140: Police stations that have registered more than one case';
SELECT PoliceStationID, COUNT(*) AS CaseCount
FROM dbo.CriminalCases
GROUP BY PoliceStationID
HAVING COUNT(*) > 1;
GO

-- Query 141: Crime categories used in more than one offence entry
PRINT 'Query 141: Crime categories used in more than one offence entry';
SELECT CrimeCategoryID, COUNT(*) AS TimesUsed
FROM dbo.CaseOffences
GROUP BY CrimeCategoryID
HAVING COUNT(*) > 1;
GO

-- Query 142: People who hold more than one role across cases
PRINT 'Query 142: People who hold more than one role across cases';
SELECT PersonID, COUNT(*) AS RoleEntries
FROM dbo.CasePersonRoles
GROUP BY PersonID
HAVING COUNT(*) > 1
ORDER BY RoleEntries DESC;
GO

-- Query 143: Officers with more than one investigation assignment
PRINT 'Query 143: Officers with more than one investigation assignment';
SELECT PoliceOfficerID, COUNT(*) AS Assignments
FROM dbo.InvestigationAssignments
GROUP BY PoliceOfficerID
HAVING COUNT(*) > 1
ORDER BY Assignments DESC;
GO

-- Query 144: Cases that have more than one evidence item
PRINT 'Query 144: Cases that have more than one evidence item';
SELECT CriminalCaseID, COUNT(*) AS EvidenceCount
FROM dbo.EvidenceItems
GROUP BY CriminalCaseID
HAVING COUNT(*) > 1;
GO

-- Query 145: Cases with more than one diary entry
PRINT 'Query 145: Cases with more than one diary entry';
SELECT CriminalCaseID, COUNT(*) AS DiaryEntries
FROM dbo.CaseDiaryEntries
GROUP BY CriminalCaseID
HAVING COUNT(*) > 1;
GO

-- Query 146: Average length of investigation activities in minutes
PRINT 'Query 146: Average length of investigation activities in minutes';
SELECT AVG(DATEDIFF(minute, ActivityStartedAt, ActivityEndedAt) * 1.0) AS AverageMinutes
FROM dbo.InvestigationActivities
WHERE ActivityEndedAt IS NOT NULL;
GO

-- Query 147: Earliest complaint received
PRINT 'Query 147: Earliest complaint received';
SELECT MIN(ReceivedAt) AS EarliestComplaint
FROM dbo.Complaints;
GO

-- Query 148: Latest complaint received
PRINT 'Query 148: Latest complaint received';
SELECT MAX(ReceivedAt) AS LatestComplaint
FROM dbo.Complaints;
GO

-- Query 149: Earliest case opened
PRINT 'Query 149: Earliest case opened';
SELECT MIN(OpenedAt) AS EarliestCaseOpened
FROM dbo.CriminalCases;
GO

-- Query 150: Latest case opened
PRINT 'Query 150: Latest case opened';
SELECT MAX(OpenedAt) AS LatestCaseOpened
FROM dbo.CriminalCases;
GO

-- Query 151: Number of different complaint sources actually used
PRINT 'Query 151: Number of different complaint sources actually used';
SELECT COUNT(DISTINCT ComplaintSourceID) AS SourcesUsed
FROM dbo.Complaints;
GO

-- Query 152: Bail orders and total bond by decision
PRINT 'Query 152: Bail orders and total bond by decision';
SELECT BailDecision, COUNT(*) AS OrderCount, SUM(ISNULL(BondAmountINR, 0)) AS TotalBondINR
FROM dbo.BailOrders
GROUP BY BailDecision;
GO

-- Query 153: Average stolen property value by category
PRINT 'Query 153: Average stolen property value by category';
SELECT PropertyCategory, COUNT(*) AS ItemCount, AVG(EstimatedValueINR) AS AverageValueINR
FROM dbo.StolenProperties
WHERE EstimatedValueINR IS NOT NULL
GROUP BY PropertyCategory
ORDER BY AverageValueINR DESC;
GO

-- Query 154: Cases opened per year
PRINT 'Query 154: Cases opened per year';
SELECT YEAR(OpenedAt) AS OpenedYear, COUNT(*) AS CaseCount
FROM dbo.CriminalCases
GROUP BY YEAR(OpenedAt)
ORDER BY OpenedYear;
GO

-- Query 155: Digital versus physical evidence
PRINT 'Query 155: Digital versus physical evidence';
SELECT IsDigitalEvidence, COUNT(*) AS ItemCount
FROM dbo.EvidenceItems
GROUP BY IsDigitalEvidence;
GO

-- Query 156: Evidence count by case and status
PRINT 'Query 156: Evidence count by case and status';
SELECT CriminalCaseID, EvidenceStatus, COUNT(*) AS ItemCount
FROM dbo.EvidenceItems
GROUP BY CriminalCaseID, EvidenceStatus
ORDER BY CriminalCaseID, EvidenceStatus;
GO

-- Query 157: Complaints by station and urgency
PRINT 'Query 157: Complaints by station and urgency';
SELECT PoliceStationID, UrgencyLevel, COUNT(*) AS ComplaintCount
FROM dbo.Complaints
GROUP BY PoliceStationID, UrgencyLevel
ORDER BY PoliceStationID, UrgencyLevel;
GO

-- Query 158: Active versus inactive officers
PRINT 'Query 158: Active versus inactive officers';
SELECT IsActive, COUNT(*) AS OfficerCount
FROM dbo.PoliceOfficers
GROUP BY IsActive;
GO

-- Query 159: Enabled versus disabled system users
PRINT 'Query 159: Enabled versus disabled system users';
SELECT IsEnabled, COUNT(*) AS UserCount
FROM dbo.SystemUsers
GROUP BY IsEnabled;
GO

-- Query 160: Share of cases in each status (percent)
PRINT 'Query 160: Share of cases in each status (percent)';
SELECT CaseStatus,
       COUNT(*) AS CaseCount,
       CAST(100.0 * COUNT(*) / (SELECT COUNT(*) FROM dbo.CriminalCases) AS DECIMAL(5,2)) AS PercentOfCases
FROM dbo.CriminalCases
GROUP BY CaseStatus
ORDER BY CaseCount DESC;
GO


-- ---------------------------------------------------------------------
-- Joining tables together (Queries 161-230)
-- ---------------------------------------------------------------------

-- Query 161: Cases with the police station that registered them
PRINT 'Query 161: Cases with the police station that registered them';
SELECT c.CaseNumber, c.CaseTitle, ps.PoliceStationName
FROM dbo.CriminalCases AS c
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = c.PoliceStationID;
GO

-- Query 162: Police stations with their district
PRINT 'Query 162: Police stations with their district';
SELECT ps.PoliceStationName, d.DistrictName
FROM dbo.PoliceStations AS ps
JOIN dbo.Districts AS d ON d.DistrictID = ps.DistrictID;
GO

-- Query 163: Districts with their state
PRINT 'Query 163: Districts with their state';
SELECT d.DistrictName, s.StateName
FROM dbo.Districts AS d
JOIN dbo.States AS s ON s.StateID = d.StateID;
GO

-- Query 164: Officers with their rank
PRINT 'Query 164: Officers with their rank';
SELECT o.ServiceNumber, o.FirstName, o.LastName, r.RankName, r.RankLevel
FROM dbo.PoliceOfficers AS o
JOIN dbo.PoliceRanks AS r ON r.PoliceRankID = o.PoliceRankID
ORDER BY r.RankLevel DESC, o.LastName;
GO

-- Query 165: Officer postings with station and unit
PRINT 'Query 165: Officer postings with station and unit';
SELECT o.ServiceNumber, o.LastName, ps.PoliceStationName, pu.UnitName, oa.AssignmentStartDate, oa.AssignmentEndDate
FROM dbo.OfficerAssignments AS oa
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = oa.PoliceOfficerID
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = oa.PoliceStationID
LEFT JOIN dbo.PoliceUnits AS pu ON pu.PoliceUnitID = oa.PoliceUnitID;
GO

-- Query 166: Complaints with the station that received them
PRINT 'Query 166: Complaints with the station that received them';
SELECT c.ComplaintNumber, c.ComplaintSummary, ps.PoliceStationName
FROM dbo.Complaints AS c
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = c.PoliceStationID;
GO

-- Query 167: Complaints with their source
PRINT 'Query 167: Complaints with their source';
SELECT c.ComplaintNumber, c.ComplaintSummary, src.SourceName
FROM dbo.Complaints AS c
JOIN dbo.ComplaintSources AS src ON src.ComplaintSourceID = c.ComplaintSourceID;
GO

-- Query 168: Complaints with the assigned officer (including unassigned ones)
PRINT 'Query 168: Complaints with the assigned officer (including unassigned ones)';
SELECT c.ComplaintNumber, c.ComplaintStatus, o.FirstName, o.LastName
FROM dbo.Complaints AS c
LEFT JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = c.AssignedOfficerID;
GO

-- Query 169: Cases with the complaint they came from (including cases without one)
PRINT 'Query 169: Cases with the complaint they came from (including cases without one)';
SELECT cc.CaseNumber, cc.CaseTitle, co.ComplaintNumber
FROM dbo.CriminalCases AS cc
LEFT JOIN dbo.Complaints AS co ON co.ComplaintID = cc.ComplaintID;
GO

-- Query 170: Cases with district and state
PRINT 'Query 170: Cases with district and state';
SELECT c.CaseNumber, ps.PoliceStationName, d.DistrictName, s.StateName
FROM dbo.CriminalCases AS c
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = c.PoliceStationID
JOIN dbo.Districts AS d ON d.DistrictID = ps.DistrictID
JOIN dbo.States AS s ON s.StateID = d.StateID;
GO

-- Query 171: Offences with their crime category
PRINT 'Query 171: Offences with their crime category';
SELECT c.CaseNumber, cat.CategoryName, co.IsPrimaryOffence
FROM dbo.CaseOffences AS co
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = co.CriminalCaseID
JOIN dbo.CrimeCategories AS cat ON cat.CrimeCategoryID = co.CrimeCategoryID;
GO

-- Query 172: Offences with legal provision (where one is recorded)
PRINT 'Query 172: Offences with legal provision (where one is recorded)';
SELECT c.CaseNumber, cat.CategoryName, lp.LegislationShortCode, lp.ProvisionNumber
FROM dbo.CaseOffences AS co
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = co.CriminalCaseID
JOIN dbo.CrimeCategories AS cat ON cat.CrimeCategoryID = co.CrimeCategoryID
LEFT JOIN dbo.LegalProvisions AS lp ON lp.LegalProvisionID = co.LegalProvisionID;
GO

-- Query 173: People involved in each case with their role
PRINT 'Query 173: People involved in each case with their role';
SELECT c.CaseNumber, p.GivenName, p.FamilyName, r.CaseRole
FROM dbo.CasePersonRoles AS r
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = r.CriminalCaseID
JOIN dbo.Persons AS p ON p.PersonID = r.PersonID
ORDER BY c.CaseNumber, r.CaseRole;
GO

-- Query 174: Victims by case
PRINT 'Query 174: Victims by case';
SELECT c.CaseNumber, p.GivenName, p.FamilyName
FROM dbo.CasePersonRoles AS r
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = r.CriminalCaseID
JOIN dbo.Persons AS p ON p.PersonID = r.PersonID
WHERE r.CaseRole = N'Victim';
GO

-- Query 175: Witnesses by case
PRINT 'Query 175: Witnesses by case';
SELECT c.CaseNumber, p.GivenName, p.FamilyName, p.PreferredLanguage
FROM dbo.CasePersonRoles AS r
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = r.CriminalCaseID
JOIN dbo.Persons AS p ON p.PersonID = r.PersonID
WHERE r.CaseRole = N'Witness';
GO

-- Query 176: Suspects by case (allegations only)
PRINT 'Query 176: Suspects by case (allegations only)';
SELECT c.CaseNumber, p.GivenName, p.FamilyName
FROM dbo.CasePersonRoles AS r
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = r.CriminalCaseID
JOIN dbo.Persons AS p ON p.PersonID = r.PersonID
WHERE r.CaseRole = N'Suspect';
GO

-- Query 177: Investigation assignments with case and officer
PRINT 'Query 177: Investigation assignments with case and officer';
SELECT c.CaseNumber, o.FirstName, o.LastName, ia.AssignmentRole, ia.AssignedAt, ia.ReleasedAt
FROM dbo.InvestigationAssignments AS ia
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = ia.CriminalCaseID
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = ia.PoliceOfficerID;
GO

-- Query 178: Diary entries with case and author
PRINT 'Query 178: Diary entries with case and author';
SELECT c.CaseNumber, d.EntryNumber, d.EntryDateTime, o.LastName AS Officer
FROM dbo.CaseDiaryEntries AS d
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = d.CriminalCaseID
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = d.PoliceOfficerID
ORDER BY c.CaseNumber, d.EntryNumber;
GO

-- Query 179: Investigation activities with case and officer
PRINT 'Query 179: Investigation activities with case and officer';
SELECT c.CaseNumber, a.ActivityType, a.ActivityStartedAt, o.LastName AS Officer
FROM dbo.InvestigationActivities AS a
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = a.CriminalCaseID
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = a.PoliceOfficerID;
GO

-- Query 180: Witness statements with witness name and recording officer
PRINT 'Query 180: Witness statements with witness name and recording officer';
SELECT c.CaseNumber, p.GivenName, p.FamilyName, ws.StatementType, o.LastName AS RecordedBy
FROM dbo.WitnessStatements AS ws
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = ws.CriminalCaseID
JOIN dbo.Persons AS p ON p.PersonID = ws.WitnessPersonID
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = ws.RecordedByOfficerID;
GO

-- Query 181: Interviews with person and interviewing officer
PRINT 'Query 181: Interviews with person and interviewing officer';
SELECT c.CaseNumber, p.GivenName, p.FamilyName, i.InterviewStartedAt, o.LastName AS Interviewer
FROM dbo.Interviews AS i
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = i.CriminalCaseID
JOIN dbo.Persons AS p ON p.PersonID = i.PersonID
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = i.InterviewingOfficerID;
GO

-- Query 182: Arrests with person, case and arresting officer
PRINT 'Query 182: Arrests with person, case and arresting officer';
SELECT a.ArrestMemoReference, c.CaseNumber, p.GivenName, p.FamilyName, o.LastName AS ArrestingOfficer, a.ArrestedAt
FROM dbo.Arrests AS a
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = a.CriminalCaseID
JOIN dbo.Persons AS p ON p.PersonID = a.ArrestedPersonID
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = a.ArrestingOfficerID;
GO

-- Query 183: Custody records with the arrest they belong to
PRINT 'Query 183: Custody records with the arrest they belong to';
SELECT a.ArrestMemoReference, cr.CustodyType, cr.CustodyLocation, cr.CustodyStartedAt, cr.CustodyEndedAt
FROM dbo.CustodyRecords AS cr
JOIN dbo.Arrests AS a ON a.ArrestID = cr.ArrestID;
GO

-- Query 184: Search operations with lead officer and case
PRINT 'Query 184: Search operations with lead officer and case';
SELECT c.CaseNumber, so.SearchLocation, so.SearchStartedAt, o.LastName AS LeadOfficer
FROM dbo.SearchOperations AS so
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = so.CriminalCaseID
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = so.LeadOfficerID;
GO

-- Query 185: Evidence with its type
PRINT 'Query 185: Evidence with its type';
SELECT e.ExhibitNumber, et.EvidenceTypeName, e.EvidenceDescription, e.EvidenceStatus
FROM dbo.EvidenceItems AS e
JOIN dbo.EvidenceTypes AS et ON et.EvidenceTypeID = e.EvidenceTypeID;
GO

-- Query 186: Evidence with the officer who collected it
PRINT 'Query 186: Evidence with the officer who collected it';
SELECT e.ExhibitNumber, e.CollectedAt, o.FirstName, o.LastName
FROM dbo.EvidenceItems AS e
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = e.CollectedByOfficerID;
GO

-- Query 187: Custody transfers with the exhibit number
PRINT 'Query 187: Custody transfers with the exhibit number';
SELECT e.ExhibitNumber, t.TransferredAt, t.FromLocation, t.ToLocation, t.TransferPurpose
FROM dbo.EvidenceCustodyTransfers AS t
JOIN dbo.EvidenceItems AS e ON e.EvidenceItemID = t.EvidenceItemID
ORDER BY e.ExhibitNumber, t.TransferredAt;
GO

-- Query 188: Forensic requests with exhibit and laboratory
PRINT 'Query 188: Forensic requests with exhibit and laboratory';
SELECT e.ExhibitNumber, fl.LaboratoryName, fr.ExaminationType, fr.RequestStatus
FROM dbo.ForensicRequests AS fr
JOIN dbo.EvidenceItems AS e ON e.EvidenceItemID = fr.EvidenceItemID
JOIN dbo.ForensicLaboratories AS fl ON fl.ForensicLaboratoryID = fr.ForensicLaboratoryID;
GO

-- Query 189: Forensic reports with the examination they answer
PRINT 'Query 189: Forensic reports with the examination they answer';
SELECT fr.ReportNumber, r.ExaminationType, fr.ReportStatus, fr.ReportIssuedAt
FROM dbo.ForensicReports AS fr
JOIN dbo.ForensicRequests AS r ON r.ForensicRequestID = fr.ForensicRequestID;
GO

-- Query 190: Stolen property with case number and reporting person
PRINT 'Query 190: Stolen property with case number and reporting person';
SELECT c.CaseNumber, sp.PropertyDescription, sp.EstimatedValueINR, p.GivenName, p.FamilyName
FROM dbo.StolenProperties AS sp
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = sp.CriminalCaseID
LEFT JOIN dbo.Persons AS p ON p.PersonID = sp.ReportedByPersonID;
GO

-- Query 191: Property recoveries with the recovering officer
PRINT 'Query 191: Property recoveries with the recovering officer';
SELECT sp.PropertyDescription, pr.RecoveredAt, pr.RecoveryLocation, o.LastName AS RecoveredBy
FROM dbo.PropertyRecoveries AS pr
JOIN dbo.StolenProperties AS sp ON sp.StolenPropertyID = pr.StolenPropertyID
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = pr.RecoveredByOfficerID;
GO

-- Query 192: Missing person reports with both person names
PRINT 'Query 192: Missing person reports with both person names';
SELECT mp.GivenName AS MissingGiven, mp.FamilyName AS MissingFamily, rp.GivenName AS ReporterGiven, rp.FamilyName AS ReporterFamily, m.MissingPersonStatus
FROM dbo.MissingPersonReports AS m
JOIN dbo.Persons AS mp ON mp.PersonID = m.MissingPersonID
JOIN dbo.Persons AS rp ON rp.PersonID = m.ReportedByPersonID;
GO

-- Query 193: Missing person reports with the station that took them
PRINT 'Query 193: Missing person reports with the station that took them';
SELECT ps.PoliceStationName, m.ReportedAt, m.LastSeenLocation, m.MissingPersonStatus
FROM dbo.MissingPersonReports AS m
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = m.PoliceStationID;
GO

-- Query 194: Charge sheets with the case they belong to
PRINT 'Query 194: Charge sheets with the case they belong to';
SELECT c.CaseNumber, cs.ChargeSheetNumber, cs.ChargeSheetType, cs.FiledAt
FROM dbo.ChargeSheets AS cs
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = cs.CriminalCaseID;
GO

-- Query 195: Prosecution teams with case titles
PRINT 'Query 195: Prosecution teams with case titles';
SELECT c.CaseNumber, c.CaseTitle, pt.ProsecutorName, pt.ProsecutorRole
FROM dbo.ProsecutionTeams AS pt
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = pt.CriminalCaseID;
GO

-- Query 196: Court cases with the investigation case number
PRINT 'Query 196: Court cases with the investigation case number';
SELECT cc.CourtCaseNumber, c.CaseNumber, cc.CourtCaseStatus
FROM dbo.CourtCases AS cc
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = cc.CriminalCaseID;
GO

-- Query 197: Hearings with their court case number
PRINT 'Query 197: Hearings with their court case number';
SELECT cc.CourtCaseNumber, h.HearingDateTime, h.HearingPurpose
FROM dbo.CourtHearings AS h
JOIN dbo.CourtCases AS cc ON cc.CourtCaseID = h.CourtCaseID
ORDER BY cc.CourtCaseNumber, h.HearingDateTime;
GO

-- Query 198: Court orders with court case and hearing date
PRINT 'Query 198: Court orders with court case and hearing date';
SELECT cc.CourtCaseNumber, co.OrderReference, co.OrderType, h.HearingDateTime
FROM dbo.CourtOrders AS co
JOIN dbo.CourtCases AS cc ON cc.CourtCaseID = co.CourtCaseID
LEFT JOIN dbo.CourtHearings AS h ON h.CourtHearingID = co.CourtHearingID;
GO

-- Query 199: Bail orders with the arrest memo
PRINT 'Query 199: Bail orders with the arrest memo';
SELECT b.OrderReference, a.ArrestMemoReference, b.BailDecision, b.DecisionDate
FROM dbo.BailOrders AS b
JOIN dbo.Arrests AS a ON a.ArrestID = b.ArrestID;
GO

-- Query 200: Case outcomes with case number
PRINT 'Query 200: Case outcomes with case number';
SELECT c.CaseNumber, o.OutcomeType, o.OutcomeDate, o.AppealFiled
FROM dbo.CaseOutcomes AS o
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = o.CriminalCaseID;
GO

-- Query 201: Victim support services with victim name and case
PRINT 'Query 201: Victim support services with victim name and case';
SELECT c.CaseNumber, p.GivenName, p.FamilyName, v.ServiceType, v.ServiceStatus
FROM dbo.VictimSupportServices AS v
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = v.CriminalCaseID
JOIN dbo.Persons AS p ON p.PersonID = v.VictimPersonID;
GO

-- Query 202: System users with the officer they belong to (if any)
PRINT 'Query 202: System users with the officer they belong to (if any)';
SELECT u.Username, u.IsEnabled, o.FirstName, o.LastName
FROM dbo.SystemUsers AS u
LEFT JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = u.PoliceOfficerID;
GO

-- Query 203: System users with their roles
PRINT 'Query 203: System users with their roles';
SELECT u.Username, r.RoleName, ur.GrantedAt
FROM dbo.SystemUserRoles AS ur
JOIN dbo.SystemUsers AS u ON u.SystemUserID = ur.SystemUserID
JOIN dbo.SystemRoles AS r ON r.SystemRoleID = ur.SystemRoleID
ORDER BY u.Username, r.RoleName;
GO

-- Query 204: Audit log entries with the user name
PRINT 'Query 204: Audit log entries with the user name';
SELECT u.Username, a.EventAt, a.ActionType, a.EntityName, a.ActionSummary
FROM dbo.AuditLog AS a
LEFT JOIN dbo.SystemUsers AS u ON u.SystemUserID = a.SystemUserID
ORDER BY a.EventAt;
GO

-- Query 205: Contact methods with the person they belong to
PRINT 'Query 205: Contact methods with the person they belong to';
SELECT p.GivenName, p.FamilyName, cm.ContactType, cm.ContactValue, cm.IsPreferred
FROM dbo.PersonContactMethods AS cm
JOIN dbo.Persons AS p ON p.PersonID = cm.PersonID;
GO

-- Query 206: Addresses with person and district
PRINT 'Query 206: Addresses with person and district';
SELECT p.GivenName, p.FamilyName, a.AddressType, a.Locality, d.DistrictName
FROM dbo.PersonAddresses AS a
JOIN dbo.Persons AS p ON p.PersonID = a.PersonID
JOIN dbo.Districts AS d ON d.DistrictID = a.DistrictID;
GO

-- Query 207: Identifiers with the person they belong to
PRINT 'Query 207: Identifiers with the person they belong to';
SELECT p.GivenName, p.FamilyName, i.IdentifierType, i.VerificationStatus
FROM dbo.PersonIdentifiers AS i
JOIN dbo.Persons AS p ON p.PersonID = i.PersonID;
GO

-- Query 208: Complaint status history with complaint number
PRINT 'Query 208: Complaint status history with complaint number';
SELECT c.ComplaintNumber, u.UpdatedAt, u.PreviousStatus, u.NewStatus
FROM dbo.ComplaintUpdates AS u
JOIN dbo.Complaints AS c ON c.ComplaintID = u.ComplaintID
ORDER BY c.ComplaintNumber, u.UpdatedAt;
GO

-- Query 209: Complaints and the case number they turned into
PRINT 'Query 209: Complaints and the case number they turned into';
SELECT co.ComplaintNumber, co.ComplaintStatus, cc.CaseNumber
FROM dbo.Complaints AS co
LEFT JOIN dbo.CriminalCases AS cc ON cc.ComplaintID = co.ComplaintID
ORDER BY co.ComplaintNumber;
GO

-- Query 210: Evidence count for every case (zero included)
PRINT 'Query 210: Evidence count for every case (zero included)';
SELECT c.CaseNumber, COUNT(e.EvidenceItemID) AS EvidenceCount
FROM dbo.CriminalCases AS c
LEFT JOIN dbo.EvidenceItems AS e ON e.CriminalCaseID = c.CriminalCaseID
GROUP BY c.CaseNumber
ORDER BY EvidenceCount DESC, c.CaseNumber;
GO

-- Query 211: Number of people linked to every case
PRINT 'Query 211: Number of people linked to every case';
SELECT c.CaseNumber, COUNT(DISTINCT r.PersonID) AS PeopleInvolved
FROM dbo.CriminalCases AS c
LEFT JOIN dbo.CasePersonRoles AS r ON r.CriminalCaseID = c.CriminalCaseID
GROUP BY c.CaseNumber
ORDER BY PeopleInvolved DESC, c.CaseNumber;
GO

-- Query 212: Number of investigation activities for every case
PRINT 'Query 212: Number of investigation activities for every case';
SELECT c.CaseNumber, COUNT(a.InvestigationActivityID) AS ActivityCount
FROM dbo.CriminalCases AS c
LEFT JOIN dbo.InvestigationActivities AS a ON a.CriminalCaseID = c.CriminalCaseID
GROUP BY c.CaseNumber
ORDER BY ActivityCount DESC, c.CaseNumber;
GO

-- Query 213: Number of cases registered by every station (zero included)
PRINT 'Query 213: Number of cases registered by every station (zero included)';
SELECT ps.PoliceStationName, COUNT(c.CriminalCaseID) AS CaseCount
FROM dbo.PoliceStations AS ps
LEFT JOIN dbo.CriminalCases AS c ON c.PoliceStationID = ps.PoliceStationID
GROUP BY ps.PoliceStationName
ORDER BY CaseCount DESC, ps.PoliceStationName;
GO

-- Query 214: How often each crime category has been used
PRINT 'Query 214: How often each crime category has been used';
SELECT cat.CategoryName, COUNT(co.CaseOffenceID) AS TimesUsed
FROM dbo.CrimeCategories AS cat
LEFT JOIN dbo.CaseOffences AS co ON co.CrimeCategoryID = cat.CrimeCategoryID
GROUP BY cat.CategoryName
ORDER BY TimesUsed DESC, cat.CategoryName;
GO

-- Query 215: Requests received by every forensic laboratory
PRINT 'Query 215: Requests received by every forensic laboratory';
SELECT fl.LaboratoryName, COUNT(fr.ForensicRequestID) AS RequestCount
FROM dbo.ForensicLaboratories AS fl
LEFT JOIN dbo.ForensicRequests AS fr ON fr.ForensicLaboratoryID = fl.ForensicLaboratoryID
GROUP BY fl.LaboratoryName
ORDER BY RequestCount DESC;
GO

-- Query 216: Hearings held per court case (zero included)
PRINT 'Query 216: Hearings held per court case (zero included)';
SELECT cc.CourtCaseNumber, COUNT(h.CourtHearingID) AS HearingCount
FROM dbo.CourtCases AS cc
LEFT JOIN dbo.CourtHearings AS h ON h.CourtCaseID = cc.CourtCaseID
GROUP BY cc.CourtCaseNumber
ORDER BY HearingCount DESC;
GO

-- Query 217: Number of cases each person is linked to
PRINT 'Query 217: Number of cases each person is linked to';
SELECT p.PersonID, p.GivenName, p.FamilyName, COUNT(DISTINCT r.CriminalCaseID) AS CaseCount
FROM dbo.Persons AS p
LEFT JOIN dbo.CasePersonRoles AS r ON r.PersonID = p.PersonID
GROUP BY p.PersonID, p.GivenName, p.FamilyName
ORDER BY CaseCount DESC, p.FamilyName;
GO

-- Query 218: Chain of custody for every case (case, exhibit, transfer)
PRINT 'Query 218: Chain of custody for every case (case, exhibit, transfer)';
SELECT c.CaseNumber, e.ExhibitNumber, t.TransferredAt, t.ToLocation
FROM dbo.CriminalCases AS c
JOIN dbo.EvidenceItems AS e ON e.CriminalCaseID = c.CriminalCaseID
JOIN dbo.EvidenceCustodyTransfers AS t ON t.EvidenceItemID = e.EvidenceItemID
ORDER BY c.CaseNumber, e.ExhibitNumber, t.TransferredAt;
GO

-- Query 219: Forensic status for every case with evidence
PRINT 'Query 219: Forensic status for every case with evidence';
SELECT c.CaseNumber, e.ExhibitNumber, fr.RequestStatus
FROM dbo.CriminalCases AS c
JOIN dbo.EvidenceItems AS e ON e.CriminalCaseID = c.CriminalCaseID
LEFT JOIN dbo.ForensicRequests AS fr ON fr.EvidenceItemID = e.EvidenceItemID
ORDER BY c.CaseNumber, e.ExhibitNumber;
GO

-- Query 220: Missing person reports with the status of their linked case
PRINT 'Query 220: Missing person reports with the status of their linked case';
SELECT m.MissingPersonStatus, c.CaseNumber, c.CaseStatus
FROM dbo.MissingPersonReports AS m
LEFT JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = m.RelatedCaseID;
GO

-- Query 221: Every case with its charge sheet (if any)
PRINT 'Query 221: Every case with its charge sheet (if any)';
SELECT c.CaseNumber, c.CaseStatus, cs.ChargeSheetNumber, cs.ChargeSheetType
FROM dbo.CriminalCases AS c
LEFT JOIN dbo.ChargeSheets AS cs ON cs.CriminalCaseID = c.CriminalCaseID
ORDER BY c.CaseNumber;
GO

-- Query 222: Cases with court case and outcome (both optional)
PRINT 'Query 222: Cases with court case and outcome (both optional)';
SELECT c.CaseNumber, cc.CourtCaseNumber, o.OutcomeType
FROM dbo.CriminalCases AS c
LEFT JOIN dbo.CourtCases AS cc ON cc.CriminalCaseID = c.CriminalCaseID
LEFT JOIN dbo.CaseOutcomes AS o ON o.CriminalCaseID = c.CriminalCaseID
WHERE cc.CourtCaseID IS NOT NULL OR o.CaseOutcomeID IS NOT NULL
ORDER BY c.CaseNumber;
GO

-- Query 223: Court hearings with any order made at them
PRINT 'Query 223: Court hearings with any order made at them';
SELECT cc.CourtCaseNumber, h.HearingDateTime, co.OrderReference, co.OrderType
FROM dbo.CourtHearings AS h
JOIN dbo.CourtCases AS cc ON cc.CourtCaseID = h.CourtCaseID
LEFT JOIN dbo.CourtOrders AS co ON co.CourtHearingID = h.CourtHearingID
ORDER BY cc.CourtCaseNumber, h.HearingDateTime;
GO

-- Query 224: People with their email and their case role
PRINT 'Query 224: People with their email and their case role';
SELECT p.GivenName, p.FamilyName, cm.ContactValue AS Email, r.CaseRole
FROM dbo.Persons AS p
LEFT JOIN dbo.PersonContactMethods AS cm ON cm.PersonID = p.PersonID AND cm.ContactType = N'Email'
LEFT JOIN dbo.CasePersonRoles AS r ON r.PersonID = p.PersonID
ORDER BY p.FamilyName, p.GivenName;
GO

-- Query 225: Cases handled per officer (lead or support)
PRINT 'Query 225: Cases handled per officer (lead or support)';
SELECT o.ServiceNumber, o.FirstName, o.LastName, COUNT(ia.InvestigationAssignmentID) AS AssignmentCount
FROM dbo.PoliceOfficers AS o
LEFT JOIN dbo.InvestigationAssignments AS ia ON ia.PoliceOfficerID = o.PoliceOfficerID
GROUP BY o.ServiceNumber, o.FirstName, o.LastName
ORDER BY AssignmentCount DESC, o.LastName;
GO

-- Query 226: Cases with their lead investigator
PRINT 'Query 226: Cases with their lead investigator';
SELECT c.CaseNumber, c.CaseTitle, o.FirstName, o.LastName
FROM dbo.CriminalCases AS c
LEFT JOIN dbo.InvestigationAssignments AS ia ON ia.CriminalCaseID = c.CriminalCaseID AND ia.AssignmentRole = N'Lead Investigator'
LEFT JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = ia.PoliceOfficerID
ORDER BY c.CaseNumber;
GO

-- Query 227: Diary entries with the activities recorded against them
PRINT 'Query 227: Diary entries with the activities recorded against them';
SELECT d.CriminalCaseID, d.EntryNumber, a.ActivityType
FROM dbo.CaseDiaryEntries AS d
LEFT JOIN dbo.InvestigationActivities AS a ON a.RelatedCaseDiaryEntryID = d.CaseDiaryEntryID
ORDER BY d.CriminalCaseID, d.EntryNumber;
GO

-- Query 228: Case, station, district and state in one result
PRINT 'Query 228: Case, station, district and state in one result';
SELECT c.CaseNumber, c.CasePriority, ps.PoliceStationName, d.DistrictName, s.StateName
FROM dbo.CriminalCases AS c
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = c.PoliceStationID
JOIN dbo.Districts AS d ON d.DistrictID = ps.DistrictID
JOIN dbo.States AS s ON s.StateID = d.StateID
ORDER BY s.StateName, d.DistrictName, c.CaseNumber;
GO

-- Query 229: Evidence with its case and the station that holds the case
PRINT 'Query 229: Evidence with its case and the station that holds the case';
SELECT e.ExhibitNumber, c.CaseNumber, ps.PoliceStationName
FROM dbo.EvidenceItems AS e
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = e.CriminalCaseID
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = c.PoliceStationID;
GO

-- Query 230: Current officer postings with station and district
PRINT 'Query 230: Current officer postings with station and district';
SELECT o.ServiceNumber, o.LastName, ps.PoliceStationName, d.DistrictName
FROM dbo.OfficerAssignments AS oa
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = oa.PoliceOfficerID
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = oa.PoliceStationID
JOIN dbo.Districts AS d ON d.DistrictID = ps.DistrictID
WHERE oa.AssignmentEndDate IS NULL;
GO


-- ---------------------------------------------------------------------
-- Subqueries, EXISTS and NOT EXISTS (Queries 231-270)
-- ---------------------------------------------------------------------

-- Query 231: Cases that have at least one evidence item
PRINT 'Query 231: Cases that have at least one evidence item';
SELECT c.CaseNumber, c.CaseTitle
FROM dbo.CriminalCases AS c
WHERE EXISTS (SELECT 1 FROM dbo.EvidenceItems AS e WHERE e.CriminalCaseID = c.CriminalCaseID);
GO

-- Query 232: Cases that have no evidence item yet
PRINT 'Query 232: Cases that have no evidence item yet';
SELECT c.CaseNumber, c.CaseTitle, c.CaseStatus
FROM dbo.CriminalCases AS c
WHERE NOT EXISTS (SELECT 1 FROM dbo.EvidenceItems AS e WHERE e.CriminalCaseID = c.CriminalCaseID);
GO

-- Query 233: Cases with at least one forensic request
PRINT 'Query 233: Cases with at least one forensic request';
SELECT c.CaseNumber, c.CaseTitle
FROM dbo.CriminalCases AS c
WHERE EXISTS (SELECT 1 FROM dbo.EvidenceItems AS e JOIN dbo.ForensicRequests AS fr ON fr.EvidenceItemID = e.EvidenceItemID WHERE e.CriminalCaseID = c.CriminalCaseID);
GO

-- Query 234: Cases that have never gone to court
PRINT 'Query 234: Cases that have never gone to court';
SELECT c.CaseNumber, c.CaseTitle, c.CaseStatus
FROM dbo.CriminalCases AS c
WHERE NOT EXISTS (SELECT 1 FROM dbo.CourtCases AS cc WHERE cc.CriminalCaseID = c.CriminalCaseID);
GO

-- Query 235: Officers who have been given at least one case
PRINT 'Query 235: Officers who have been given at least one case';
SELECT o.ServiceNumber, o.FirstName, o.LastName
FROM dbo.PoliceOfficers AS o
WHERE EXISTS (SELECT 1 FROM dbo.InvestigationAssignments AS ia WHERE ia.PoliceOfficerID = o.PoliceOfficerID);
GO

-- Query 236: Officers who have never been given a case
PRINT 'Query 236: Officers who have never been given a case';
SELECT o.ServiceNumber, o.FirstName, o.LastName, o.IsActive
FROM dbo.PoliceOfficers AS o
WHERE NOT EXISTS (SELECT 1 FROM dbo.InvestigationAssignments AS ia WHERE ia.PoliceOfficerID = o.PoliceOfficerID);
GO

-- Query 237: People who appear in at least one case
PRINT 'Query 237: People who appear in at least one case';
SELECT p.GivenName, p.FamilyName
FROM dbo.Persons AS p
WHERE p.PersonID IN (SELECT PersonID FROM dbo.CasePersonRoles);
GO

-- Query 238: People who are not linked to any case
PRINT 'Query 238: People who are not linked to any case';
SELECT p.GivenName, p.FamilyName, p.PersonNotes
FROM dbo.Persons AS p
WHERE p.PersonID NOT IN (SELECT PersonID FROM dbo.CasePersonRoles);
GO

-- Query 239: Evidence that has a forensic request
PRINT 'Query 239: Evidence that has a forensic request';
SELECT e.ExhibitNumber, e.EvidenceDescription
FROM dbo.EvidenceItems AS e
WHERE e.EvidenceItemID IN (SELECT EvidenceItemID FROM dbo.ForensicRequests);
GO

-- Query 240: Evidence that has never been transferred
PRINT 'Query 240: Evidence that has never been transferred';
SELECT e.ExhibitNumber, e.EvidenceDescription, e.EvidenceStatus
FROM dbo.EvidenceItems AS e
WHERE NOT EXISTS (SELECT 1 FROM dbo.EvidenceCustodyTransfers AS t WHERE t.EvidenceItemID = e.EvidenceItemID);
GO

-- Query 241: Complaints that were turned into cases
PRINT 'Query 241: Complaints that were turned into cases';
SELECT co.ComplaintNumber, co.ComplaintSummary
FROM dbo.Complaints AS co
WHERE EXISTS (SELECT 1 FROM dbo.CriminalCases AS cc WHERE cc.ComplaintID = co.ComplaintID);
GO

-- Query 242: Complaints that have not become cases
PRINT 'Query 242: Complaints that have not become cases';
SELECT co.ComplaintNumber, co.ComplaintSummary, co.ComplaintStatus
FROM dbo.Complaints AS co
WHERE NOT EXISTS (SELECT 1 FROM dbo.CriminalCases AS cc WHERE cc.ComplaintID = co.ComplaintID);
GO

-- Query 243: Cases that already have a charge sheet
PRINT 'Query 243: Cases that already have a charge sheet';
SELECT c.CaseNumber, c.CaseStatus
FROM dbo.CriminalCases AS c
WHERE EXISTS (SELECT 1 FROM dbo.ChargeSheets AS cs WHERE cs.CriminalCaseID = c.CriminalCaseID);
GO

-- Query 244: Cases that do not have a charge sheet
PRINT 'Query 244: Cases that do not have a charge sheet';
SELECT c.CaseNumber, c.CaseStatus
FROM dbo.CriminalCases AS c
WHERE NOT EXISTS (SELECT 1 FROM dbo.ChargeSheets AS cs WHERE cs.CriminalCaseID = c.CriminalCaseID);
GO

-- Query 245: Cases where victim support was arranged
PRINT 'Query 245: Cases where victim support was arranged';
SELECT c.CaseNumber, c.CaseTitle
FROM dbo.CriminalCases AS c
WHERE EXISTS (SELECT 1 FROM dbo.VictimSupportServices AS v WHERE v.CriminalCaseID = c.CriminalCaseID);
GO

-- Query 246: Cases in which someone was arrested
PRINT 'Query 246: Cases in which someone was arrested';
SELECT c.CaseNumber, c.CaseTitle
FROM dbo.CriminalCases AS c
WHERE EXISTS (SELECT 1 FROM dbo.Arrests AS a WHERE a.CriminalCaseID = c.CriminalCaseID);
GO

-- Query 247: Cases with no arrest so far
PRINT 'Query 247: Cases with no arrest so far';
SELECT c.CaseNumber, c.CaseTitle, c.CaseStatus
FROM dbo.CriminalCases AS c
WHERE NOT EXISTS (SELECT 1 FROM dbo.Arrests AS a WHERE a.CriminalCaseID = c.CriminalCaseID);
GO

-- Query 248: Cases booked under more than one offence
PRINT 'Query 248: Cases booked under more than one offence';
SELECT c.CaseNumber, c.CaseTitle
FROM dbo.CriminalCases AS c
WHERE (SELECT COUNT(*) FROM dbo.CaseOffences AS co WHERE co.CriminalCaseID = c.CriminalCaseID) > 1;
GO

-- Query 249: Cases with more than two people involved
PRINT 'Query 249: Cases with more than two people involved';
SELECT c.CaseNumber, c.CaseTitle
FROM dbo.CriminalCases AS c
WHERE (SELECT COUNT(DISTINCT r.PersonID) FROM dbo.CasePersonRoles AS r WHERE r.CriminalCaseID = c.CriminalCaseID) > 2;
GO

-- Query 250: People with more than one contact method
PRINT 'Query 250: People with more than one contact method';
SELECT p.GivenName, p.FamilyName
FROM dbo.Persons AS p
WHERE (SELECT COUNT(*) FROM dbo.PersonContactMethods AS cm WHERE cm.PersonID = p.PersonID) > 1;
GO

-- Query 251: Stolen property worth more than the average item
PRINT 'Query 251: Stolen property worth more than the average item';
SELECT PropertyDescription, EstimatedValueINR
FROM dbo.StolenProperties
WHERE EstimatedValueINR > (SELECT AVG(EstimatedValueINR) FROM dbo.StolenProperties);
GO

-- Query 252: The most valuable stolen property item
PRINT 'Query 252: The most valuable stolen property item';
SELECT PropertyDescription, EstimatedValueINR
FROM dbo.StolenProperties
WHERE EstimatedValueINR = (SELECT MAX(EstimatedValueINR) FROM dbo.StolenProperties);
GO

-- Query 253: The case that was opened first
PRINT 'Query 253: The case that was opened first';
SELECT CaseNumber, CaseTitle, OpenedAt
FROM dbo.CriminalCases
WHERE OpenedAt = (SELECT MIN(OpenedAt) FROM dbo.CriminalCases);
GO

-- Query 254: The most recently received complaint
PRINT 'Query 254: The most recently received complaint';
SELECT ComplaintNumber, ComplaintSummary, ReceivedAt
FROM dbo.Complaints
WHERE ReceivedAt = (SELECT MAX(ReceivedAt) FROM dbo.Complaints);
GO

-- Query 255: Officers ranked above the average rank level
PRINT 'Query 255: Officers ranked above the average rank level';
SELECT o.ServiceNumber, o.FirstName, o.LastName, r.RankName
FROM dbo.PoliceOfficers AS o
JOIN dbo.PoliceRanks AS r ON r.PoliceRankID = o.PoliceRankID
WHERE r.RankLevel > (SELECT AVG(CAST(RankLevel AS FLOAT)) FROM dbo.PoliceRanks);
GO

-- Query 256: Police stations in districts that have more than one station
PRINT 'Query 256: Police stations in districts that have more than one station';
SELECT ps.PoliceStationName, ps.DistrictID
FROM dbo.PoliceStations AS ps
WHERE ps.DistrictID IN (SELECT DistrictID FROM dbo.PoliceStations GROUP BY DistrictID HAVING COUNT(*) > 1);
GO

-- Query 257: Crime categories that have been used
PRINT 'Query 257: Crime categories that have been used';
SELECT cat.CategoryName
FROM dbo.CrimeCategories AS cat
WHERE EXISTS (SELECT 1 FROM dbo.CaseOffences AS co WHERE co.CrimeCategoryID = cat.CrimeCategoryID);
GO

-- Query 258: Crime categories that have never been used
PRINT 'Query 258: Crime categories that have never been used';
SELECT cat.CategoryName, cat.CategoryDescription
FROM dbo.CrimeCategories AS cat
WHERE NOT EXISTS (SELECT 1 FROM dbo.CaseOffences AS co WHERE co.CrimeCategoryID = cat.CrimeCategoryID);
GO

-- Query 259: Laboratories that have received a request
PRINT 'Query 259: Laboratories that have received a request';
SELECT fl.LaboratoryName
FROM dbo.ForensicLaboratories AS fl
WHERE EXISTS (SELECT 1 FROM dbo.ForensicRequests AS fr WHERE fr.ForensicLaboratoryID = fl.ForensicLaboratoryID);
GO

-- Query 260: Laboratories that have never received a request
PRINT 'Query 260: Laboratories that have never received a request';
SELECT fl.LaboratoryName, fl.LaboratoryType
FROM dbo.ForensicLaboratories AS fl
WHERE NOT EXISTS (SELECT 1 FROM dbo.ForensicRequests AS fr WHERE fr.ForensicLaboratoryID = fl.ForensicLaboratoryID);
GO

-- Query 261: Court cases that have had at least one hearing
PRINT 'Query 261: Court cases that have had at least one hearing';
SELECT cc.CourtCaseNumber, cc.CourtCaseStatus
FROM dbo.CourtCases AS cc
WHERE EXISTS (SELECT 1 FROM dbo.CourtHearings AS h WHERE h.CourtCaseID = cc.CourtCaseID);
GO

-- Query 262: Court cases with no hearing recorded (expect 0 rows)
PRINT 'Query 262: Court cases with no hearing recorded (expect 0 rows)';
SELECT cc.CourtCaseNumber, cc.CourtCaseStatus
FROM dbo.CourtCases AS cc
WHERE NOT EXISTS (SELECT 1 FROM dbo.CourtHearings AS h WHERE h.CourtCaseID = cc.CourtCaseID);
GO

-- Query 263: Arrests that led to a bail order
PRINT 'Query 263: Arrests that led to a bail order';
SELECT a.ArrestMemoReference, a.ArrestStatus
FROM dbo.Arrests AS a
WHERE EXISTS (SELECT 1 FROM dbo.BailOrders AS b WHERE b.ArrestID = a.ArrestID);
GO

-- Query 264: Arrests with no bail order
PRINT 'Query 264: Arrests with no bail order';
SELECT a.ArrestMemoReference, a.ArrestStatus
FROM dbo.Arrests AS a
WHERE NOT EXISTS (SELECT 1 FROM dbo.BailOrders AS b WHERE b.ArrestID = a.ArrestID);
GO

-- Query 265: Cases that have a missing person report
PRINT 'Query 265: Cases that have a missing person report';
SELECT c.CaseNumber, c.CaseTitle
FROM dbo.CriminalCases AS c
WHERE EXISTS (SELECT 1 FROM dbo.MissingPersonReports AS m WHERE m.RelatedCaseID = c.CriminalCaseID);
GO

-- Query 266: System users who hold at least one role
PRINT 'Query 266: System users who hold at least one role';
SELECT u.Username
FROM dbo.SystemUsers AS u
WHERE EXISTS (SELECT 1 FROM dbo.SystemUserRoles AS ur WHERE ur.SystemUserID = u.SystemUserID);
GO

-- Query 267: System users who hold no role
PRINT 'Query 267: System users who hold no role';
SELECT u.Username, u.IsEnabled
FROM dbo.SystemUsers AS u
WHERE NOT EXISTS (SELECT 1 FROM dbo.SystemUserRoles AS ur WHERE ur.SystemUserID = u.SystemUserID);
GO

-- Query 268: Cases with no recorded victim
PRINT 'Query 268: Cases with no recorded victim';
SELECT c.CaseNumber, c.CaseTitle
FROM dbo.CriminalCases AS c
WHERE NOT EXISTS (SELECT 1 FROM dbo.CasePersonRoles AS r WHERE r.CriminalCaseID = c.CriminalCaseID AND r.CaseRole = N'Victim');
GO

-- Query 269: Cases with no recorded witness
PRINT 'Query 269: Cases with no recorded witness';
SELECT c.CaseNumber, c.CaseTitle
FROM dbo.CriminalCases AS c
WHERE NOT EXISTS (SELECT 1 FROM dbo.CasePersonRoles AS r WHERE r.CriminalCaseID = c.CriminalCaseID AND r.CaseRole = N'Witness');
GO

-- Query 270: Cases that have both a victim and a witness
PRINT 'Query 270: Cases that have both a victim and a witness';
SELECT c.CaseNumber, c.CaseTitle
FROM dbo.CriminalCases AS c
WHERE EXISTS (SELECT 1 FROM dbo.CasePersonRoles AS r WHERE r.CriminalCaseID = c.CriminalCaseID AND r.CaseRole = N'Victim')
  AND EXISTS (SELECT 1 FROM dbo.CasePersonRoles AS r2 WHERE r2.CriminalCaseID = c.CriminalCaseID AND r2.CaseRole = N'Witness');
GO


-- ---------------------------------------------------------------------
-- Working with dates and times (Queries 271-310)
-- ---------------------------------------------------------------------

-- Query 271: How many days each case has been open
PRINT 'Query 271: How many days each case has been open';
SELECT CaseNumber, OpenedAt, DATEDIFF(day, OpenedAt, ISNULL(ClosedAt, GETDATE())) AS DaysOpen
FROM dbo.CriminalCases
ORDER BY DaysOpen DESC;
GO

-- Query 272: Days between a complaint arriving and the case being opened
PRINT 'Query 272: Days between a complaint arriving and the case being opened';
SELECT co.ComplaintNumber, cc.CaseNumber, DATEDIFF(day, co.ReceivedAt, cc.OpenedAt) AS DaysToOpenCase
FROM dbo.Complaints AS co
JOIN dbo.CriminalCases AS cc ON cc.ComplaintID = co.ComplaintID;
GO

-- Query 273: Length of each finished investigation activity in minutes
PRINT 'Query 273: Length of each finished investigation activity in minutes';
SELECT ActivityType, ActivityStartedAt, DATEDIFF(minute, ActivityStartedAt, ActivityEndedAt) AS DurationMinutes
FROM dbo.InvestigationActivities
WHERE ActivityEndedAt IS NOT NULL;
GO

-- Query 274: Days since each piece of evidence was collected
PRINT 'Query 274: Days since each piece of evidence was collected';
SELECT ExhibitNumber, CollectedAt, DATEDIFF(day, CollectedAt, GETDATE()) AS DaysSinceCollection
FROM dbo.EvidenceItems;
GO

-- Query 275: Days taken to complete each forensic request
PRINT 'Query 275: Days taken to complete each forensic request';
SELECT ForensicRequestID, ExaminationType, DATEDIFF(day, RequestedAt, CompletedAt) AS DaysToComplete
FROM dbo.ForensicRequests
WHERE CompletedAt IS NOT NULL;
GO

-- Query 276: Hours between arrest and production before a court
PRINT 'Query 276: Hours between arrest and production before a court';
SELECT ArrestMemoReference, DATEDIFF(hour, ArrestedAt, ProducedBeforeCourtAt) AS HoursToCourt
FROM dbo.Arrests
WHERE ProducedBeforeCourtAt IS NOT NULL;
GO

-- Query 277: Cases in the order they were opened
PRINT 'Query 277: Cases in the order they were opened';
SELECT CaseNumber, CaseTitle, OpenedAt
FROM dbo.CriminalCases
ORDER BY OpenedAt;
GO

-- Query 278: Complaints with the newest first
PRINT 'Query 278: Complaints with the newest first';
SELECT ComplaintNumber, ComplaintSummary, ReceivedAt
FROM dbo.Complaints
ORDER BY ReceivedAt DESC;
GO

-- Query 279: Evidence with the most recently collected first
PRINT 'Query 279: Evidence with the most recently collected first';
SELECT ExhibitNumber, EvidenceDescription, CollectedAt
FROM dbo.EvidenceItems
ORDER BY CollectedAt DESC;
GO

-- Query 280: Hearings in date order
PRINT 'Query 280: Hearings in date order';
SELECT CourtCaseID, HearingDateTime, HearingPurpose
FROM dbo.CourtHearings
ORDER BY HearingDateTime;
GO

-- Query 281: Cases grouped into age bands
PRINT 'Query 281: Cases grouped into age bands';
SELECT CaseNumber, OpenedAt,
       CASE WHEN DATEDIFF(day, OpenedAt, GETDATE()) <= 90  THEN N'Up to 3 months'
            WHEN DATEDIFF(day, OpenedAt, GETDATE()) <= 365 THEN N'3 to 12 months'
            ELSE N'Over a year' END AS AgeBand
FROM dbo.CriminalCases;
GO

-- Query 282: Cases opened in each month
PRINT 'Query 282: Cases opened in each month';
SELECT YEAR(OpenedAt) AS OpenedYear, MONTH(OpenedAt) AS OpenedMonth, COUNT(*) AS CaseCount
FROM dbo.CriminalCases
GROUP BY YEAR(OpenedAt), MONTH(OpenedAt)
ORDER BY OpenedYear, OpenedMonth;
GO

-- Query 283: Complaints received in each month
PRINT 'Query 283: Complaints received in each month';
SELECT YEAR(ReceivedAt) AS ReceivedYear, MONTH(ReceivedAt) AS ReceivedMonth, COUNT(*) AS ComplaintCount
FROM dbo.Complaints
GROUP BY YEAR(ReceivedAt), MONTH(ReceivedAt)
ORDER BY ReceivedYear, ReceivedMonth;
GO

-- Query 284: Arrests in each month
PRINT 'Query 284: Arrests in each month';
SELECT YEAR(ArrestedAt) AS ArrestYear, MONTH(ArrestedAt) AS ArrestMonth, COUNT(*) AS ArrestCount
FROM dbo.Arrests
GROUP BY YEAR(ArrestedAt), MONTH(ArrestedAt)
ORDER BY ArrestYear, ArrestMonth;
GO

-- Query 285: Evidence collected in each month
PRINT 'Query 285: Evidence collected in each month';
SELECT YEAR(CollectedAt) AS CollectedYear, MONTH(CollectedAt) AS CollectedMonth, COUNT(*) AS ItemCount
FROM dbo.EvidenceItems
GROUP BY YEAR(CollectedAt), MONTH(CollectedAt)
ORDER BY CollectedYear, CollectedMonth;
GO

-- Query 286: Court hearings in each year
PRINT 'Query 286: Court hearings in each year';
SELECT YEAR(HearingDateTime) AS HearingYear, COUNT(*) AS HearingCount
FROM dbo.CourtHearings
GROUP BY YEAR(HearingDateTime)
ORDER BY HearingYear;
GO

-- Query 287: Average number of days a forensic request takes
PRINT 'Query 287: Average number of days a forensic request takes';
SELECT AVG(DATEDIFF(day, RequestedAt, CompletedAt) * 1.0) AS AverageDays
FROM dbo.ForensicRequests
WHERE CompletedAt IS NOT NULL;
GO

-- Query 288: Cases opened in each week of the year
PRINT 'Query 288: Cases opened in each week of the year';
SELECT YEAR(OpenedAt) AS OpenedYear, DATEPART(week, OpenedAt) AS WeekNumber, COUNT(*) AS CaseCount
FROM dbo.CriminalCases
GROUP BY YEAR(OpenedAt), DATEPART(week, OpenedAt)
ORDER BY OpenedYear, WeekNumber;
GO

-- Query 289: Complaints that were not turned into a case on the same day
PRINT 'Query 289: Complaints that were not turned into a case on the same day';
SELECT co.ComplaintNumber, co.ReceivedAt, cc.OpenedAt
FROM dbo.Complaints AS co
JOIN dbo.CriminalCases AS cc ON cc.ComplaintID = co.ComplaintID
WHERE DATEDIFF(day, co.ReceivedAt, cc.OpenedAt) >= 1;
GO

-- Query 290: Forensic requests that took more than three days
PRINT 'Query 290: Forensic requests that took more than three days';
SELECT ForensicRequestID, ExaminationType, RequestedAt, CompletedAt
FROM dbo.ForensicRequests
WHERE DATEDIFF(day, RequestedAt, CompletedAt) > 3;
GO

-- Query 291: Custody periods longer than 24 hours
PRINT 'Query 291: Custody periods longer than 24 hours';
SELECT CustodyRecordID, CustodyType, CustodyStartedAt, CustodyEndedAt, DATEDIFF(hour, CustodyStartedAt, CustodyEndedAt) AS HoursInCustody
FROM dbo.CustodyRecords
WHERE DATEDIFF(hour, CustodyStartedAt, CustodyEndedAt) > 24;
GO

-- Query 292: Hearings that already have a next date fixed
PRINT 'Query 292: Hearings that already have a next date fixed';
SELECT CourtCaseID, HearingDateTime, NextHearingDateTime
FROM dbo.CourtHearings
WHERE NextHearingDateTime IS NOT NULL
ORDER BY NextHearingDateTime;
GO

-- Query 293: Hearings still waiting for an outcome (not yet held)
PRINT 'Query 293: Hearings still waiting for an outcome (not yet held)';
SELECT CourtCaseID, HearingDateTime, HearingPurpose
FROM dbo.CourtHearings
WHERE HearingOutcome IS NULL;
GO

-- Query 294: Day of the week on which each arrest was made
PRINT 'Query 294: Day of the week on which each arrest was made';
SELECT ArrestMemoReference, ArrestedAt, DATENAME(weekday, ArrestedAt) AS WeekdayName
FROM dbo.Arrests;
GO

-- Query 295: Cases opened in each quarter
PRINT 'Query 295: Cases opened in each quarter';
SELECT YEAR(OpenedAt) AS OpenedYear, DATEPART(quarter, OpenedAt) AS QuarterNumber, COUNT(*) AS CaseCount
FROM dbo.CriminalCases
GROUP BY YEAR(OpenedAt), DATEPART(quarter, OpenedAt)
ORDER BY OpenedYear, QuarterNumber;
GO

-- Query 296: Month name for each case opening
PRINT 'Query 296: Month name for each case opening';
SELECT CaseNumber, DATENAME(month, OpenedAt) AS OpenedMonthName, OpenedAt
FROM dbo.CriminalCases;
GO

-- Query 297: Complaints received outside normal office hours
PRINT 'Query 297: Complaints received outside normal office hours';
SELECT ComplaintNumber, ReceivedAt
FROM dbo.Complaints
WHERE DATEPART(hour, ReceivedAt) < 9 OR DATEPART(hour, ReceivedAt) >= 18;
GO

-- Query 298: Years of service for officers with a joining date
PRINT 'Query 298: Years of service for officers with a joining date';
SELECT ServiceNumber, FirstName, LastName, DateOfJoining, DATEDIFF(year, DateOfJoining, GETDATE()) AS YearsOfService
FROM dbo.PoliceOfficers
WHERE DateOfJoining IS NOT NULL
ORDER BY YearsOfService DESC;
GO

-- Query 299: Approximate age of each person with a date of birth
PRINT 'Query 299: Approximate age of each person with a date of birth';
SELECT GivenName, FamilyName, DateOfBirth, DATEDIFF(year, DateOfBirth, GETDATE()) AS ApproximateAge
FROM dbo.Persons
WHERE DateOfBirth IS NOT NULL
ORDER BY ApproximateAge DESC;
GO

-- Query 300: People grouped into age bands
PRINT 'Query 300: People grouped into age bands';
SELECT GivenName, FamilyName,
       CASE WHEN DATEDIFF(year, DateOfBirth, GETDATE()) < 30 THEN N'Under 30'
            WHEN DATEDIFF(year, DateOfBirth, GETDATE()) < 45 THEN N'30 to 44'
            ELSE N'45 and over' END AS AgeBand
FROM dbo.Persons
WHERE DateOfBirth IS NOT NULL;
GO

-- Query 301: Hours between the incident and the complaint being received
PRINT 'Query 301: Hours between the incident and the complaint being received';
SELECT ComplaintNumber, IncidentDateTime, ReceivedAt, DATEDIFF(hour, IncidentDateTime, ReceivedAt) AS HoursToReport
FROM dbo.Complaints
WHERE IncidentDateTime IS NOT NULL
ORDER BY HoursToReport DESC;
GO

-- Query 302: Days between FIR registration and charge sheet filing
PRINT 'Query 302: Days between FIR registration and charge sheet filing';
SELECT c.CaseNumber, cs.ChargeSheetNumber, DATEDIFF(day, c.FIRRegisteredAt, cs.FiledAt) AS DaysToChargeSheet
FROM dbo.ChargeSheets AS cs
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = cs.CriminalCaseID
WHERE cs.FiledAt IS NOT NULL AND c.FIRRegisteredAt IS NOT NULL;
GO

-- Query 303: Days between arrest and the bail decision
PRINT 'Query 303: Days between arrest and the bail decision';
SELECT a.ArrestMemoReference, b.BailDecision, DATEDIFF(day, a.ArrestedAt, b.DecisionDate) AS DaysToDecision
FROM dbo.BailOrders AS b
JOIN dbo.Arrests AS a ON a.ArrestID = b.ArrestID;
GO

-- Query 304: Gap in days between a hearing and the next fixed hearing
PRINT 'Query 304: Gap in days between a hearing and the next fixed hearing';
SELECT CourtCaseID, HearingDateTime, NextHearingDateTime, DATEDIFF(day, HearingDateTime, NextHearingDateTime) AS GapDays
FROM dbo.CourtHearings
WHERE NextHearingDateTime IS NOT NULL;
GO

-- Query 305: How long closed cases stayed open
PRINT 'Query 305: How long closed cases stayed open';
SELECT CaseNumber, OpenedAt, ClosedAt, DATEDIFF(day, OpenedAt, ClosedAt) AS DaysBeforeClosure
FROM dbo.CriminalCases
WHERE ClosedAt IS NOT NULL;
GO

-- Query 306: Cases opened in the 90 days before the newest case
PRINT 'Query 306: Cases opened in the 90 days before the newest case';
SELECT CaseNumber, CaseTitle, OpenedAt
FROM dbo.CriminalCases
WHERE OpenedAt >= DATEADD(day, -90, (SELECT MAX(OpenedAt) FROM dbo.CriminalCases));
GO

-- Query 307: Hours between case opening and the first diary entry
PRINT 'Query 307: Hours between case opening and the first diary entry';
SELECT c.CaseNumber, MIN(DATEDIFF(hour, c.OpenedAt, d.EntryDateTime)) AS HoursToFirstEntry
FROM dbo.CriminalCases AS c
JOIN dbo.CaseDiaryEntries AS d ON d.CriminalCaseID = c.CriminalCaseID
GROUP BY c.CaseNumber;
GO

-- Query 308: Days between case opening and the first evidence being collected
PRINT 'Query 308: Days between case opening and the first evidence being collected';
SELECT c.CaseNumber, MIN(DATEDIFF(day, c.OpenedAt, e.CollectedAt)) AS DaysToFirstEvidence
FROM dbo.CriminalCases AS c
JOIN dbo.EvidenceItems AS e ON e.CriminalCaseID = c.CriminalCaseID
GROUP BY c.CaseNumber;
GO

-- Query 309: Evidence collected on the same day the case was opened
PRINT 'Query 309: Evidence collected on the same day the case was opened';
SELECT c.CaseNumber, e.ExhibitNumber, e.CollectedAt
FROM dbo.CriminalCases AS c
JOIN dbo.EvidenceItems AS e ON e.CriminalCaseID = c.CriminalCaseID
WHERE DATEDIFF(day, c.OpenedAt, e.CollectedAt) = 0;
GO

-- Query 310: Date a week after each complaint was received (follow-up date)
PRINT 'Query 310: Date a week after each complaint was received (follow-up date)';
SELECT ComplaintNumber, ReceivedAt, DATEADD(day, 7, ReceivedAt) AS FollowUpDue
FROM dbo.Complaints;
GO


-- ---------------------------------------------------------------------
-- Window functions, CTEs and top-N queries (Queries 311-345)
-- ---------------------------------------------------------------------

-- Query 311: Rank cases by how early they were opened
PRINT 'Query 311: Rank cases by how early they were opened';
SELECT CaseNumber, OpenedAt, RANK() OVER (ORDER BY OpenedAt) AS OpenedRank
FROM dbo.CriminalCases;
GO

-- Query 312: Number the cases inside each priority level
PRINT 'Query 312: Number the cases inside each priority level';
SELECT CasePriority, CaseNumber, ROW_NUMBER() OVER (PARTITION BY CasePriority ORDER BY OpenedAt) AS PositionInPriority
FROM dbo.CriminalCases;
GO

-- Query 313: Number the officers by service number
PRINT 'Query 313: Number the officers by service number';
SELECT ServiceNumber, FirstName, LastName, ROW_NUMBER() OVER (ORDER BY ServiceNumber) AS RowNo
FROM dbo.PoliceOfficers;
GO

-- Query 314: Dense rank of stolen property by value
PRINT 'Query 314: Dense rank of stolen property by value';
SELECT PropertyDescription, EstimatedValueINR, DENSE_RANK() OVER (ORDER BY EstimatedValueINR DESC) AS ValueRank
FROM dbo.StolenProperties
WHERE EstimatedValueINR IS NOT NULL;
GO

-- Query 315: Running count of cases in order of opening
PRINT 'Query 315: Running count of cases in order of opening';
SELECT CaseNumber, OpenedAt, COUNT(*) OVER (ORDER BY OpenedAt ROWS UNBOUNDED PRECEDING) AS CasesSoFar
FROM dbo.CriminalCases;
GO

-- Query 316: Running total of stolen property value
PRINT 'Query 316: Running total of stolen property value';
SELECT StolenPropertyID, PropertyDescription, ISNULL(EstimatedValueINR, 0) AS ValueINR,
       SUM(ISNULL(EstimatedValueINR, 0)) OVER (ORDER BY StolenPropertyID ROWS UNBOUNDED PRECEDING) AS RunningTotalINR
FROM dbo.StolenProperties;
GO

-- Query 317: Each case next to the number of cases in its status
PRINT 'Query 317: Each case next to the number of cases in its status';
SELECT CaseNumber, CaseStatus, COUNT(*) OVER (PARTITION BY CaseStatus) AS CasesWithSameStatus
FROM dbo.CriminalCases;
GO

-- Query 318: Previous case opening date (LAG)
PRINT 'Query 318: Previous case opening date (LAG)';
SELECT CaseNumber, OpenedAt, LAG(OpenedAt) OVER (ORDER BY OpenedAt) AS PreviousOpenedAt
FROM dbo.CriminalCases;
GO

-- Query 319: Next case opening date (LEAD)
PRINT 'Query 319: Next case opening date (LEAD)';
SELECT CaseNumber, OpenedAt, LEAD(OpenedAt) OVER (ORDER BY OpenedAt) AS NextOpenedAt
FROM dbo.CriminalCases;
GO

-- Query 320: Days since the previous case was opened
PRINT 'Query 320: Days since the previous case was opened';
SELECT CaseNumber, OpenedAt, DATEDIFF(day, LAG(OpenedAt) OVER (ORDER BY OpenedAt), OpenedAt) AS DaysSincePreviousCase
FROM dbo.CriminalCases;
GO

-- Query 321: Split stolen property into four value groups (NTILE)
PRINT 'Query 321: Split stolen property into four value groups (NTILE)';
SELECT PropertyDescription, EstimatedValueINR, NTILE(4) OVER (ORDER BY EstimatedValueINR) AS ValueQuartile
FROM dbo.StolenProperties
WHERE EstimatedValueINR IS NOT NULL;
GO

-- Query 322: High priority cases through a CTE
PRINT 'Query 322: High priority cases through a CTE';
WITH HighPriorityCases AS (
    SELECT CriminalCaseID, CaseNumber, CaseTitle, CasePriority
    FROM dbo.CriminalCases
    WHERE CasePriority IN (N'High', N'Critical')
)
SELECT CaseNumber, CaseTitle, CasePriority
FROM HighPriorityCases
ORDER BY CaseNumber;
GO

-- Query 323: Evidence count per case through a CTE
PRINT 'Query 323: Evidence count per case through a CTE';
WITH EvidencePerCase AS (
    SELECT CriminalCaseID, COUNT(*) AS EvidenceCount
    FROM dbo.EvidenceItems
    GROUP BY CriminalCaseID
)
SELECT c.CaseNumber, e.EvidenceCount
FROM EvidencePerCase AS e
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = e.CriminalCaseID
ORDER BY e.EvidenceCount DESC, c.CaseNumber;
GO

-- Query 324: People per case through a CTE
PRINT 'Query 324: People per case through a CTE';
WITH PeoplePerCase AS (
    SELECT CriminalCaseID, COUNT(DISTINCT PersonID) AS PeopleCount
    FROM dbo.CasePersonRoles
    GROUP BY CriminalCaseID
)
SELECT c.CaseNumber, p.PeopleCount
FROM PeoplePerCase AS p
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = p.CriminalCaseID
ORDER BY p.PeopleCount DESC, c.CaseNumber;
GO

-- Query 325: Forensic requests that are still open, through a CTE
PRINT 'Query 325: Forensic requests that are still open, through a CTE';
WITH OpenRequests AS (
    SELECT ForensicRequestID, EvidenceItemID, ExaminationType, RequestStatus, RequestedAt
    FROM dbo.ForensicRequests
    WHERE RequestStatus IN (N'Submitted', N'Accepted', N'In Progress')
)
SELECT e.ExhibitNumber, r.ExaminationType, r.RequestStatus, r.RequestedAt
FROM OpenRequests AS r
JOIN dbo.EvidenceItems AS e ON e.EvidenceItemID = r.EvidenceItemID
ORDER BY r.RequestedAt;
GO

-- Query 326: Cases that have not reached any court, through a CTE
PRINT 'Query 326: Cases that have not reached any court, through a CTE';
WITH CasesInCourt AS (
    SELECT DISTINCT CriminalCaseID
    FROM dbo.CourtCases
)
SELECT c.CaseNumber, c.CaseTitle, c.CaseStatus
FROM dbo.CriminalCases AS c
LEFT JOIN CasesInCourt AS cic ON cic.CriminalCaseID = c.CriminalCaseID
WHERE cic.CriminalCaseID IS NULL;
GO

-- Query 327: Latest diary entry for every case
PRINT 'Query 327: Latest diary entry for every case';
WITH RankedEntries AS (
    SELECT CriminalCaseID, EntryNumber, EntryDateTime, EntryNarrative,
           ROW_NUMBER() OVER (PARTITION BY CriminalCaseID ORDER BY EntryDateTime DESC) AS rn
    FROM dbo.CaseDiaryEntries
)
SELECT c.CaseNumber, r.EntryNumber, r.EntryDateTime, r.EntryNarrative
FROM RankedEntries AS r
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = r.CriminalCaseID
WHERE r.rn = 1
ORDER BY c.CaseNumber;
GO

-- Query 328: Latest custody transfer for every evidence item
PRINT 'Query 328: Latest custody transfer for every evidence item';
WITH RankedTransfers AS (
    SELECT EvidenceItemID, TransferredAt, ToLocation,
           ROW_NUMBER() OVER (PARTITION BY EvidenceItemID ORDER BY TransferredAt DESC) AS rn
    FROM dbo.EvidenceCustodyTransfers
)
SELECT e.ExhibitNumber, r.TransferredAt, r.ToLocation
FROM RankedTransfers AS r
JOIN dbo.EvidenceItems AS e ON e.EvidenceItemID = r.EvidenceItemID
WHERE r.rn = 1
ORDER BY e.ExhibitNumber;
GO

-- Query 329: Latest status update for every complaint
PRINT 'Query 329: Latest status update for every complaint';
WITH RankedUpdates AS (
    SELECT ComplaintID, UpdatedAt, NewStatus,
           ROW_NUMBER() OVER (PARTITION BY ComplaintID ORDER BY UpdatedAt DESC) AS rn
    FROM dbo.ComplaintUpdates
)
SELECT c.ComplaintNumber, r.UpdatedAt, r.NewStatus
FROM RankedUpdates AS r
JOIN dbo.Complaints AS c ON c.ComplaintID = r.ComplaintID
WHERE r.rn = 1
ORDER BY c.ComplaintNumber;
GO

-- Query 330: Newest case registered at each police station
PRINT 'Query 330: Newest case registered at each police station';
WITH RankedCases AS (
    SELECT PoliceStationID, CaseNumber, CaseTitle, OpenedAt,
           ROW_NUMBER() OVER (PARTITION BY PoliceStationID ORDER BY OpenedAt DESC) AS rn
    FROM dbo.CriminalCases
)
SELECT ps.PoliceStationName, r.CaseNumber, r.CaseTitle, r.OpenedAt
FROM RankedCases AS r
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = r.PoliceStationID
WHERE r.rn = 1
ORDER BY ps.PoliceStationName;
GO

-- Query 331: Cases opened per month with a running total
PRINT 'Query 331: Cases opened per month with a running total';
WITH MonthlyCases AS (
    SELECT YEAR(OpenedAt) AS OpenedYear, MONTH(OpenedAt) AS OpenedMonth, COUNT(*) AS CaseCount
    FROM dbo.CriminalCases
    GROUP BY YEAR(OpenedAt), MONTH(OpenedAt)
)
SELECT OpenedYear, OpenedMonth, CaseCount,
       SUM(CaseCount) OVER (ORDER BY OpenedYear, OpenedMonth ROWS UNBOUNDED PRECEDING) AS RunningTotal
FROM MonthlyCases
ORDER BY OpenedYear, OpenedMonth;
GO

-- Query 332: The three most valuable stolen items
PRINT 'Query 332: The three most valuable stolen items';
SELECT TOP 3 PropertyDescription, EstimatedValueINR
FROM dbo.StolenProperties
WHERE EstimatedValueINR IS NOT NULL
ORDER BY EstimatedValueINR DESC;
GO

-- Query 333: The five most recently opened cases
PRINT 'Query 333: The five most recently opened cases';
SELECT TOP 5 CaseNumber, CaseTitle, OpenedAt
FROM dbo.CriminalCases
ORDER BY OpenedAt DESC;
GO

-- Query 334: The oldest case that is still open
PRINT 'Query 334: The oldest case that is still open';
SELECT TOP 1 CaseNumber, CaseTitle, OpenedAt
FROM dbo.CriminalCases
WHERE ClosedAt IS NULL
ORDER BY OpenedAt;
GO

-- Query 335: The case with the most evidence items
PRINT 'Query 335: The case with the most evidence items';
SELECT TOP 1 c.CaseNumber, COUNT(e.EvidenceItemID) AS EvidenceCount
FROM dbo.CriminalCases AS c
JOIN dbo.EvidenceItems AS e ON e.CriminalCaseID = c.CriminalCaseID
GROUP BY c.CaseNumber
ORDER BY COUNT(e.EvidenceItemID) DESC, c.CaseNumber;
GO

-- Query 336: The officer with the most investigation assignments
PRINT 'Query 336: The officer with the most investigation assignments';
SELECT TOP 1 o.ServiceNumber, o.FirstName, o.LastName, COUNT(*) AS Assignments
FROM dbo.InvestigationAssignments AS ia
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = ia.PoliceOfficerID
GROUP BY o.ServiceNumber, o.FirstName, o.LastName
ORDER BY COUNT(*) DESC, o.ServiceNumber;
GO

-- Query 337: The most common case status
PRINT 'Query 337: The most common case status';
SELECT TOP 1 CaseStatus, COUNT(*) AS CaseCount
FROM dbo.CriminalCases
GROUP BY CaseStatus
ORDER BY COUNT(*) DESC, CaseStatus;
GO

-- Query 338: The complaint source used most often
PRINT 'Query 338: The complaint source used most often';
SELECT TOP 1 src.SourceName, COUNT(*) AS ComplaintCount
FROM dbo.Complaints AS c
JOIN dbo.ComplaintSources AS src ON src.ComplaintSourceID = c.ComplaintSourceID
GROUP BY src.SourceName
ORDER BY COUNT(*) DESC, src.SourceName;
GO

-- Query 339: The evidence type collected most often
PRINT 'Query 339: The evidence type collected most often';
SELECT TOP 1 et.EvidenceTypeName, COUNT(*) AS ItemCount
FROM dbo.EvidenceItems AS e
JOIN dbo.EvidenceTypes AS et ON et.EvidenceTypeID = e.EvidenceTypeID
GROUP BY et.EvidenceTypeName
ORDER BY COUNT(*) DESC, et.EvidenceTypeName;
GO

-- Query 340: The laboratory with the most forensic requests
PRINT 'Query 340: The laboratory with the most forensic requests';
SELECT TOP 1 fl.LaboratoryName, COUNT(*) AS RequestCount
FROM dbo.ForensicRequests AS fr
JOIN dbo.ForensicLaboratories AS fl ON fl.ForensicLaboratoryID = fr.ForensicLaboratoryID
GROUP BY fl.LaboratoryName
ORDER BY COUNT(*) DESC, fl.LaboratoryName;
GO

-- Query 341: The police station that registered the most cases
PRINT 'Query 341: The police station that registered the most cases';
SELECT TOP 1 ps.PoliceStationName, COUNT(*) AS CaseCount
FROM dbo.CriminalCases AS c
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = c.PoliceStationID
GROUP BY ps.PoliceStationName
ORDER BY COUNT(*) DESC, ps.PoliceStationName;
GO

-- Query 342: Average number of evidence items per case that has evidence
PRINT 'Query 342: Average number of evidence items per case that has evidence';
SELECT AVG(x.EvidenceCount * 1.0) AS AverageEvidencePerCase
FROM (SELECT CriminalCaseID, COUNT(*) AS EvidenceCount
      FROM dbo.EvidenceItems
      GROUP BY CriminalCaseID) AS x;
GO

-- Query 343: The case with the most people involved
PRINT 'Query 343: The case with the most people involved';
SELECT TOP 1 c.CaseNumber, COUNT(DISTINCT r.PersonID) AS PeopleInvolved
FROM dbo.CriminalCases AS c
JOIN dbo.CasePersonRoles AS r ON r.CriminalCaseID = c.CriminalCaseID
GROUP BY c.CaseNumber
ORDER BY COUNT(DISTINCT r.PersonID) DESC, c.CaseNumber;
GO

-- Query 344: First case ever registered at each station next to every later case (FIRST_VALUE)
PRINT 'Query 344: First case ever registered at each station next to every later case (FIRST_VALUE)';
SELECT PoliceStationID, CaseNumber, OpenedAt,
       FIRST_VALUE(CaseNumber) OVER (PARTITION BY PoliceStationID ORDER BY OpenedAt) AS FirstCaseAtStation
FROM dbo.CriminalCases
ORDER BY PoliceStationID, OpenedAt;
GO

-- Query 345: Cases ranked by evidence count using two chained CTEs
PRINT 'Query 345: Cases ranked by evidence count using two chained CTEs';
WITH EvidencePerCase AS (
    SELECT CriminalCaseID, COUNT(*) AS EvidenceCount
    FROM dbo.EvidenceItems
    GROUP BY CriminalCaseID
),
RankedCases AS (
    SELECT CriminalCaseID, EvidenceCount, DENSE_RANK() OVER (ORDER BY EvidenceCount DESC) AS EvidenceRank
    FROM EvidencePerCase
)
SELECT c.CaseNumber, c.CaseTitle, r.EvidenceCount, r.EvidenceRank
FROM RankedCases AS r
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = r.CriminalCaseID
ORDER BY r.EvidenceRank, c.CaseNumber;
GO


-- ---------------------------------------------------------------------
-- Operational reports (Queries 346-380)
-- ---------------------------------------------------------------------

-- Query 346: Complaint review queue (received or under review, oldest first)
PRINT 'Query 346: Complaint review queue (received or under review, oldest first)';
SELECT ComplaintNumber, ComplaintSummary, UrgencyLevel, ComplaintStatus, ReceivedAt
FROM dbo.Complaints
WHERE ComplaintStatus IN (N'Received', N'Under Review')
ORDER BY ReceivedAt;
GO

-- Query 347: Active high priority cases waiting on a decision
PRINT 'Query 347: Active high priority cases waiting on a decision';
SELECT CaseNumber, CaseTitle, CasePriority, CaseStatus
FROM dbo.CriminalCases
WHERE CasePriority IN (N'High', N'Critical') AND CaseStatus IN (N'Registered', N'Under Investigation')
ORDER BY CasePriority, OpenedAt;
GO

-- Query 348: Digital evidence that is missing its hash value (expect 0 rows)
PRINT 'Query 348: Digital evidence that is missing its hash value (expect 0 rows)';
SELECT ExhibitNumber, EvidenceDescription
FROM dbo.EvidenceItems
WHERE IsDigitalEvidence = 1 AND DigitalFileHashSHA256 IS NULL;
GO

-- Query 349: Evidence in storage that has no forensic request yet
PRINT 'Query 349: Evidence in storage that has no forensic request yet';
SELECT e.ExhibitNumber, e.EvidenceDescription, e.StorageLocation
FROM dbo.EvidenceItems AS e
WHERE e.EvidenceStatus = N'In Storage'
  AND NOT EXISTS (SELECT 1 FROM dbo.ForensicRequests AS fr WHERE fr.EvidenceItemID = e.EvidenceItemID);
GO

-- Query 350: Forensic turnaround report by laboratory
PRINT 'Query 350: Forensic turnaround report by laboratory';
SELECT fl.LaboratoryName, COUNT(*) AS CompletedRequests, AVG(DATEDIFF(day, fr.RequestedAt, fr.CompletedAt) * 1.0) AS AverageDays
FROM dbo.ForensicRequests AS fr
JOIN dbo.ForensicLaboratories AS fl ON fl.ForensicLaboratoryID = fr.ForensicLaboratoryID
WHERE fr.CompletedAt IS NOT NULL
GROUP BY fl.LaboratoryName;
GO

-- Query 351: Forensic reports that still need peer review
PRINT 'Query 351: Forensic reports that still need peer review';
SELECT ReportNumber, ExaminerName, ReportIssuedAt
FROM dbo.ForensicReports
WHERE ReportStatus = N'Peer Review';
GO

-- Query 352: Arrests and any bail decision made
PRINT 'Query 352: Arrests and any bail decision made';
SELECT a.ArrestMemoReference, a.ArrestStatus, b.OrderReference, b.BailDecision, b.BondAmountINR
FROM dbo.Arrests AS a
LEFT JOIN dbo.BailOrders AS b ON b.ArrestID = a.ArrestID
ORDER BY a.ArrestedAt;
GO

-- Query 353: Custody timeline for every arrest
PRINT 'Query 353: Custody timeline for every arrest';
SELECT a.ArrestMemoReference, cr.CustodyType, cr.CustodyStartedAt, cr.CustodyEndedAt
FROM dbo.CustodyRecords AS cr
JOIN dbo.Arrests AS a ON a.ArrestID = cr.ArrestID
ORDER BY a.ArrestMemoReference, cr.CustodyStartedAt;
GO

-- Query 354: Stolen property count and value by category
PRINT 'Query 354: Stolen property count and value by category';
SELECT PropertyCategory, COUNT(*) AS ItemCount, SUM(ISNULL(EstimatedValueINR, 0)) AS TotalValueINR
FROM dbo.StolenProperties
GROUP BY PropertyCategory
ORDER BY TotalValueINR DESC;
GO

-- Query 355: Value of property that has been recovered or returned
PRINT 'Query 355: Value of property that has been recovered or returned';
SELECT SUM(ISNULL(EstimatedValueINR, 0)) AS RecoveredValueINR
FROM dbo.StolenProperties
WHERE PropertyStatus IN (N'Recovered', N'Returned To Owner');
GO

-- Query 356: Missing person follow-up list
PRINT 'Query 356: Missing person follow-up list';
SELECT mp.GivenName, mp.FamilyName, m.ReportedAt, m.LastSeenLocation, m.MissingPersonStatus
FROM dbo.MissingPersonReports AS m
JOIN dbo.Persons AS mp ON mp.PersonID = m.MissingPersonID
WHERE m.MissingPersonStatus <> N'Located';
GO

-- Query 357: Court hearing diary with the case and judge
PRINT 'Query 357: Court hearing diary with the case and judge';
SELECT cc.CourtCaseNumber, h.HearingDateTime, h.HearingPurpose, h.PresidingJudgeName
FROM dbo.CourtHearings AS h
JOIN dbo.CourtCases AS cc ON cc.CourtCaseID = h.CourtCaseID
ORDER BY h.HearingDateTime;
GO

-- Query 358: Court orders in date order
PRINT 'Query 358: Court orders in date order';
SELECT cc.CourtCaseNumber, co.OrderDate, co.OrderType, co.OrderReference
FROM dbo.CourtOrders AS co
JOIN dbo.CourtCases AS cc ON cc.CourtCaseID = co.CourtCaseID
ORDER BY co.OrderDate;
GO

-- Query 359: Case outcomes where an appeal has been filed
PRINT 'Query 359: Case outcomes where an appeal has been filed';
SELECT c.CaseNumber, o.OutcomeType, o.OutcomeDate, o.AppealFiledDate
FROM dbo.CaseOutcomes AS o
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = o.CriminalCaseID
WHERE o.AppealFiled = 1;
GO

-- Query 360: Victim support follow-ups that are due and not yet finished
PRINT 'Query 360: Victim support follow-ups that are due and not yet finished';
SELECT CriminalCaseID, VictimPersonID, ServiceType, ServiceStatus, FollowUpDate
FROM dbo.VictimSupportServices
WHERE FollowUpDate IS NOT NULL
  AND FollowUpDate <= CONVERT(date, GETDATE())
  AND ServiceStatus NOT IN (N'Completed', N'Declined');
GO

-- Query 361: Where each active officer is currently posted
PRINT 'Query 361: Where each active officer is currently posted';
SELECT o.ServiceNumber, o.FirstName, o.LastName, ps.PoliceStationName
FROM dbo.PoliceOfficers AS o
JOIN dbo.OfficerAssignments AS oa ON oa.PoliceOfficerID = o.PoliceOfficerID
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = oa.PoliceStationID
WHERE o.IsActive = 1 AND oa.AssignmentEndDate IS NULL AND oa.IsPrimaryAssignment = 1
ORDER BY ps.PoliceStationName, o.LastName;
GO

-- Query 362: Complaint totals for each police station
PRINT 'Query 362: Complaint totals for each police station';
SELECT ps.PoliceStationName, COUNT(c.ComplaintID) AS ComplaintCount
FROM dbo.PoliceStations AS ps
LEFT JOIN dbo.Complaints AS c ON c.PoliceStationID = ps.PoliceStationID
GROUP BY ps.PoliceStationName
ORDER BY ComplaintCount DESC, ps.PoliceStationName;
GO

-- Query 363: High and critical complaints for each station (zero included)
PRINT 'Query 363: High and critical complaints for each station (zero included)';
SELECT ps.PoliceStationName, COUNT(c.ComplaintID) AS UrgentComplaints
FROM dbo.PoliceStations AS ps
LEFT JOIN dbo.Complaints AS c ON c.PoliceStationID = ps.PoliceStationID AND c.UrgencyLevel IN (N'High', N'Critical')
GROUP BY ps.PoliceStationName
ORDER BY UrgentComplaints DESC, ps.PoliceStationName;
GO

-- Query 364: Cases by district
PRINT 'Query 364: Cases by district';
SELECT d.DistrictName, COUNT(c.CriminalCaseID) AS CaseCount
FROM dbo.Districts AS d
LEFT JOIN dbo.PoliceStations AS ps ON ps.DistrictID = d.DistrictID
LEFT JOIN dbo.CriminalCases AS c ON c.PoliceStationID = ps.PoliceStationID
GROUP BY d.DistrictName
ORDER BY CaseCount DESC, d.DistrictName;
GO

-- Query 365: Number of police stations in each state
PRINT 'Query 365: Number of police stations in each state';
SELECT s.StateName, COUNT(ps.PoliceStationID) AS StationCount
FROM dbo.States AS s
LEFT JOIN dbo.Districts AS d ON d.StateID = s.StateID
LEFT JOIN dbo.PoliceStations AS ps ON ps.DistrictID = d.DistrictID
GROUP BY s.StateName
ORDER BY StationCount DESC, s.StateName;
GO

-- Query 366: Offence category summary with primary offence counts
PRINT 'Query 366: Offence category summary with primary offence counts';
SELECT cat.CategoryName, COUNT(*) AS TotalEntries, SUM(CASE WHEN co.IsPrimaryOffence = 1 THEN 1 ELSE 0 END) AS AsPrimaryOffence
FROM dbo.CaseOffences AS co
JOIN dbo.CrimeCategories AS cat ON cat.CrimeCategoryID = co.CrimeCategoryID
GROUP BY cat.CategoryName
ORDER BY TotalEntries DESC, cat.CategoryName;
GO

-- Query 367: Open case workload for each officer
PRINT 'Query 367: Open case workload for each officer';
SELECT o.ServiceNumber, o.LastName, COUNT(*) AS OpenCases
FROM dbo.InvestigationAssignments AS ia
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = ia.PoliceOfficerID
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = ia.CriminalCaseID
WHERE ia.ReleasedAt IS NULL AND c.ClosedAt IS NULL
GROUP BY o.ServiceNumber, o.LastName
ORDER BY OpenCases DESC, o.ServiceNumber;
GO

-- Query 368: Cases that currently have more than one investigator
PRINT 'Query 368: Cases that currently have more than one investigator';
SELECT c.CaseNumber, COUNT(*) AS ActiveInvestigators
FROM dbo.InvestigationAssignments AS ia
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = ia.CriminalCaseID
WHERE ia.ReleasedAt IS NULL
GROUP BY c.CaseNumber
HAVING COUNT(*) > 1;
GO

-- Query 369: Property that has not been recovered
PRINT 'Query 369: Property that has not been recovered';
SELECT c.CaseNumber, sp.PropertyDescription, sp.EstimatedValueINR
FROM dbo.StolenProperties AS sp
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = sp.CriminalCaseID
WHERE sp.PropertyStatus = N'Not Recovered';
GO

-- Query 370: Missing person reports that are still open
PRINT 'Query 370: Missing person reports that are still open';
SELECT MissingPersonReportID, ReportedAt, LastSeenLocation, MissingPersonStatus
FROM dbo.MissingPersonReports
WHERE MissingPersonStatus IN (N'Missing', N'Under Review');
GO

-- Query 371: Charge sheets prepared but not yet filed
PRINT 'Query 371: Charge sheets prepared but not yet filed';
SELECT c.CaseNumber, cs.ChargeSheetNumber, cs.ChargeSheetType, cs.PreparedAt
FROM dbo.ChargeSheets AS cs
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = cs.CriminalCaseID
WHERE cs.FiledAt IS NULL;
GO

-- Query 372: Search operations carried out without a recorded authorization
PRINT 'Query 372: Search operations carried out without a recorded authorization';
SELECT CriminalCaseID, SearchStartedAt, SearchLocation, SearchPurpose
FROM dbo.SearchOperations
WHERE SearchAuthorizationID IS NULL;
GO

-- Query 373: Custody transfers where the seal was not simply intact
PRINT 'Query 373: Custody transfers where the seal was not simply intact';
SELECT e.ExhibitNumber, t.TransferredAt, t.SealCondition, t.TransferPurpose
FROM dbo.EvidenceCustodyTransfers AS t
JOIN dbo.EvidenceItems AS e ON e.EvidenceItemID = t.EvidenceItemID
WHERE t.SealCondition <> N'Intact';
GO

-- Query 374: Stolen property with no estimated value
PRINT 'Query 374: Stolen property with no estimated value';
SELECT PropertyDescription, PropertyCategory, PropertyStatus
FROM dbo.StolenProperties
WHERE EstimatedValueINR IS NULL;
GO

-- Query 375: Recovered property that has not been handed back yet
PRINT 'Query 375: Recovered property that has not been handed back yet';
SELECT sp.PropertyDescription, pr.RecoveredAt, pr.RecoveryDescription
FROM dbo.PropertyRecoveries AS pr
JOIN dbo.StolenProperties AS sp ON sp.StolenPropertyID = pr.StolenPropertyID
WHERE pr.ReturnedToOwnerAt IS NULL;
GO

-- Query 376: Prosecutors who are still assigned to a case
PRINT 'Query 376: Prosecutors who are still assigned to a case';
SELECT c.CaseNumber, pt.ProsecutorName, pt.ProsecutorRole, pt.AssignedAt
FROM dbo.ProsecutionTeams AS pt
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = pt.CriminalCaseID
WHERE pt.ReleasedAt IS NULL;
GO

-- Query 377: Court cases where an appeal has been filed
PRINT 'Query 377: Court cases where an appeal has been filed';
SELECT CourtCaseNumber, CourtName, CourtCaseStatus
FROM dbo.CourtCases
WHERE CourtCaseStatus = N'Appeal Filed';
GO

-- Query 378: Bail applications that were rejected
PRINT 'Query 378: Bail applications that were rejected';
SELECT b.OrderReference, a.ArrestMemoReference, b.DecisionDate
FROM dbo.BailOrders AS b
JOIN dbo.Arrests AS a ON a.ArrestID = b.ArrestID
WHERE b.BailDecision = N'Rejected';
GO

-- Query 379: Victim support referrals that are still waiting for action
PRINT 'Query 379: Victim support referrals that are still waiting for action';
SELECT CriminalCaseID, ServiceType, ServiceProviderName, ReferralDate
FROM dbo.VictimSupportServices
WHERE ServiceStatus = N'Referred';
GO

-- Query 380: Station scorecard with complaints, cases and evidence
PRINT 'Query 380: Station scorecard with complaints, cases and evidence';
SELECT ps.PoliceStationName,
       (SELECT COUNT(*) FROM dbo.Complaints AS c WHERE c.PoliceStationID = ps.PoliceStationID) AS Complaints,
       (SELECT COUNT(*) FROM dbo.CriminalCases AS cc WHERE cc.PoliceStationID = ps.PoliceStationID) AS Cases,
       (SELECT COUNT(*) FROM dbo.EvidenceItems AS e JOIN dbo.CriminalCases AS cc2 ON cc2.CriminalCaseID = e.CriminalCaseID WHERE cc2.PoliceStationID = ps.PoliceStationID) AS EvidenceItems
FROM dbo.PoliceStations AS ps
ORDER BY ps.PoliceStationName;
GO


-- ---------------------------------------------------------------------
-- Data quality checks and audit reports (Queries 381-400)
-- ---------------------------------------------------------------------

-- Query 381: Quality check: open cases that carry a closure date (expect 0 rows)
PRINT 'Query 381: Quality check: open cases that carry a closure date (expect 0 rows)';
SELECT CaseNumber, CaseStatus, ClosedAt
FROM dbo.CriminalCases
WHERE CaseStatus NOT IN (N'Closed', N'Disposed') AND ClosedAt IS NOT NULL;
GO

-- Query 382: Quality check: closed or disposed cases with no closure date (expect 0 rows)
PRINT 'Query 382: Quality check: closed or disposed cases with no closure date (expect 0 rows)';
SELECT CaseNumber, CaseStatus
FROM dbo.CriminalCases
WHERE CaseStatus IN (N'Closed', N'Disposed') AND ClosedAt IS NULL;
GO

-- Query 383: Quality check: complaints that arrived after their FIR was registered (expect 0 rows)
PRINT 'Query 383: Quality check: complaints that arrived after their FIR was registered (expect 0 rows)';
SELECT co.ComplaintNumber, co.ReceivedAt, cc.FIRRegisteredAt
FROM dbo.Complaints AS co
JOIN dbo.CriminalCases AS cc ON cc.ComplaintID = co.ComplaintID
WHERE co.ReceivedAt > cc.FIRRegisteredAt;
GO

-- Query 384: Quality check: cases opened before the incident started (expect 0 rows)
PRINT 'Query 384: Quality check: cases opened before the incident started (expect 0 rows)';
SELECT CaseNumber, IncidentStartAt, OpenedAt
FROM dbo.CriminalCases
WHERE OpenedAt < IncidentStartAt;
GO

-- Query 385: Quality check: non-digital evidence that carries a hash (expect 0 rows)
PRINT 'Query 385: Quality check: non-digital evidence that carries a hash (expect 0 rows)';
SELECT ExhibitNumber, DigitalFileHashSHA256
FROM dbo.EvidenceItems
WHERE IsDigitalEvidence = 0 AND DigitalFileHashSHA256 IS NOT NULL;
GO

-- Query 386: Quality check: contact details shared by more than one person
PRINT 'Query 386: Quality check: contact details shared by more than one person';
SELECT ContactType, ContactValue, COUNT(*) AS PeopleSharing
FROM dbo.PersonContactMethods
GROUP BY ContactType, ContactValue
HAVING COUNT(*) > 1;
GO

-- Query 387: Quality check: family names shared by several people (possible duplicates)
PRINT 'Query 387: Quality check: family names shared by several people (possible duplicates)';
SELECT FamilyName, COUNT(*) AS PeopleWithName
FROM dbo.Persons
GROUP BY FamilyName
HAVING COUNT(*) > 1
ORDER BY PeopleWithName DESC;
GO

-- Query 388: Identity check: identifiers that are not yet verified
PRINT 'Query 388: Identity check: identifiers that are not yet verified';
SELECT p.GivenName, p.FamilyName, i.IdentifierType, i.VerificationStatus
FROM dbo.PersonIdentifiers AS i
JOIN dbo.Persons AS p ON p.PersonID = i.PersonID
WHERE i.VerificationStatus <> N'Verified';
GO

-- Query 389: Identity check: identifiers that are verified
PRINT 'Query 389: Identity check: identifiers that are verified';
SELECT p.GivenName, p.FamilyName, i.IdentifierType
FROM dbo.PersonIdentifiers AS i
JOIN dbo.Persons AS p ON p.PersonID = i.PersonID
WHERE i.VerificationStatus = N'Verified';
GO

-- Query 390: Audit trail: number of events by action type
PRINT 'Query 390: Audit trail: number of events by action type';
SELECT ActionType, COUNT(*) AS EventCount
FROM dbo.AuditLog
GROUP BY ActionType
ORDER BY EventCount DESC;
GO

-- Query 391: Audit trail: number of events by record type
PRINT 'Query 391: Audit trail: number of events by record type';
SELECT EntityName, COUNT(*) AS EventCount
FROM dbo.AuditLog
GROUP BY EntityName
ORDER BY EventCount DESC;
GO

-- Query 392: Audit trail: how many roles each enabled user holds
PRINT 'Query 392: Audit trail: how many roles each enabled user holds';
SELECT u.Username, COUNT(ur.SystemRoleID) AS RoleCount
FROM dbo.SystemUsers AS u
LEFT JOIN dbo.SystemUserRoles AS ur ON ur.SystemUserID = u.SystemUserID
WHERE u.IsEnabled = 1
GROUP BY u.Username
ORDER BY RoleCount DESC, u.Username;
GO

-- Query 393: Audit trail: most recent sign-ins
PRINT 'Query 393: Audit trail: most recent sign-ins';
SELECT TOP 5 Username, LastLoginAt
FROM dbo.SystemUsers
WHERE LastLoginAt IS NOT NULL
ORDER BY LastLoginAt DESC;
GO

-- Query 394: Audit trail: accounts that have never signed in
PRINT 'Query 394: Audit trail: accounts that have never signed in';
SELECT Username, IsEnabled, CreatedAt
FROM dbo.SystemUsers
WHERE LastLoginAt IS NULL;
GO

-- Query 395: Audit trail: accounts that are disabled
PRINT 'Query 395: Audit trail: accounts that are disabled';
SELECT Username, LastLoginAt
FROM dbo.SystemUsers
WHERE IsEnabled = 0;
GO

-- Query 396: Audit trail: users who hold the Administrator role
PRINT 'Query 396: Audit trail: users who hold the Administrator role';
SELECT u.Username, ur.GrantedAt
FROM dbo.SystemUserRoles AS ur
JOIN dbo.SystemUsers AS u ON u.SystemUserID = ur.SystemUserID
JOIN dbo.SystemRoles AS r ON r.SystemRoleID = ur.SystemRoleID
WHERE r.RoleName = N'Administrator';
GO

-- Query 397: Quality check: evidence marked as sent for forensics with no request (expect 0 rows)
PRINT 'Query 397: Quality check: evidence marked as sent for forensics with no request (expect 0 rows)';
SELECT e.ExhibitNumber, e.EvidenceStatus
FROM dbo.EvidenceItems AS e
WHERE e.EvidenceStatus = N'Sent for Forensics'
  AND NOT EXISTS (SELECT 1 FROM dbo.ForensicRequests AS fr WHERE fr.EvidenceItemID = e.EvidenceItemID);
GO

-- Query 398: Quality check: arrests produced in court more than 24 hours after arrest (expect 0 rows)
PRINT 'Query 398: Quality check: arrests produced in court more than 24 hours after arrest (expect 0 rows)';
SELECT ArrestMemoReference, ArrestedAt, ProducedBeforeCourtAt
FROM dbo.Arrests
WHERE ProducedBeforeCourtAt IS NOT NULL AND DATEDIFF(hour, ArrestedAt, ProducedBeforeCourtAt) > 24;
GO

-- Query 399: Quality check: lead investigators posted to a different station than the case (expect 0 rows)
PRINT 'Query 399: Quality check: lead investigators posted to a different station than the case (expect 0 rows)';
SELECT c.CaseNumber, o.ServiceNumber, ps.PoliceStationName AS OfficerStation
FROM dbo.InvestigationAssignments AS ia
JOIN dbo.CriminalCases AS c ON c.CriminalCaseID = ia.CriminalCaseID
JOIN dbo.PoliceOfficers AS o ON o.PoliceOfficerID = ia.PoliceOfficerID
JOIN dbo.OfficerAssignments AS oa ON oa.PoliceOfficerID = o.PoliceOfficerID AND oa.IsPrimaryAssignment = 1 AND oa.AssignmentEndDate IS NULL
JOIN dbo.PoliceStations AS ps ON ps.PoliceStationID = oa.PoliceStationID
WHERE ia.AssignmentRole = N'Lead Investigator' AND oa.PoliceStationID <> c.PoliceStationID;
GO

-- Query 400: Quality check: case FIR registered before the case was opened (expect 0 rows)
PRINT 'Query 400: Quality check: case FIR registered before the case was opened (expect 0 rows)';
SELECT CaseNumber, FIRRegisteredAt, OpenedAt
FROM dbo.CriminalCases
WHERE FIRRegisteredAt IS NOT NULL AND FIRRegisteredAt > OpenedAt;
GO


SET ANSI_WARNINGS ON;
GO
PRINT 'Finished: all 400 queries have run.';
GO

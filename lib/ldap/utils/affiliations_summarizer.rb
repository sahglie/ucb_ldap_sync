module Ldap::Utils
  module AffiliationsSummarizer

    def self.summary(affiliations)
      {
        employee?: employee?(affiliations),
        student?: student?(affiliations),
        affiliate?: affiliate?(affiliations)
      }
    end

    EMP_AFFILIATIONS = [
      "EMPLOYEE-TYPE-STAFF",
      "EMPLOYEE-TYPE-ACADEMIC"
    ]

    INELIGIBLE_EMP_AFFILIATIONS = [
      "FORMER-EMPLOYEE"
    ]

    def self.employee?(affiliations)
      is_employee = affiliations.any? { |aff| EMP_AFFILIATIONS.include?(aff) }
      ineligible_employee = affiliations.any? { |aff| INELIGIBLE_EMP_AFFILIATIONS.include?(aff) }
      is_employee && !ineligible_employee
    end

    STU_AFFILIATIONS = [
      "STUDENT-TYPE-REGISTERED"
    ]

    INELIGIBLE_STU_AFFILIATIONS = [
      "FORMER-STUDENT",
      "STUDENT-TYPE-NOT REGISTERED",
      "STUDENT-TYPE-PRESIR",
      "STUDENT-TYPE-NOT-REGISTERED"
    ]

    def self.student?(affiliations)
      is_student = affiliations.any? { |aff| STU_AFFILIATIONS.include?(aff) }
      ineligible_student = affiliations.any? { |aff| INELIGIBLE_STU_AFFILIATIONS.include?(aff) }
      is_student && !ineligible_student
    end

    AFF_AFFILIATIONS = [
      "AFFILIATE-TYPE-AFFILIATED-ORGANIZATION",
      "AFFILIATE-TYPE-AFFILIATED-RESEARCH-INSTITUTE",
      "AFFILIATE-TYPE-CONCURR ENROLL",
      "AFFILIATE-TYPE-INDEPENDENT-CONTRACTOR-CONSULTANT",
      "AFFILIATE-TYPE-LBL/DOE POSTDOC",
      "AFFILIATE-TYPE-RESEARCH ASSOCIATE",
      "AFFILIATE-TYPE-RESEARCH FELLOW",
      "AFFILIATE-TYPE-STAFF EMERITUS",
      "AFFILIATE-TYPE-STAFF OF UC/OP/AFFILIATED ORGS",
      "AFFILIATE-TYPE-UC-EMPLOYEE-DIFFERENT-BU",
      "AFFILIATE-TYPE-VISITING SCHOLAR",
      "AFFILIATE-TYPE-VISITING STU RESEARCHER",
      "AFFILIATE-TYPE-TEMPORARY AGENCY STAFF"
    ]

    INELIGIBLE_AFF_AFFILIATIONS = [
      "FORMER-AFFILIATE"
    ]

    def self.affiliate?(affiliations)
      is_affiliate = affiliations.any? { |aff| AFF_AFFILIATIONS.include?(aff) }
      ineligible_affiliate = affiliations.any? { |aff| INELIGIBLE_AFF_AFFILIATIONS.include?(aff) }
      is_affiliate && !ineligible_affiliate
    end
  end
end

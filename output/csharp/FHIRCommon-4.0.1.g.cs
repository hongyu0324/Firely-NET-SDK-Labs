using System;
using System.Linq;
using System.Collections.Generic;
using Hl7.Cql.Runtime;
using Hl7.Cql.Primitives;
using Hl7.Cql.Abstractions;
using Hl7.Cql.ValueSets;
using Hl7.Cql.Iso8601;
using System.Reflection;
using Hl7.Cql.Operators;
using Hl7.Fhir.Model;
using Range = Hl7.Fhir.Model.Range;
using Task = Hl7.Fhir.Model.Task;

[System.CodeDom.Compiler.GeneratedCode(".NET Code Generation", "5.0.0.0")]
[CqlLibrary("FHIRCommon", "4.0.1")]
public partial class FHIRCommon_4_0_1 : ILibrary, ISingleton<FHIRCommon_4_0_1>
{
    #region Codes

    [CqlCodeDefinition("Birthdate", codeId: "21112-8", codeSystem: "http://loinc.org")]
    public CqlCode Birthdate(CqlContext _) => _Birthdate;
    private static readonly CqlCode _Birthdate = new CqlCode("21112-8", "http://loinc.org");

    [CqlCodeDefinition("Dead", codeId: "419099009", codeSystem: "http://snomed.info/sct")]
    public CqlCode Dead(CqlContext _) => _Dead;
    private static readonly CqlCode _Dead = new CqlCode("419099009", "http://snomed.info/sct");

    [CqlCodeDefinition("ER", codeId: "ER", codeSystem: "http://terminology.hl7.org/CodeSystem/v3-RoleCode")]
    public CqlCode ER(CqlContext _) => _ER;
    private static readonly CqlCode _ER = new CqlCode("ER", "http://terminology.hl7.org/CodeSystem/v3-RoleCode");

    [CqlCodeDefinition("ICU", codeId: "ICU", codeSystem: "http://terminology.hl7.org/CodeSystem/v3-RoleCode")]
    public CqlCode ICU(CqlContext _) => _ICU;
    private static readonly CqlCode _ICU = new CqlCode("ICU", "http://terminology.hl7.org/CodeSystem/v3-RoleCode");

    [CqlCodeDefinition("Billing", codeId: "billing", codeSystem: "http://terminology.hl7.org/CodeSystem/diagnosis-role")]
    public CqlCode Billing(CqlContext _) => _Billing;
    private static readonly CqlCode _Billing = new CqlCode("billing", "http://terminology.hl7.org/CodeSystem/diagnosis-role");

    [CqlCodeDefinition("active", codeId: "active", codeSystem: "http://terminology.hl7.org/CodeSystem/condition-clinical")]
    public CqlCode active(CqlContext _) => _active;
    private static readonly CqlCode _active = new CqlCode("active", "http://terminology.hl7.org/CodeSystem/condition-clinical");

    [CqlCodeDefinition("recurrence", codeId: "recurrence", codeSystem: "http://terminology.hl7.org/CodeSystem/condition-clinical")]
    public CqlCode recurrence(CqlContext _) => _recurrence;
    private static readonly CqlCode _recurrence = new CqlCode("recurrence", "http://terminology.hl7.org/CodeSystem/condition-clinical");

    [CqlCodeDefinition("relapse", codeId: "relapse", codeSystem: "http://terminology.hl7.org/CodeSystem/condition-clinical")]
    public CqlCode relapse(CqlContext _) => _relapse;
    private static readonly CqlCode _relapse = new CqlCode("relapse", "http://terminology.hl7.org/CodeSystem/condition-clinical");

    [CqlCodeDefinition("inactive", codeId: "inactive", codeSystem: "http://terminology.hl7.org/CodeSystem/condition-clinical")]
    public CqlCode inactive(CqlContext _) => _inactive;
    private static readonly CqlCode _inactive = new CqlCode("inactive", "http://terminology.hl7.org/CodeSystem/condition-clinical");

    [CqlCodeDefinition("remission", codeId: "remission", codeSystem: "http://terminology.hl7.org/CodeSystem/condition-clinical")]
    public CqlCode remission(CqlContext _) => _remission;
    private static readonly CqlCode _remission = new CqlCode("remission", "http://terminology.hl7.org/CodeSystem/condition-clinical");

    [CqlCodeDefinition("resolved", codeId: "resolved", codeSystem: "http://terminology.hl7.org/CodeSystem/condition-clinical")]
    public CqlCode resolved(CqlContext _) => _resolved;
    private static readonly CqlCode _resolved = new CqlCode("resolved", "http://terminology.hl7.org/CodeSystem/condition-clinical");

    [CqlCodeDefinition("unconfirmed", codeId: "unconfirmed", codeSystem: "http://terminology.hl7.org/CodeSystem/condition-verification")]
    public CqlCode unconfirmed(CqlContext _) => _unconfirmed;
    private static readonly CqlCode _unconfirmed = new CqlCode("unconfirmed", "http://terminology.hl7.org/CodeSystem/condition-verification");

    [CqlCodeDefinition("provisional", codeId: "provisional", codeSystem: "http://terminology.hl7.org/CodeSystem/condition-verification")]
    public CqlCode provisional(CqlContext _) => _provisional;
    private static readonly CqlCode _provisional = new CqlCode("provisional", "http://terminology.hl7.org/CodeSystem/condition-verification");

    [CqlCodeDefinition("differential", codeId: "differential", codeSystem: "http://terminology.hl7.org/CodeSystem/condition-verification")]
    public CqlCode differential(CqlContext _) => _differential;
    private static readonly CqlCode _differential = new CqlCode("differential", "http://terminology.hl7.org/CodeSystem/condition-verification");

    [CqlCodeDefinition("confirmed", codeId: "confirmed", codeSystem: "http://terminology.hl7.org/CodeSystem/condition-verification")]
    public CqlCode confirmed(CqlContext _) => _confirmed;
    private static readonly CqlCode _confirmed = new CqlCode("confirmed", "http://terminology.hl7.org/CodeSystem/condition-verification");

    [CqlCodeDefinition("refuted", codeId: "refuted", codeSystem: "http://terminology.hl7.org/CodeSystem/condition-verification")]
    public CqlCode refuted(CqlContext _) => _refuted;
    private static readonly CqlCode _refuted = new CqlCode("refuted", "http://terminology.hl7.org/CodeSystem/condition-verification");

    [CqlCodeDefinition("entered-in-error", codeId: "entered-in-error", codeSystem: "http://terminology.hl7.org/CodeSystem/condition-verification")]
    public CqlCode entered_in_error(CqlContext _) => _entered_in_error;
    private static readonly CqlCode _entered_in_error = new CqlCode("entered-in-error", "http://terminology.hl7.org/CodeSystem/condition-verification");

    [CqlCodeDefinition("allergy-active", codeId: "active", codeSystem: "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical")]
    public CqlCode allergy_active(CqlContext _) => _allergy_active;
    private static readonly CqlCode _allergy_active = new CqlCode("active", "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical");

    [CqlCodeDefinition("allergy-inactive", codeId: "inactive", codeSystem: "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical")]
    public CqlCode allergy_inactive(CqlContext _) => _allergy_inactive;
    private static readonly CqlCode _allergy_inactive = new CqlCode("inactive", "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical");

    [CqlCodeDefinition("allergy-resolved", codeId: "resolved", codeSystem: "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical")]
    public CqlCode allergy_resolved(CqlContext _) => _allergy_resolved;
    private static readonly CqlCode _allergy_resolved = new CqlCode("resolved", "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical");

    [CqlCodeDefinition("allergy-unconfirmed", codeId: "unconfirmed", codeSystem: "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification")]
    public CqlCode allergy_unconfirmed(CqlContext _) => _allergy_unconfirmed;
    private static readonly CqlCode _allergy_unconfirmed = new CqlCode("unconfirmed", "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification");

    [CqlCodeDefinition("allergy-confirmed", codeId: "confirmed", codeSystem: "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification")]
    public CqlCode allergy_confirmed(CqlContext _) => _allergy_confirmed;
    private static readonly CqlCode _allergy_confirmed = new CqlCode("confirmed", "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification");

    [CqlCodeDefinition("allergy-refuted", codeId: "refuted", codeSystem: "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification")]
    public CqlCode allergy_refuted(CqlContext _) => _allergy_refuted;
    private static readonly CqlCode _allergy_refuted = new CqlCode("refuted", "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification");

    [CqlCodeDefinition("Community", codeId: "community", codeSystem: "http://terminology.hl7.org/CodeSystem/medicationrequest-category")]
    public CqlCode Community(CqlContext _) => _Community;
    private static readonly CqlCode _Community = new CqlCode("community", "http://terminology.hl7.org/CodeSystem/medicationrequest-category");

    [CqlCodeDefinition("Discharge", codeId: "discharge", codeSystem: "http://terminology.hl7.org/CodeSystem/medicationrequest-category")]
    public CqlCode Discharge(CqlContext _) => _Discharge;
    private static readonly CqlCode _Discharge = new CqlCode("discharge", "http://terminology.hl7.org/CodeSystem/medicationrequest-category");

    #endregion Codes

    #region CodeSystems

    [CqlCodeSystemDefinition("LOINC", codeSystemId: "http://loinc.org", codeSystemVersion: null)]
    public CqlCodeSystem LOINC(CqlContext _) => _LOINC;
    private static readonly CqlCodeSystem _LOINC =
      new CqlCodeSystem("http://loinc.org", null, [
          _Birthdate]);

    [CqlCodeSystemDefinition("SNOMEDCT", codeSystemId: "http://snomed.info/sct", codeSystemVersion: null)]
    public CqlCodeSystem SNOMEDCT(CqlContext _) => _SNOMEDCT;
    private static readonly CqlCodeSystem _SNOMEDCT =
      new CqlCodeSystem("http://snomed.info/sct", null, [
          _Dead]);

    [CqlCodeSystemDefinition("ActCode", codeSystemId: "http://terminology.hl7.org/CodeSystem/v3-ActCode", codeSystemVersion: null)]
    public CqlCodeSystem ActCode(CqlContext _) => _ActCode;
    private static readonly CqlCodeSystem _ActCode =
      new CqlCodeSystem("http://terminology.hl7.org/CodeSystem/v3-ActCode", null, []);

    [CqlCodeSystemDefinition("RoleCode", codeSystemId: "http://terminology.hl7.org/CodeSystem/v3-RoleCode", codeSystemVersion: null)]
    public CqlCodeSystem RoleCode(CqlContext _) => _RoleCode;
    private static readonly CqlCodeSystem _RoleCode =
      new CqlCodeSystem("http://terminology.hl7.org/CodeSystem/v3-RoleCode", null, [
          _ER,
          _ICU]);

    [CqlCodeSystemDefinition("Diagnosis Role", codeSystemId: "http://terminology.hl7.org/CodeSystem/diagnosis-role", codeSystemVersion: null)]
    public CqlCodeSystem Diagnosis_Role(CqlContext _) => _Diagnosis_Role;
    private static readonly CqlCodeSystem _Diagnosis_Role =
      new CqlCodeSystem("http://terminology.hl7.org/CodeSystem/diagnosis-role", null, [
          _Billing]);

    [CqlCodeSystemDefinition("RequestIntent", codeSystemId: "http://terminology.hl7.org/CodeSystem/request-intent", codeSystemVersion: null)]
    public CqlCodeSystem RequestIntent(CqlContext _) => _RequestIntent;
    private static readonly CqlCodeSystem _RequestIntent =
      new CqlCodeSystem("http://terminology.hl7.org/CodeSystem/request-intent", null, []);

    [CqlCodeSystemDefinition("MedicationRequestCategory", codeSystemId: "http://terminology.hl7.org/CodeSystem/medicationrequest-category", codeSystemVersion: null)]
    public CqlCodeSystem MedicationRequestCategory(CqlContext _) => _MedicationRequestCategory;
    private static readonly CqlCodeSystem _MedicationRequestCategory =
      new CqlCodeSystem("http://terminology.hl7.org/CodeSystem/medicationrequest-category", null, [
          _Community,
          _Discharge]);

    [CqlCodeSystemDefinition("ConditionClinicalStatusCodes", codeSystemId: "http://terminology.hl7.org/CodeSystem/condition-clinical", codeSystemVersion: null)]
    public CqlCodeSystem ConditionClinicalStatusCodes(CqlContext _) => _ConditionClinicalStatusCodes;
    private static readonly CqlCodeSystem _ConditionClinicalStatusCodes =
      new CqlCodeSystem("http://terminology.hl7.org/CodeSystem/condition-clinical", null, [
          _active,
          _recurrence,
          _relapse,
          _inactive,
          _remission,
          _resolved]);

    [CqlCodeSystemDefinition("ConditionVerificationStatusCodes", codeSystemId: "http://terminology.hl7.org/CodeSystem/condition-verification", codeSystemVersion: null)]
    public CqlCodeSystem ConditionVerificationStatusCodes(CqlContext _) => _ConditionVerificationStatusCodes;
    private static readonly CqlCodeSystem _ConditionVerificationStatusCodes =
      new CqlCodeSystem("http://terminology.hl7.org/CodeSystem/condition-verification", null, [
          _unconfirmed,
          _provisional,
          _differential,
          _confirmed,
          _refuted,
          _entered_in_error]);

    [CqlCodeSystemDefinition("AllergyIntoleranceClinicalStatusCodes", codeSystemId: "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical", codeSystemVersion: null)]
    public CqlCodeSystem AllergyIntoleranceClinicalStatusCodes(CqlContext _) => _AllergyIntoleranceClinicalStatusCodes;
    private static readonly CqlCodeSystem _AllergyIntoleranceClinicalStatusCodes =
      new CqlCodeSystem("http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical", null, [
          _allergy_active,
          _allergy_inactive,
          _allergy_resolved]);

    [CqlCodeSystemDefinition("AllergyIntoleranceVerificationStatusCodes", codeSystemId: "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification", codeSystemVersion: null)]
    public CqlCodeSystem AllergyIntoleranceVerificationStatusCodes(CqlContext _) => _AllergyIntoleranceVerificationStatusCodes;
    private static readonly CqlCodeSystem _AllergyIntoleranceVerificationStatusCodes =
      new CqlCodeSystem("http://terminology.hl7.org/CodeSystem/allergyintolerance-verification", null, [
          _allergy_unconfirmed,
          _allergy_confirmed,
          _allergy_refuted]);

    #endregion CodeSystems

    #region Functions and Expressions

    [CqlExpressionDefinition("Patient")]
    public Patient Patient(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<Patient>(7046851793845180544L, () => {
            IEnumerable<Patient> a_ = context.Operators.Retrieve<Patient>(new RetrieveParameters(default, default, default, "http://hl7.org/fhir/StructureDefinition/Patient"));
            Patient b_ = context.Operators.SingletonFrom<Patient>(a_);
            return b_;
        });


    [CqlFunctionDefinition("ToInterval")]
    public object ToInterval(CqlContext context, object choice)
    {

        object a_() {
            if (choice is FhirDateTime)
            {
                CqlDateTime b_ = this.ToDateTime(context, choice as FhirDateTime);
                CqlInterval<CqlDateTime> d_ = context.Operators.Interval(b_, b_, true, true);
                return d_ as object;
            }
            else if (choice is Period)
            {
                CqlInterval<CqlDateTime> e_ = this.ToInterval(context, choice as Period);
                return e_ as object;
            }
            else if (choice is Instant)
            {
                CqlDateTime f_ = this.ToDateTime(context, choice as Instant);
                CqlInterval<CqlDateTime> h_ = context.Operators.Interval(f_, f_, true, true);
                return h_ as object;
            }
            else if (choice is Age)
            {
                Patient i_ = this.Patient(context);
                Date j_ = i_?.BirthDateElement;
                CqlDate k_ = this.ToDate(context, j_);
                CqlQuantity l_ = this.ToQuantity(context, (choice as Age) as Quantity);
                CqlDate m_ = context.Operators.Add(k_, l_);
                Date o_ = i_?.BirthDateElement;
                CqlDate p_ = this.ToDate(context, o_);
                CqlDate r_ = context.Operators.Add(p_, l_);
                CqlQuantity s_ = context.Operators.Quantity(1m, "year");
                CqlDate t_ = context.Operators.Add(r_, s_);
                CqlInterval<CqlDate> u_ = context.Operators.Interval(m_, t_, true, false);
                return u_ as object;
            }
            else if (choice is Range)
            {
                Patient v_ = this.Patient(context);
                Date w_ = v_?.BirthDateElement;
                CqlDate x_ = this.ToDate(context, w_);
                Quantity y_ = (choice as Range)?.Low;
                CqlQuantity z_ = this.ToQuantity(context, y_ as Quantity);
                CqlDate aa_ = context.Operators.Add(x_, z_);
                Date ac_ = v_?.BirthDateElement;
                CqlDate ad_ = this.ToDate(context, ac_);
                Quantity ae_ = (choice as Range)?.High;
                CqlQuantity af_ = this.ToQuantity(context, ae_ as Quantity);
                CqlDate ag_ = context.Operators.Add(ad_, af_);
                CqlQuantity ah_ = context.Operators.Quantity(1m, "year");
                CqlDate ai_ = context.Operators.Add(ag_, ah_);
                CqlInterval<CqlDate> aj_ = context.Operators.Interval(aa_, ai_, true, false);
                return aj_ as object;
            }
            else if (choice is Timing)
            {
                CqlInterval<CqlDateTime> ak_ = context.Operators.Message<CqlInterval<CqlDateTime>>(null as CqlInterval<CqlDateTime>, "1", "Error", "Cannot compute a single interval from a Timing type");
                return ak_ as object;
            }
            else if (choice is FhirString)
            {
                CqlInterval<CqlDateTime> al_ = context.Operators.Message<CqlInterval<CqlDateTime>>(null as CqlInterval<CqlDateTime>, "1", "Error", "Cannot compute an interval from a String value");
                return al_ as object;
            }
            else
            {
                return (null as CqlInterval<CqlDateTime>) as object;
            };
        }

        return a_();
    }


    [CqlFunctionDefinition("ToAbatementInterval")]
    public CqlInterval<CqlDateTime> ToAbatementInterval(CqlContext context, Condition condition)
    {

        CqlInterval<CqlDateTime> a_() {

            bool b_() {
                DataType h_ = condition?.Abatement;
                bool i_ = h_ is FhirDateTime;
                return i_;
            }


            bool c_() {
                DataType j_ = condition?.Abatement;
                bool k_ = j_ is Period;
                return k_;
            }


            bool d_() {
                DataType l_ = condition?.Abatement;
                bool m_ = l_ is FhirString;
                return m_;
            }


            bool e_() {
                DataType n_ = condition?.Abatement;
                bool o_ = n_ is Age;
                return o_;
            }


            bool f_() {
                DataType p_ = condition?.Abatement;
                bool q_ = p_ is Range;
                return q_;
            }


            bool g_() {
                DataType r_ = condition?.Abatement;
                bool s_ = r_ is FhirBoolean;
                return s_;
            }

            if (b_())
            {
                DataType t_ = condition?.Abatement;
                CqlDateTime u_ = this.ToDateTime(context, t_ as FhirDateTime);
                CqlDateTime w_ = this.ToDateTime(context, t_ as FhirDateTime);
                CqlInterval<CqlDateTime> x_ = context.Operators.Interval(u_, w_, true, true);
                return x_;
            }
            else if (c_())
            {
                DataType y_ = condition?.Abatement;
                CqlInterval<CqlDateTime> z_ = this.ToInterval(context, y_ as Period);
                return z_;
            }
            else if (d_())
            {
                CqlInterval<CqlDateTime> aa_ = context.Operators.Message<CqlInterval<CqlDateTime>>(null as CqlInterval<CqlDateTime>, "1", "Error", "Cannot compute an interval from a String value");
                return aa_;
            }
            else if (e_())
            {
                Patient ab_ = this.Patient(context);
                Date ac_ = ab_?.BirthDateElement;
                CqlDate ad_ = this.ToDate(context, ac_);
                DataType ae_ = condition?.Abatement;
                CqlQuantity af_ = this.ToQuantity(context, (ae_ as Age) as Quantity);
                CqlDate ag_ = context.Operators.Add(ad_, af_);
                Date ai_ = ab_?.BirthDateElement;
                CqlDate aj_ = this.ToDate(context, ai_);
                CqlQuantity al_ = this.ToQuantity(context, (ae_ as Age) as Quantity);
                CqlDate am_ = context.Operators.Add(aj_, al_);
                CqlQuantity an_ = context.Operators.Quantity(1m, "year");
                CqlDate ao_ = context.Operators.Add(am_, an_);
                CqlInterval<CqlDate> ap_ = context.Operators.Interval(ag_, ao_, true, false);
                CqlDate aq_ = ap_?.low;
                CqlDateTime ar_ = context.Operators.ConvertDateToDateTime(aq_);
                Date at_ = ab_?.BirthDateElement;
                CqlDate au_ = this.ToDate(context, at_);
                CqlQuantity aw_ = this.ToQuantity(context, (ae_ as Age) as Quantity);
                CqlDate ax_ = context.Operators.Add(au_, aw_);
                Date az_ = ab_?.BirthDateElement;
                CqlDate ba_ = this.ToDate(context, az_);
                CqlQuantity bc_ = this.ToQuantity(context, (ae_ as Age) as Quantity);
                CqlDate bd_ = context.Operators.Add(ba_, bc_);
                CqlDate bf_ = context.Operators.Add(bd_, an_);
                CqlInterval<CqlDate> bg_ = context.Operators.Interval(ax_, bf_, true, false);
                CqlDate bh_ = bg_?.high;
                CqlDateTime bi_ = context.Operators.ConvertDateToDateTime(bh_);
                Date bk_ = ab_?.BirthDateElement;
                CqlDate bl_ = this.ToDate(context, bk_);
                CqlQuantity bn_ = this.ToQuantity(context, (ae_ as Age) as Quantity);
                CqlDate bo_ = context.Operators.Add(bl_, bn_);
                Date bq_ = ab_?.BirthDateElement;
                CqlDate br_ = this.ToDate(context, bq_);
                CqlQuantity bt_ = this.ToQuantity(context, (ae_ as Age) as Quantity);
                CqlDate bu_ = context.Operators.Add(br_, bt_);
                CqlDate bw_ = context.Operators.Add(bu_, an_);
                CqlInterval<CqlDate> bx_ = context.Operators.Interval(bo_, bw_, true, false);
                bool? by_ = bx_?.lowClosed;
                Date ca_ = ab_?.BirthDateElement;
                CqlDate cb_ = this.ToDate(context, ca_);
                CqlQuantity cd_ = this.ToQuantity(context, (ae_ as Age) as Quantity);
                CqlDate ce_ = context.Operators.Add(cb_, cd_);
                Date cg_ = ab_?.BirthDateElement;
                CqlDate ch_ = this.ToDate(context, cg_);
                CqlQuantity cj_ = this.ToQuantity(context, (ae_ as Age) as Quantity);
                CqlDate ck_ = context.Operators.Add(ch_, cj_);
                CqlDate cm_ = context.Operators.Add(ck_, an_);
                CqlInterval<CqlDate> cn_ = context.Operators.Interval(ce_, cm_, true, false);
                bool? co_ = cn_?.highClosed;
                CqlInterval<CqlDateTime> cp_ = context.Operators.Interval(ar_, bi_, by_, co_);
                return cp_;
            }
            else if (f_())
            {
                Patient cq_ = this.Patient(context);
                Date cr_ = cq_?.BirthDateElement;
                CqlDate cs_ = this.ToDate(context, cr_);
                DataType ct_ = condition?.Abatement;
                Quantity cu_ = (ct_ as Range)?.Low;
                CqlQuantity cv_ = this.ToQuantity(context, cu_ as Quantity);
                CqlDate cw_ = context.Operators.Add(cs_, cv_);
                Date cy_ = cq_?.BirthDateElement;
                CqlDate cz_ = this.ToDate(context, cy_);
                Quantity db_ = (ct_ as Range)?.High;
                CqlQuantity dc_ = this.ToQuantity(context, db_ as Quantity);
                CqlDate dd_ = context.Operators.Add(cz_, dc_);
                CqlQuantity de_ = context.Operators.Quantity(1m, "year");
                CqlDate df_ = context.Operators.Add(dd_, de_);
                CqlInterval<CqlDate> dg_ = context.Operators.Interval(cw_, df_, true, false);
                CqlDate dh_ = dg_?.low;
                CqlDateTime di_ = context.Operators.ConvertDateToDateTime(dh_);
                Date dk_ = cq_?.BirthDateElement;
                CqlDate dl_ = this.ToDate(context, dk_);
                Quantity dn_ = (ct_ as Range)?.Low;
                CqlQuantity do_ = this.ToQuantity(context, dn_ as Quantity);
                CqlDate dp_ = context.Operators.Add(dl_, do_);
                Date dr_ = cq_?.BirthDateElement;
                CqlDate ds_ = this.ToDate(context, dr_);
                Quantity du_ = (ct_ as Range)?.High;
                CqlQuantity dv_ = this.ToQuantity(context, du_ as Quantity);
                CqlDate dw_ = context.Operators.Add(ds_, dv_);
                CqlDate dy_ = context.Operators.Add(dw_, de_);
                CqlInterval<CqlDate> dz_ = context.Operators.Interval(dp_, dy_, true, false);
                CqlDate ea_ = dz_?.high;
                CqlDateTime eb_ = context.Operators.ConvertDateToDateTime(ea_);
                Date ed_ = cq_?.BirthDateElement;
                CqlDate ee_ = this.ToDate(context, ed_);
                Quantity eg_ = (ct_ as Range)?.Low;
                CqlQuantity eh_ = this.ToQuantity(context, eg_ as Quantity);
                CqlDate ei_ = context.Operators.Add(ee_, eh_);
                Date ek_ = cq_?.BirthDateElement;
                CqlDate el_ = this.ToDate(context, ek_);
                Quantity en_ = (ct_ as Range)?.High;
                CqlQuantity eo_ = this.ToQuantity(context, en_ as Quantity);
                CqlDate ep_ = context.Operators.Add(el_, eo_);
                CqlDate er_ = context.Operators.Add(ep_, de_);
                CqlInterval<CqlDate> es_ = context.Operators.Interval(ei_, er_, true, false);
                bool? et_ = es_?.lowClosed;
                Date ev_ = cq_?.BirthDateElement;
                CqlDate ew_ = this.ToDate(context, ev_);
                Quantity ey_ = (ct_ as Range)?.Low;
                CqlQuantity ez_ = this.ToQuantity(context, ey_ as Quantity);
                CqlDate fa_ = context.Operators.Add(ew_, ez_);
                Date fc_ = cq_?.BirthDateElement;
                CqlDate fd_ = this.ToDate(context, fc_);
                Quantity ff_ = (ct_ as Range)?.High;
                CqlQuantity fg_ = this.ToQuantity(context, ff_ as Quantity);
                CqlDate fh_ = context.Operators.Add(fd_, fg_);
                CqlDate fj_ = context.Operators.Add(fh_, de_);
                CqlInterval<CqlDate> fk_ = context.Operators.Interval(fa_, fj_, true, false);
                bool? fl_ = fk_?.highClosed;
                CqlInterval<CqlDateTime> fm_ = context.Operators.Interval(di_, eb_, et_, fl_);
                return fm_;
            }
            else if (g_())
            {
                DataType fn_ = condition?.Onset;
                object fo_ = this.ToInterval(context, fn_ as object);
                CqlDate fp_ = context.Operators.End((CqlInterval<CqlDate>)fo_);
                FhirDateTime fq_ = condition?.RecordedDateElement;
                CqlDateTime fr_ = FHIRHelpers_4_0_1.Instance.ToDateTime(context, fq_);
                CqlInterval<CqlDateTime> fs_ = context.Operators.Interval(fp_ as CqlDateTime, fr_, true, false);
                return fs_;
            }
            else
            {
                return null as CqlInterval<CqlDateTime>;
            };
        }

        return a_();
    }


    [CqlFunctionDefinition("ToPrevalenceInterval")]
    public CqlInterval<CqlDateTime> ToPrevalenceInterval(CqlContext context, Condition condition)
    {
        DataType a_ = condition?.Onset;
        object b_ = this.ToInterval(context, a_ as object);
        CqlDate c_ = context.Operators.Start((CqlInterval<CqlDate>)b_);
        CqlInterval<CqlDateTime> d_ = this.ToAbatementInterval(context, condition);
        CqlDateTime e_ = context.Operators.End(d_);
        CqlInterval<CqlDateTime> f_ = context.Operators.Interval(c_ as CqlDateTime, e_, true, false);
        return f_;
    }


    [CqlFunctionDefinition("Extensions")]
    public IEnumerable<Extension> Extensions(CqlContext context, DomainResource domainResource, string url)
    {
        List<Extension> a_ = domainResource?.Extension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            bool? i_ = context.Operators.Equal(h_, url);
            return i_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("Extensions")]
    public IEnumerable<Extension> Extensions(CqlContext context, Element element, string url)
    {
        List<Extension> a_ = element?.Extension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            bool? i_ = context.Operators.Equal(h_, url);
            return i_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("Extension")]
    public Extension Extension(CqlContext context, DomainResource domainResource, string url)
    {
        IEnumerable<Extension> a_ = this.Extensions(context, domainResource, url);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("Extension")]
    public Extension Extension(CqlContext context, Element element, string url)
    {
        IEnumerable<Extension> a_ = this.Extensions(context, element, url);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("ModifierExtensions")]
    public IEnumerable<Extension> ModifierExtensions(CqlContext context, DomainResource domainResource, string url)
    {
        List<Extension> a_ = domainResource?.ModifierExtension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            bool? i_ = context.Operators.Equal(h_, url);
            return i_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("ModifierExtensions")]
    public IEnumerable<Extension> ModifierExtensions(CqlContext context, BackboneElement element, string url)
    {
        List<Extension> a_ = element?.ModifierExtension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            bool? i_ = context.Operators.Equal(h_, url);
            return i_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("ModifierExtension")]
    public Extension ModifierExtension(CqlContext context, DomainResource domainResource, string url)
    {
        IEnumerable<Extension> a_ = this.ModifierExtensions(context, domainResource, url);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("ModifierExtension")]
    public Extension ModifierExtension(CqlContext context, BackboneElement element, string url)
    {
        IEnumerable<Extension> a_ = this.ModifierExtensions(context, element, url);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("BaseExtensions")]
    public IEnumerable<Extension> BaseExtensions(CqlContext context, DomainResource domainResource, string id)
    {
        List<Extension> a_ = domainResource?.Extension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            string i_ = context.Operators.Concatenate("http://hl7.org/fhir/StructureDefinition/", id);
            bool? j_ = context.Operators.Equal(h_, i_);
            return j_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("BaseExtensions")]
    public IEnumerable<Extension> BaseExtensions(CqlContext context, Element element, string id)
    {
        List<Extension> a_ = element?.Extension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            string i_ = context.Operators.Concatenate("http://hl7.org/fhir/StructureDefinition/", id);
            bool? j_ = context.Operators.Equal(h_, i_);
            return j_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("BaseExtension")]
    public Extension BaseExtension(CqlContext context, DomainResource domainResource, string id)
    {
        IEnumerable<Extension> a_ = this.BaseExtensions(context, domainResource, id);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("BaseExtension")]
    public Extension BaseExtension(CqlContext context, Element element, string id)
    {
        IEnumerable<Extension> a_ = this.BaseExtensions(context, element, id);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("BaseModifierExtensions")]
    public IEnumerable<Extension> BaseModifierExtensions(CqlContext context, DomainResource domainResource, string id)
    {
        List<Extension> a_ = domainResource?.ModifierExtension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            string i_ = context.Operators.Concatenate("http://hl7.org/fhir/StructureDefinition/", id);
            bool? j_ = context.Operators.Equal(h_, i_);
            return j_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("BaseModifierExtensions")]
    public IEnumerable<Extension> BaseModifierExtensions(CqlContext context, BackboneElement element, string id)
    {
        List<Extension> a_ = element?.ModifierExtension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            string i_ = context.Operators.Concatenate("http://hl7.org/fhir/StructureDefinition/", id);
            bool? j_ = context.Operators.Equal(h_, i_);
            return j_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("BaseModifierExtension")]
    public Extension BaseModifierExtension(CqlContext context, DomainResource domainResource, string id)
    {
        IEnumerable<Extension> a_ = this.BaseModifierExtensions(context, domainResource, id);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("BaseModifierExtension")]
    public Extension BaseModifierExtension(CqlContext context, BackboneElement element, string id)
    {
        IEnumerable<Extension> a_ = this.BaseModifierExtensions(context, element, id);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("USExtensions")]
    public IEnumerable<Extension> USExtensions(CqlContext context, DomainResource domainResource, string id)
    {
        List<Extension> a_ = domainResource?.Extension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            string i_ = context.Operators.Concatenate("http://hl7.org/fhir/us/core/StructureDefinition/", id);
            bool? j_ = context.Operators.Equal(h_, i_);
            return j_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("USExtensions")]
    public IEnumerable<Extension> USExtensions(CqlContext context, Element element, string id)
    {
        List<Extension> a_ = element?.Extension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            string i_ = context.Operators.Concatenate("http://hl7.org/fhir/us/core/StructureDefinition/", id);
            bool? j_ = context.Operators.Equal(h_, i_);
            return j_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("USExtension")]
    public Extension USExtension(CqlContext context, DomainResource domainResource, string id)
    {
        IEnumerable<Extension> a_ = this.USExtensions(context, domainResource, id);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("USExtension")]
    public Extension USExtension(CqlContext context, Element element, string id)
    {
        IEnumerable<Extension> a_ = this.USExtensions(context, element, id);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("USModifierExtensions")]
    public IEnumerable<Extension> USModifierExtensions(CqlContext context, DomainResource domainResource, string id)
    {
        List<Extension> a_ = domainResource?.ModifierExtension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            string i_ = context.Operators.Concatenate("http://hl7.org/fhir/us/core/StructureDefinition/", id);
            bool? j_ = context.Operators.Equal(h_, i_);
            return j_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("USModifierExtensions")]
    public IEnumerable<Extension> USModifierExtensions(CqlContext context, BackboneElement element, string id)
    {
        List<Extension> a_ = element?.ModifierExtension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            string i_ = context.Operators.Concatenate("http://hl7.org/fhir/us/core/StructureDefinition/", id);
            bool? j_ = context.Operators.Equal(h_, i_);
            return j_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("USModifierExtension")]
    public Extension USModifierExtension(CqlContext context, DomainResource domainResource, string id)
    {
        IEnumerable<Extension> a_ = this.USModifierExtensions(context, domainResource, id);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("USModifierExtension")]
    public Extension USModifierExtension(CqlContext context, BackboneElement element, string id)
    {
        IEnumerable<Extension> a_ = this.USModifierExtensions(context, element, id);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("QIExtensions")]
    public IEnumerable<Extension> QIExtensions(CqlContext context, DomainResource domainResource, string id)
    {
        List<Extension> a_ = domainResource?.Extension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            string i_ = context.Operators.Concatenate("http://hl7.org/fhir/us/qicore/StructureDefinition/", id);
            bool? j_ = context.Operators.Equal(h_, i_);
            return j_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("QIExtensions")]
    public IEnumerable<Extension> QIExtensions(CqlContext context, Element element, string id)
    {
        List<Extension> a_ = element?.Extension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            string i_ = context.Operators.Concatenate("http://hl7.org/fhir/us/qicore/StructureDefinition/", id);
            bool? j_ = context.Operators.Equal(h_, i_);
            return j_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("QIExtension")]
    public Extension QIExtension(CqlContext context, DomainResource domainResource, string id)
    {
        IEnumerable<Extension> a_ = this.QIExtensions(context, domainResource, id);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("QIExtension")]
    public Extension QIExtension(CqlContext context, Element element, string id)
    {
        IEnumerable<Extension> a_ = this.QIExtensions(context, element, id);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("QIModifierExtensions")]
    public IEnumerable<Extension> QIModifierExtensions(CqlContext context, DomainResource domainResource, string id)
    {
        List<Extension> a_ = domainResource?.ModifierExtension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            string i_ = context.Operators.Concatenate("http://hl7.org/fhir/us/qicore/StructureDefinition/", id);
            bool? j_ = context.Operators.Equal(h_, i_);
            return j_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("QIModifierExtensions")]
    public IEnumerable<Extension> QIModifierExtensions(CqlContext context, BackboneElement element, string id)
    {
        List<Extension> a_ = element?.ModifierExtension;

        bool? b_(Extension E) {
            FhirUri g_ = E?.UrlElement;
            string h_ = FHIRHelpers_4_0_1.Instance.ToString(context, g_);
            string i_ = context.Operators.Concatenate("http://hl7.org/fhir/us/qicore/StructureDefinition/", id);
            bool? j_ = context.Operators.Equal(h_, i_);
            return j_;
        }

        IEnumerable<Extension> c_ = context.Operators.Where<Extension>((IEnumerable<Extension>)a_, b_);
        Extension d_(Extension E) => E;
        IEnumerable<Extension> e_ = context.Operators.Select<Extension, Extension>(c_, d_);
        IEnumerable<Extension> f_ = context.Operators.Distinct<Extension>(e_);
        return f_;
    }


    [CqlFunctionDefinition("QIModifierExtension")]
    public Extension QIModifierExtension(CqlContext context, DomainResource domainResource, string id)
    {
        IEnumerable<Extension> a_ = this.QIModifierExtensions(context, domainResource, id);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    [CqlFunctionDefinition("QIModifierExtension")]
    public Extension QIModifierExtension(CqlContext context, BackboneElement element, string id)
    {
        IEnumerable<Extension> a_ = this.QIModifierExtensions(context, element, id);
        Extension b_ = context.Operators.SingletonFrom<Extension>(a_);
        return b_;
    }


    #endregion Functions and Expressions

    #region Singleton Lifetime Members

    private FHIRCommon_4_0_1() {}

    public static FHIRCommon_4_0_1 Instance { get; } = new();

    #endregion

    #region ILibrary Implementation

    public string Name => "FHIRCommon";
    public string Version => "4.0.1";
    public ILibrary[] Dependencies => [FHIRHelpers_4_0_1.Instance];

    #endregion ILibrary Implementation

}

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

namespace tmhtc.Demos;

[System.CodeDom.Compiler.GeneratedCode(".NET Code Generation", "5.0.0.0")]
[CqlLibrary("MetabolicSyndromeLogic", "1.0.0")]
public partial class MetabolicSyndromeLogic_1_0_0 : ILibrary, ISingleton<MetabolicSyndromeLogic_1_0_0>
{
    #region Codes

    [CqlCodeDefinition("WaistCircumference", codeId: "21482-5", codeSystem: "http://loinc.org")]
    public CqlCode WaistCircumference(CqlContext _) => _WaistCircumference;
    private static readonly CqlCode _WaistCircumference = new CqlCode("21482-5", "http://loinc.org");

    [CqlCodeDefinition("FastingGlucose", codeId: "1558-6", codeSystem: "http://loinc.org")]
    public CqlCode FastingGlucose(CqlContext _) => _FastingGlucose;
    private static readonly CqlCode _FastingGlucose = new CqlCode("1558-6", "http://loinc.org");

    [CqlCodeDefinition("Triglycerides", codeId: "2571-8", codeSystem: "http://loinc.org")]
    public CqlCode Triglycerides(CqlContext _) => _Triglycerides;
    private static readonly CqlCode _Triglycerides = new CqlCode("2571-8", "http://loinc.org");

    [CqlCodeDefinition("HDL_Cholesterol", codeId: "2085-9", codeSystem: "http://loinc.org")]
    public CqlCode HDL_Cholesterol(CqlContext _) => _HDL_Cholesterol;
    private static readonly CqlCode _HDL_Cholesterol = new CqlCode("2085-9", "http://loinc.org");

    [CqlCodeDefinition("BloodPressure", codeId: "85354-9", codeSystem: "http://loinc.org")]
    public CqlCode BloodPressure(CqlContext _) => _BloodPressure;
    private static readonly CqlCode _BloodPressure = new CqlCode("85354-9", "http://loinc.org");

    [CqlCodeDefinition("SystolicBP", codeId: "8480-6", codeSystem: "http://loinc.org")]
    public CqlCode SystolicBP(CqlContext _) => _SystolicBP;
    private static readonly CqlCode _SystolicBP = new CqlCode("8480-6", "http://loinc.org");

    [CqlCodeDefinition("DiastolicBP", codeId: "8462-4", codeSystem: "http://loinc.org")]
    public CqlCode DiastolicBP(CqlContext _) => _DiastolicBP;
    private static readonly CqlCode _DiastolicBP = new CqlCode("8462-4", "http://loinc.org");

    #endregion Codes

    #region CodeSystems

    [CqlCodeSystemDefinition("LOINC", codeSystemId: "http://loinc.org", codeSystemVersion: null)]
    public CqlCodeSystem LOINC(CqlContext _) => _LOINC;
    private static readonly CqlCodeSystem _LOINC =
      new CqlCodeSystem("http://loinc.org", null, [
          _WaistCircumference,
          _FastingGlucose,
          _Triglycerides,
          _HDL_Cholesterol,
          _BloodPressure,
          _SystolicBP,
          _DiastolicBP]);

    #endregion CodeSystems

    #region Functions and Expressions

    [CqlExpressionDefinition("Patient")]
    public Patient Patient(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<Patient>(3474239932114606876L, () => {
            IEnumerable<Patient> a_ = context.Operators.Retrieve<Patient>(new RetrieveParameters(default, default, default, "http://hl7.org/fhir/StructureDefinition/Patient"));
            Patient b_ = context.Operators.SingletonFrom<Patient>(a_);
            return b_;
        });


    [CqlExpressionDefinition("LatestWaist")]
    public Observation LatestWaist(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<Observation>(2530344019428902365L, () => {
            CqlCode a_ = this.WaistCircumference(context);
            IEnumerable<CqlCode> b_ = context.Operators.ToList<CqlCode>(a_);
            IEnumerable<Observation> c_ = context.Operators.Retrieve<Observation>(new RetrieveParameters(default, default, b_, "http://hl7.org/fhir/StructureDefinition/Observation"));

            bool? d_(Observation O) {
                Code<ObservationStatus> i_ = O?.StatusElement;
                string j_ = FHIRHelpers_4_0_001.Instance.ToString(context, i_);
                string[] k_ = [
                    "final",
                    "amended",
                ];
                bool? l_ = context.Operators.In<string>(j_, (IEnumerable<string>)k_);
                return l_;
            }

            IEnumerable<Observation> e_ = context.Operators.Where<Observation>(c_, d_);

            object f_(Observation @this) {
                DataType m_ = @this?.Effective;
                return m_;
            }

            IEnumerable<Observation> g_ = context.Operators.SortBy<Observation>(e_, f_, System.ComponentModel.ListSortDirection.Descending);
            Observation h_ = context.Operators.First<Observation>(g_);
            return h_;
        });


    [CqlExpressionDefinition("LatestWaistValue")]
    public FhirDecimal LatestWaistValue(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<FhirDecimal>(860487397986753379L, () => {
            Observation a_ = this.LatestWaist(context);
            DataType b_ = a_?.Value;
            FhirDecimal c_ = (b_ as Quantity)?.ValueElement;
            return c_;
        });


    [CqlExpressionDefinition("LatestBP")]
    public Observation LatestBP(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<Observation>(-2658682613432494857L, () => {
            CqlCode a_ = this.BloodPressure(context);
            IEnumerable<CqlCode> b_ = context.Operators.ToList<CqlCode>(a_);
            IEnumerable<Observation> c_ = context.Operators.Retrieve<Observation>(new RetrieveParameters(default, default, b_, "http://hl7.org/fhir/StructureDefinition/Observation"));

            bool? d_(Observation BP) {
                Code<ObservationStatus> i_ = BP?.StatusElement;
                string j_ = FHIRHelpers_4_0_001.Instance.ToString(context, i_);
                string[] k_ = [
                    "final",
                    "amended",
                ];
                bool? l_ = context.Operators.In<string>(j_, (IEnumerable<string>)k_);
                return l_;
            }

            IEnumerable<Observation> e_ = context.Operators.Where<Observation>(c_, d_);

            object f_(Observation @this) {
                DataType m_ = @this?.Effective;
                return m_;
            }

            IEnumerable<Observation> g_ = context.Operators.SortBy<Observation>(e_, f_, System.ComponentModel.ListSortDirection.Descending);
            Observation h_ = context.Operators.First<Observation>(g_);
            return h_;
        });


    [CqlExpressionDefinition("LatestSystolicBPValue")]
    public FhirDecimal LatestSystolicBPValue(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<FhirDecimal>(-4386069410124921824L, () => {
            Observation a_ = this.LatestBP(context);
            List<Observation.ComponentComponent> b_ = a_?.Component;

            bool? c_(Observation.ComponentComponent C) {
                CodeableConcept h_ = C?.Code;
                CqlCode i_ = this.SystolicBP(context);
                bool? j_ = context.Operators.Equivalent(h_, i_);
                return j_;
            }

            IEnumerable<Observation.ComponentComponent> d_ = context.Operators.Where<Observation.ComponentComponent>((IEnumerable<Observation.ComponentComponent>)b_, c_);
            Observation.ComponentComponent e_ = context.Operators.First<Observation.ComponentComponent>(d_);
            DataType f_ = e_?.Value;
            FhirDecimal g_ = (f_ as Quantity)?.ValueElement;
            return g_;
        });


    [CqlExpressionDefinition("LatestDiastolicBPValue")]
    public FhirDecimal LatestDiastolicBPValue(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<FhirDecimal>(-246629348145839707L, () => {
            Observation a_ = this.LatestBP(context);
            List<Observation.ComponentComponent> b_ = a_?.Component;

            bool? c_(Observation.ComponentComponent C) {
                CodeableConcept h_ = C?.Code;
                CqlCode i_ = this.DiastolicBP(context);
                bool? j_ = context.Operators.Equivalent(h_, i_);
                return j_;
            }

            IEnumerable<Observation.ComponentComponent> d_ = context.Operators.Where<Observation.ComponentComponent>((IEnumerable<Observation.ComponentComponent>)b_, c_);
            Observation.ComponentComponent e_ = context.Operators.First<Observation.ComponentComponent>(d_);
            DataType f_ = e_?.Value;
            FhirDecimal g_ = (f_ as Quantity)?.ValueElement;
            return g_;
        });


    [CqlExpressionDefinition("LatestGlucose")]
    public Observation LatestGlucose(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<Observation>(-9170127195040510338L, () => {
            CqlCode a_ = this.FastingGlucose(context);
            IEnumerable<CqlCode> b_ = context.Operators.ToList<CqlCode>(a_);
            IEnumerable<Observation> c_ = context.Operators.Retrieve<Observation>(new RetrieveParameters(default, default, b_, "http://hl7.org/fhir/StructureDefinition/Observation"));

            bool? d_(Observation O) {
                Code<ObservationStatus> i_ = O?.StatusElement;
                string j_ = FHIRHelpers_4_0_001.Instance.ToString(context, i_);
                string[] k_ = [
                    "final",
                    "amended",
                ];
                bool? l_ = context.Operators.In<string>(j_, (IEnumerable<string>)k_);
                return l_;
            }

            IEnumerable<Observation> e_ = context.Operators.Where<Observation>(c_, d_);

            object f_(Observation @this) {
                DataType m_ = @this?.Effective;
                return m_;
            }

            IEnumerable<Observation> g_ = context.Operators.SortBy<Observation>(e_, f_, System.ComponentModel.ListSortDirection.Descending);
            Observation h_ = context.Operators.First<Observation>(g_);
            return h_;
        });


    [CqlExpressionDefinition("LatestGlucoseValue")]
    public FhirDecimal LatestGlucoseValue(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<FhirDecimal>(-9061219051558398795L, () => {
            Observation a_ = this.LatestGlucose(context);
            DataType b_ = a_?.Value;
            FhirDecimal c_ = (b_ as Quantity)?.ValueElement;
            return c_;
        });


    [CqlExpressionDefinition("LatestTG")]
    public Observation LatestTG(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<Observation>(-6856814632739677913L, () => {
            CqlCode a_ = this.Triglycerides(context);
            IEnumerable<CqlCode> b_ = context.Operators.ToList<CqlCode>(a_);
            IEnumerable<Observation> c_ = context.Operators.Retrieve<Observation>(new RetrieveParameters(default, default, b_, "http://hl7.org/fhir/StructureDefinition/Observation"));

            bool? d_(Observation O) {
                Code<ObservationStatus> i_ = O?.StatusElement;
                string j_ = FHIRHelpers_4_0_001.Instance.ToString(context, i_);
                string[] k_ = [
                    "final",
                    "amended",
                ];
                bool? l_ = context.Operators.In<string>(j_, (IEnumerable<string>)k_);
                return l_;
            }

            IEnumerable<Observation> e_ = context.Operators.Where<Observation>(c_, d_);

            object f_(Observation @this) {
                DataType m_ = @this?.Effective;
                return m_;
            }

            IEnumerable<Observation> g_ = context.Operators.SortBy<Observation>(e_, f_, System.ComponentModel.ListSortDirection.Descending);
            Observation h_ = context.Operators.First<Observation>(g_);
            return h_;
        });


    [CqlExpressionDefinition("LatestTGValue")]
    public FhirDecimal LatestTGValue(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<FhirDecimal>(6244636830159613304L, () => {
            Observation a_ = this.LatestTG(context);
            DataType b_ = a_?.Value;
            FhirDecimal c_ = (b_ as Quantity)?.ValueElement;
            return c_;
        });


    [CqlExpressionDefinition("LatestHDL")]
    public Observation LatestHDL(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<Observation>(5586325887595074393L, () => {
            CqlCode a_ = this.HDL_Cholesterol(context);
            IEnumerable<CqlCode> b_ = context.Operators.ToList<CqlCode>(a_);
            IEnumerable<Observation> c_ = context.Operators.Retrieve<Observation>(new RetrieveParameters(default, default, b_, "http://hl7.org/fhir/StructureDefinition/Observation"));

            bool? d_(Observation O) {
                Code<ObservationStatus> i_ = O?.StatusElement;
                string j_ = FHIRHelpers_4_0_001.Instance.ToString(context, i_);
                string[] k_ = [
                    "final",
                    "amended",
                ];
                bool? l_ = context.Operators.In<string>(j_, (IEnumerable<string>)k_);
                return l_;
            }

            IEnumerable<Observation> e_ = context.Operators.Where<Observation>(c_, d_);

            object f_(Observation @this) {
                DataType m_ = @this?.Effective;
                return m_;
            }

            IEnumerable<Observation> g_ = context.Operators.SortBy<Observation>(e_, f_, System.ComponentModel.ListSortDirection.Descending);
            Observation h_ = context.Operators.First<Observation>(g_);
            return h_;
        });


    [CqlExpressionDefinition("LatestHDLValue")]
    public FhirDecimal LatestHDLValue(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<FhirDecimal>(-2973254572457139637L, () => {
            Observation a_ = this.LatestHDL(context);
            DataType b_ = a_?.Value;
            FhirDecimal c_ = (b_ as Quantity)?.ValueElement;
            return c_;
        });


    [CqlExpressionDefinition("Is_Abnormal_Waist")]
    public bool? Is_Abnormal_Waist(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<bool?>(1678964764818728913L, () => {

            bool? a_() {

                bool b_() {
                    Patient d_ = this.Patient(context);
                    Code<AdministrativeGender> e_ = d_?.GenderElement;
                    string f_ = FHIRHelpers_4_0_001.Instance.ToString(context, e_);
                    bool? g_ = context.Operators.Equal(f_, "male");
                    return g_ ?? false;
                }


                bool c_() {
                    Patient h_ = this.Patient(context);
                    Code<AdministrativeGender> i_ = h_?.GenderElement;
                    string j_ = FHIRHelpers_4_0_001.Instance.ToString(context, i_);
                    bool? k_ = context.Operators.Equal(j_, "female");
                    return k_ ?? false;
                }

                if (b_())
                {
                    Observation l_ = this.LatestWaist(context);
                    DataType m_ = l_?.Value;
                    FhirDecimal n_ = (m_ as Quantity)?.ValueElement;
                    decimal? o_ = FHIRHelpers_4_0_001.Instance.ToDecimal(context, n_);
                    bool? p_ = context.Operators.GreaterOrEqual(o_, 90.0m);
                    return p_;
                }
                else if (c_())
                {
                    Observation q_ = this.LatestWaist(context);
                    DataType r_ = q_?.Value;
                    FhirDecimal s_ = (r_ as Quantity)?.ValueElement;
                    decimal? t_ = FHIRHelpers_4_0_001.Instance.ToDecimal(context, s_);
                    bool? u_ = context.Operators.GreaterOrEqual(t_, 80.0m);
                    return u_;
                }
                else
                {
                    return false;
                };
            }

            return a_();
        });


    [CqlExpressionDefinition("Is_Abnormal_BP")]
    public bool? Is_Abnormal_BP(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<bool?>(-7788826528249445303L, () => {
            Observation a_ = this.LatestBP(context);
            List<Observation.ComponentComponent> b_ = a_?.Component;

            bool? c_(Observation.ComponentComponent C) {
                CodeableConcept l_ = C?.Code;
                CqlCode m_ = this.SystolicBP(context);
                bool? n_ = context.Operators.Equivalent(l_, m_);
                DataType o_ = C?.Value;
                FhirDecimal p_ = (o_ as Quantity)?.ValueElement;
                decimal? q_ = FHIRHelpers_4_0_001.Instance.ToDecimal(context, p_);
                bool? r_ = context.Operators.GreaterOrEqual(q_, 130.0m);
                bool? s_ = context.Operators.And(n_, r_);
                return s_;
            }

            IEnumerable<Observation.ComponentComponent> d_ = context.Operators.Where<Observation.ComponentComponent>((IEnumerable<Observation.ComponentComponent>)b_, c_);
            bool? e_ = context.Operators.Exists<Observation.ComponentComponent>(d_);
            List<Observation.ComponentComponent> g_ = a_?.Component;

            bool? h_(Observation.ComponentComponent C) {
                CodeableConcept t_ = C?.Code;
                CqlCode u_ = this.DiastolicBP(context);
                bool? v_ = context.Operators.Equivalent(t_, u_);
                DataType w_ = C?.Value;
                FhirDecimal x_ = (w_ as Quantity)?.ValueElement;
                decimal? y_ = FHIRHelpers_4_0_001.Instance.ToDecimal(context, x_);
                bool? z_ = context.Operators.GreaterOrEqual(y_, 85.0m);
                bool? aa_ = context.Operators.And(v_, z_);
                return aa_;
            }

            IEnumerable<Observation.ComponentComponent> i_ = context.Operators.Where<Observation.ComponentComponent>((IEnumerable<Observation.ComponentComponent>)g_, h_);
            bool? j_ = context.Operators.Exists<Observation.ComponentComponent>(i_);
            bool? k_ = context.Operators.Or(e_, j_);
            return k_;
        });


    [CqlExpressionDefinition("Is_Abnormal_Glucose")]
    public bool? Is_Abnormal_Glucose(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<bool?>(-1770660604515673044L, () => {
            Observation a_ = this.LatestGlucose(context);
            DataType b_ = a_?.Value;
            FhirDecimal c_ = (b_ as Quantity)?.ValueElement;
            decimal? d_ = FHIRHelpers_4_0_001.Instance.ToDecimal(context, c_);
            bool? e_ = context.Operators.GreaterOrEqual(d_, 100.0m);
            return e_;
        });


    [CqlExpressionDefinition("Is_Abnormal_TG")]
    public bool? Is_Abnormal_TG(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<bool?>(1487575114652636267L, () => {
            Observation a_ = this.LatestTG(context);
            DataType b_ = a_?.Value;
            FhirDecimal c_ = (b_ as Quantity)?.ValueElement;
            decimal? d_ = FHIRHelpers_4_0_001.Instance.ToDecimal(context, c_);
            bool? e_ = context.Operators.GreaterOrEqual(d_, 150.0m);
            return e_;
        });


    [CqlExpressionDefinition("Is_Abnormal_HDL")]
    public bool? Is_Abnormal_HDL(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<bool?>(4247009219594819618L, () => {

            bool? a_() {

                bool b_() {
                    Patient d_ = this.Patient(context);
                    Code<AdministrativeGender> e_ = d_?.GenderElement;
                    string f_ = FHIRHelpers_4_0_001.Instance.ToString(context, e_);
                    bool? g_ = context.Operators.Equal(f_, "male");
                    return g_ ?? false;
                }


                bool c_() {
                    Patient h_ = this.Patient(context);
                    Code<AdministrativeGender> i_ = h_?.GenderElement;
                    string j_ = FHIRHelpers_4_0_001.Instance.ToString(context, i_);
                    bool? k_ = context.Operators.Equal(j_, "female");
                    return k_ ?? false;
                }

                if (b_())
                {
                    Observation l_ = this.LatestHDL(context);
                    DataType m_ = l_?.Value;
                    FhirDecimal n_ = (m_ as Quantity)?.ValueElement;
                    decimal? o_ = FHIRHelpers_4_0_001.Instance.ToDecimal(context, n_);
                    bool? p_ = context.Operators.Less(o_, 40.0m);
                    return p_;
                }
                else if (c_())
                {
                    Observation q_ = this.LatestHDL(context);
                    DataType r_ = q_?.Value;
                    FhirDecimal s_ = (r_ as Quantity)?.ValueElement;
                    decimal? t_ = FHIRHelpers_4_0_001.Instance.ToDecimal(context, s_);
                    bool? u_ = context.Operators.Less(t_, 50.0m);
                    return u_;
                }
                else
                {
                    return false;
                };
            }

            return a_();
        });


    [CqlExpressionDefinition("Abnormal_Count")]
    public int? Abnormal_Count(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<int?>(-181680804819046043L, () => {
            int?[] a_ = [
                ((this.Is_Abnormal_Waist(context)) ?? false
                    ? 1
                    : null as int?),
                ((this.Is_Abnormal_BP(context)) ?? false
                    ? 1
                    : null as int?),
                ((this.Is_Abnormal_Glucose(context)) ?? false
                    ? 1
                    : null as int?),
                ((this.Is_Abnormal_TG(context)) ?? false
                    ? 1
                    : null as int?),
                ((this.Is_Abnormal_HDL(context)) ?? false
                    ? 1
                    : null as int?),
            ];
            int? b_ = context.Operators.Count<int?>((IEnumerable<int?>)a_);
            return b_ as int?;
        });


    [CqlExpressionDefinition("Is_Metabolic_Syndrome")]
    public bool? Is_Metabolic_Syndrome(CqlContext context) =>
        ((ICqlContextInternals)context).GetOrCompute<bool?>(4741730896691882580L, () => {
            int? a_ = this.Abnormal_Count(context);
            bool? b_ = context.Operators.GreaterOrEqual(a_, 3);
            return b_;
        });


    #endregion Functions and Expressions

    #region Singleton Lifetime Members

    private MetabolicSyndromeLogic_1_0_0() {}

    public static MetabolicSyndromeLogic_1_0_0 Instance { get; } = new();

    #endregion

    #region ILibrary Implementation

    public string Name => "MetabolicSyndromeLogic";
    public string Version => "1.0.0";
    public ILibrary[] Dependencies => [FHIRHelpers_4_0_001.Instance];

    #endregion ILibrary Implementation

}

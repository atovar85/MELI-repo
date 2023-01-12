
*---------------------------------------------------------------------------------------------------------------------------
*---------------------------------------------------------------------------------------------------------------------------
*---------------------------------------------------------------------------------------------------------------------------
* This GAMS file is part of the Mexican Electricity Long-Term Investment
* Model MELI, written by Alejandro Tovar-Garza.
* The model is published under the Creative Commons 3.0 BY-SA License
* (http://creativecommons.org/licenses/by-sa/3.0/).
* MELI builds upon the work of the European Electricity Market Model EMMA
* which is published under the same license.
* Feedback, remarks, bug reportings, and suggestions are highly welcome:
* atovar@energycolab.com
*---------------------------------------------------------------------------------------------------------------------------
*---------------------------------------------------------------------------------------------------------------------------
*---------------------------------------------------------------------------------------------------------------------------

*================================================================================================================================================
* SETTINGS and COMMAND LINE PARAMETER DEFAULTS
*================================================================================================================================================

$eolcom //
$phantom emptyset
$setenv GdxCompress 1

$if not set inputdir     $setglobal      inputdir Inputdata\
$if not set gdxdir       $setglobal      gdxdir GdxFiles\
$if not set tempdir      $setglobal      tempdir TempFiles\
$if not set resultdir    $setglobal      resultdir Results\

$if not set OPTFILE      $set OPTFILE    1
$if not set HOURS        $set HOURS      48
$if not set TEST         $set TEST       1

*------------------------------------------------------------------------------
*------------------------------------------------------------------------------
*
* 1 SETS
*
*------------------------------------------------------------------------------
*------------------------------------------------------------------------------

*-----------------------------------
* DECLARE SETS
*-----------------------------------

Sets

allt             all possible hours              /1*8760/
*t(allt)                                          /1*%HOURS%/

*$ontext
t(allt)                                         /1*72,
                                                 1009*1080,
                                                 1993*2064,
                                                 2257*2328,
                                                 3217*3288,
                                                 4153*4224,
                                                 5713*5784,
                                                 6001*6072,
                                                 6289*6360,
                                                 6889*6960,
                                                 7753*7824,
                                                 8593*8664/
*$offtext

allsys           all possible systems
sys(allsys)      systems
allr             all possible regions
r(allr)          regions
alltec           all technologies
tec(alltec)      modelled techs
gen(tec)         generation techs
thm(tec)         conventional thermal generators
fos(tec)         fossil fuel
cln(tec)         clean energy
ren(tec)         all renewable energy
vre(tec)         variable renewable energy
dre(tec)         dispatchable renewable energy
hyd(tec)         hydro optimization
sto(tec)         storage techs
dis(tec)         dispatchable techs
allfuel          all fuels
f(allfuel)       fuels
ally             all possible years
y(ally)          years
alls             all secenarios
s                scenarios

* Import sets

$onecho > %tempdir%sets.tmp
         set=allsys       rng=sets!a2         rdim=1
         set=sys          rng=sets!b2         rdim=1
         set=allr         rng=sets!c2         rdim=1
         set=r            rng=sets!d2         rdim=1
         set=alltec       rng=sets!e2         rdim=1
         set=tec          rng=sets!f2         rdim=1
         set=gen          rng=sets!g2         rdim=1
         set=thm          rng=sets!h2         rdim=1
         set=fos          rng=sets!i2         rdim=1
         set=cln          rng=sets!j2         rdim=1
         set=ren          rng=sets!k2         rdim=1
         set=vre          rng=sets!l2         rdim=1
         set=dre          rng=sets!m2         rdim=1
         set=hyd          rng=sets!n2         rdim=1
         set=sto          rng=sets!o2         rdim=1
         set=dis          rng=sets!p2         rdim=1
         set=allfuel      rng=sets!q2         rdim=1
         set=f            rng=sets!r2         rdim=1
         set=ally         rng=sets!s2         rdim=1
         set=y            rng=sets!t2         rdim=1
         set=alls         rng=sets!u2         rdim=1
         set=s            rng=sets!v2         rdim=1
$offecho

$if not set LOADDATA $set LOADDATA  1
$IF %LOADDATA%=='1' $CALL "gdxxrw %inputdir%Input.xlsx @%tempdir%sets.tmp o=%gdxdir%sets.gdx MaxDupeErrors=99 CheckDate ";

* Load GDX file to GAMS
$GDXIN %gdxdir%sets.gdx

$LOADdc allsys sys allr r alltec tec gen thm fos cln ren vre dre hyd sto dis allfuel f ally y alls s


peak             peak and off-peak               /p,op/
day              day of the year                 /1*365/
hourd            hour of the day                 /1*24/
hourw            hour of the week                /1*168/
month            month of the year               /jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec/
weekday09        weekday in 2009                 /mon,tue,wed,thu,fri,sat,sun/
season           season                          /winter,spring,summer,fall/
tpeak(t,peak)    mapping
tday(t,day)      mapping
thourd(t,hourd)  mapping
thourw(t,hourw)  mapping
tmonth(t,month)  mapping
tseason(t,season) mapping
time(allt,peak,day,hourd,hourw,month,season,weekday09)  super-set for time sets

;


ALIAS (r,rr)

*display t, allsys, sys, allr, r, alltec, tec, gen, thm, ren, vre, dre, hyd, sto, dis, allfuel, f, ally, alls, s, ally, y;

set conex(r,rr)
$call gdxxrw.exe %inputdir%Input.xlsx set=conex rng=rnt!a4 rDim=2 o=%gdxdir%sets2.gdx MaxDupeErrors=99
$gdxin %gdxdir%sets2.gdx
$load conex

*display conex;

set ftec(tec,f)
$call gdxxrw.exe %inputdir%Input.xlsx set=ftec rng=capa0!a3 rDim=2 o=%gdxdir%sets3.gdx MaxDupeErrors=99
$gdxin %gdxdir%sets3.gdx
$load ftec

*display ftec;

set freg
$call gdxxrw.exe %inputdir%Input.xlsx set=freg rng=freg!a2 rDim=2 cDim=1 o=%gdxdir%sets4.gdx MaxDupeErrors=99
$gdxin %gdxdir%sets4.gdx
$load freg

*display freg;

set sreg(sys,r)
$call gdxxrw.exe %inputdir%Input.xlsx set=sreg rng=sreg!a4 rDim=2 o=%gdxdir%sets5.gdx MaxDupeErrors=99
$gdxin %gdxdir%sets5.gdx
$load sreg

*display sreg;

*------------------------------------------------------------------------------
*------------------------------------------------------------------------------
*
* PARAMETERS
*
*------------------------------------------------------------------------------
*------------------------------------------------------------------------------

*-----------------------------------
* DECLARE PARAMETERS
*-----------------------------------

Parameters

* Input Parameters
i_load(allt,allr)
i_grow(ally,allr)
i_wind(allt,allr)
i_solar(allt,allr)
i_hydro(allt,allr)
i_geoth(allt,allr)
i_bioen(allt,allr)
i_capa0
i_ntc0(allr,allr)
i_km(allr,allr)
i_ACDC(allr,allr)
i_tech
i_co2
i_fuel

* Model Parameters
annuity(tec,y)        annuity factor                          (l)
as(r,t,y)             must-run                                (GW)
as_res                must-run as share of VRE capacity       (1)
capa0(tec,f,r)        existing net installed capacity         (GW)
cost_fuel(f,y)        fuel cost                               (USD per MMBTU)
cost_var(tec,f,y)     variable cost                           (M$ per GWh)            [loaded as $ per MWh]
cost_inv(tec,y)       annualized investment cost              (M$ per GW*a)
cost_fix(tec,y)       annulized fixed o&m costs               (M$ per GW*a)
cost_NTC              transmission cost                       (M$ per GW_NTC*km*a)
grow(r,y)             annualized load growth                  (1)
load(r,t,y)           hourly load                             (GW)
profile(*,r,t)        generation profiles for wind solar      (1 | sum up to FLH)
inflow(r,t)           inflow of hydro                         (GW)
ntc0(r,rr)            trans capacity from r to rr             (GW) [rescaled]
km(r,rr)              distance between regions                (km)
ACDC(r,rr)            HVAC or HVDC dummy                      (dummy)
rup(tec,y)            ramp-up                                 (1)
rdo(tec,y)            ramp-do                                 (1)
tloss                 transmission losses                     (1)
CR(sto,y)             storage capacity ratio                  (hr)
HR(tec,y)             heat rate                               (MMBTU per MWh)
avail(tec,r,y)        availability of generation              (1)
eff(tec,y)            efficiency of generation                (1)
co2_int(tec,y)        CO2 Intensity                           (ton CO2 per MWht)
co2p(y)               CO2 price                               ($ per ton CO2)
tech_life(tec,y)      technical lifetime                      (years)

investment(tec,y)     investment cost                         ($ per kW)
fix_om(tec,y)         fixed O&M                               ($ per kW*a)
var_om(tec,y)         variable O&M                            ($ per MWh)

pmin(tec,r,y)         minimum capacity                        (1)
pmax(tec,r,y)         maximum capacity                        (1)


* Output Parameters
o_capa(tec,r,s,y)            total installed capacity        (GW)
o_ygene(*,r,s,y)             yearly generation               (TWh per full a)
o_cur(r,s,y)                 curtailed generation            (TWh per full a)
o_invcost(*,r,s,y)           realy investment fost by tec    (M$ per full a)
o_cost(*,r,s,y)              yearly total cost by tec        (M$ per full a)
o_bp(r,s,y)                  base price                      (USD per MWh)
o_pp(r,s,y)                  peak price                      (USD per MWh)
o_op(r,s,y)                  off-peak price                  (USD per MWh)
o_dem(r,s,y)                 yearly demand                   (TWh per full a
o_gen(r,s,y)                 yearly generation               (TWh per full a)
o_CO2(r,s,y)                 CO2 emissions                   (Mt per full a)
o_ASp                        AS price                        (USD per KW full a)
o_revS(tec,r,s,y)            yearly revenues from spot       (M$ per full a)
o_revA(tec,r,s,y)            yearly revenues from AS         (M$ per full a)
o_rev(tec,r,s,y)             total yearly revenues           (M$ per full a)
o_ramp(dis,f,r,t,y)          max ramp

o_reg
o_reg2

o_LCOE
o_MV
o_subsidy
o_share
o_profit

o_hd(hourd,r,s,y)            hourly average

* Reporting Parameters (r_)
r0
r1
r2
r3
r4
r5
r6
r7
r8
r9
r10
r11

* Scalars
th                       /1000/
mn                       /1000000/
little                   /0.00001/
discountrate             /0.07/
lifetime                 /40/
sc                       scale parameter for t>8760

;

*-----------------------------------
* LOAD INPUT PARAMETERS FROM EXCEL
*-----------------------------------

* Specify what to load from Excel

$onecho > %tempdir%input.tmp
         set=time            rng=time!a2:k8761    rdim=8
         par=i_load          rng=load!b11         rdim=1  cdim=1
         par=i_grow          rng=grow!a2          rdim=1  cdim=1
         par=i_wind          rng=wind!b11         rdim=1  cdim=1
         par=i_solar         rng=solar!b11        rdim=1  cdim=1
         par=i_hydro         rng=hydro!b9         rdim=1  cdim=1
         par=i_geoth         rng=geoth!b9         rdim=1  cdim=1
         par=i_bioen         rng=bioen!b9         rdim=1  cdim=1
         par=i_capa0         rng=capa0!a2         rdim=2  cdim=1
$offecho

* Convert XLSX to GDX file and load [Mac Users: COMMENT OUT]
$if not set LOADDATA $set LOADDATA  1
$if %LOADDATA%=='1' $CALL "gdxxrw %inputdir%Input.xlsx @%tempdir%input.tmp o=%gdxdir%input.gdx MaxDupeErrors=99 CheckDate ";

* Load GDX file to GAMS
$GDXIN %gdxdir%input.gdx

$LOADdc time i_load i_grow i_wind i_solar i_hydro i_geoth i_bioen i_capa0

*display time, i_load, i_grow, i_wind, i_solar, i_hydro, i_geoth, i_bioen, i_capa0;

* Import New data format
$onecho >%tempdir%input2.tmp
         par=i_tech       rng=tech!a2           rdim=1   cdim=2
         par=i_fuel       rng=fuel!a2           rdim=1   cdim=2
$offecho

* Convert XLSX to GDX file and load [Mac Users: COMMENT OUT]
$if not set LOADDATA $set LOADDATA  1
$IF %LOADDATA%=='1' $CALL "gdxxrw %inputdir%Input.xlsx cmerge=1 MaxDupeErrors=99 CheckDate @%tempdir%input2.tmp o=%gdxdir%input2.gdx ";

* Load GDX file to GAMS
$GDXIN %gdxdir%input2.gdx

* Load other data
$onUNDF
$LOAD i_tech i_fuel
$offUNDF

*display i_tech, i_fuel;

parameter branch(r,rr,*)
$call gdxxrw.exe %inputdir%Input.xlsx skipEmpty=0 par=branch rng=rnt!a3 rDim=2 cDim=1  o=%gdxdir%input3.gdx
$gdxin %gdxdir%input3.gdx
$onUNDF
$load branch
$offUNDF
;

branch(r,rr,"ntc0")$(branch(r,rr,"ntc0")=0)     =   branch(rr,r,"ntc0");
branch(r,rr,"km")$(branch(r,rr,"km")=0)         =   branch(rr,r,"km");
branch(r,rr,"ACDC")$(branch(r,rr,"ACDC")=0)     =   branch(rr,r,"ACDC");

*display branch;

*-----------------------------------
* ASSIGN MODEL PARAMETERS
*-----------------------------------

* Time-dependend operations
loop(time(t,peak,day,hourd,hourw,month,season,weekday09),
tpeak(t,peak)    = yes;
tday(t,day)      = yes;
thourd(t,hourd)  = yes;
thourw(t,hourw)  = yes;
tmonth(t,month)  = yes;
tseason(t,season)= yes;
);

* Time series parameters (loaded)
grow(r,y)                = i_grow(y,r);
load(r,t,y)              = i_load(t,r) * grow(r,y);
profile("wind",r,t)      = i_wind(t,r);
profile("solar",r,t)     = i_solar(t,r);
profile("hydro",r,t)     = i_hydro(t,r);
profile("geothermal",r,t)= i_geoth(t,r);
profile("bioenergy",r,t) = i_bioen(t,r);

*Scalars
sc                       = 8760 / card(t);

* Technical/Economic data for generators
eff(tec,y)              = i_tech(tec,"Efficiency",y);
HR(tec,y)               = i_tech(tec,"Heat Rate",y);
avail(tec,r,y)          = i_tech(tec,"Availability",y);
investment(tec,y)       = i_tech(tec,"Investment",y);
fix_om(tec,y)           = i_tech(tec,"Fixed O&M cost",y);
var_om(tec,y)           = i_tech(tec,"Variable O&M cost",y);
co2_int(tec,y)          = i_tech(tec,"CO2 Intensity",y);
tech_life(tec,y)        = i_tech(tec,"Technical lifetime",y);
rup(tec,y)              = i_tech(tec,"Ramping Up",y) * 60;
rdo(tec,y)              = i_tech(tec,"Ramping Down",y) * 60;
CR(sto,y)               = i_tech(sto,"Storage Capacity Ratio",y);
pmin(tec,r,y)           = i_tech(tec,"Pmin",y);
pmax(tec,r,y)           = i_tech(tec,"Pmax",y);

co2p(y)                 = i_fuel("co2","Base",y);
cost_fuel(f,y)          = i_fuel(f,"Base",y);

annuity(tec,y)          = ((1+discountrate)**tech_life(tec,y)*discountrate)/((1+discountrate)**tech_life(tec,y)-1);
cost_fix(tec,y)         = fix_om(tec,y) / sc;
cost_inv(tec,y)         = investment(tec,y) * annuity(tec,y) / sc;
cost_var(tec,f,y)$(ftec(tec,f))  = (var_om(tec,y) + cost_fuel(f,y)*HR(tec,y) + co2_int(tec,y) / eff(tec,y) * co2p(y)) / th;

* Interconnector-parameters
ntc0(r,rr)               = branch(r,rr,"ntc0") / th;
km(r,rr)                 = branch(r,rr,"km");
ACDC(r,rr)               = branch(r,rr,"ACDC");


* Cost parameters for interconnections
cost_NTC              = 1.2 *((1+discountrate)**lifetime*discountrate)/((1+discountrate)**lifetime-1) / sc;

* Installed capacity parameters (loaded)
capa0(tec,f,r)          = i_capa0(tec,f,r);

* Ancillary Services [REVISAR]
as(r,t,y)             = 0.1 * load(r,t,y);
as_res                = 0.05;

* Ajdust real availability
*avail("CCGT","07_PEN",y)  = 0.40;
*avail("CCGT","08_BCA",y)  = 0.40;

display time, load, profile, avail, eff, HR, rup, rdo, ntc0, km, ACDC, annuity, cost_fuel, cost_inv, cost_fix, cost_var,cost_NTC, capa0, as, as_res, co2p, CR, pmin, pmax;

*------------------------------------------------------------------------------
*------------------------------------------------------------------------------
*
* VARIABLES AND EQUATIONS
*
*------------------------------------------------------------------------------
*------------------------------------------------------------------------------

*-----------------------------------
* DECLARE VARIABLES
*-----------------------------------

Variables

COST               total system costs    (B$)
SYSCOST(r,y)       system cost           (B$)
INVCOST(r,y)       investment cost       (B$)
FIXCOST(r,y)       fix O&M costs         (B$)
VARCOST(r,y)       variable costs        (B$)
TRACOST(r,y)       new transmission costs(B$)
CAP(tec,f,r,y)     existing capacity     (GW)
INVE(tec,f,r,y)    yearly investment     (GW)
DECO(tec,f,r,y)    yearly disinvestments (GW)
BUILD(tec,f,r,y)   new build capacity    (GW)
RETIRE(tec,f,r,y)  retired capacity      (GW)
NTCinv(r,rr,y)     new trans capacity    (GW)
DEMAND(r,t,y)      load                  (GW)
GENE(tec,f,r,t,y)  generation            (GW)
CURT(vre,f,r,t,y)  curtailment           (GW)
EXPORT(r,rr,t,y)   exports from r to rr  (GW)
IMPORT(rr,r,t,y)   imports from rr to r  (GW)
STO_V(sto,f,r,t,y) storage energy        (GWh)
STO_I(sto,f,r,t,y) in-feed to storage    (GW)
ASC(r,t,y)         ancillary services    (GW)
EMISSIONS(y)       emissions             (MtCO2)
RES(y)             renewable share       (1)
;

* Declare positive variables
Positive Variables CAP,INVE,DECO,BUILD,RETIRE,DEMAND,GENE,STO_V,STO_I,NTCinv,ASC,CURT,RES,EMISSIONS;

*-----------------------------------
* DECLARE AND DEFINE EQUATIONS
*-----------------------------------
Equations

* Objective Function (Costs)
E1                objective function
E2(r,y)           system costs
E3(r,y)           generation investment cost
E3b(r,y)          cum investment cost
E4(r,y)           generation fixed cost
E5(r,y)           generation variable cost
E6(r,y)           transmission investment costs

* Energy Balance constraints
E7(r,t,y)         demand equals generation minus exports plus sto-o minus sto-i

* Capacity constraints
E8(ren,f,r,t,y)   renewable  max availability
E9(thm,f,r,t,y)   conventional max availability
E10(thm,f,r,t,y)  concentional min
E11(vre,f,r,t,y)  curtailment equal or less than generation of VRE

* Ramp up/dn constraints
E12(dis,f,r,t,y)  ramp up-down contraint
E13(dis,f,r,t,y)  ramp up contraint

* Tranmission constraints
E14(r,rr,t,y)     transmission flow direction and losses
E15(r,rr,t,y)     tbd
E16(rr,r,t,y)     tbd
E17(r,rr,y)       tbd

* Ancillary services constraints (to be redefined to spinning reserves)
E18(r,t,y)        must run equations
E19(r,t,y)        must run equations

* Storage constraints
E20(sto,f,r,t,y)  storage equations
E21(sto,f,r,t,y)  storage equations
E22(sto,f,r,t,y)  storage equations
E23(sto,f,r,t,y)  storage equations

* Time consistency of capacity additions and retirements
E29(tec,f,r,y)    time consistency of power system additions
E30(tec,f,r,y)    capacity in first year equals capa0 plus inve
E31(tec,f,r,y)    tbd
E32(tec,f,r,y)    tbd
E33(tec,f,r,y)    tbd
E34(tec,f,r,y)    tbd

* Emissions contraints
E35(y)            yearly emissions

* RES share of total generation
E36(y)            renewable share of total generation

;

* Objective function (Costs)
E1..                           COST                =E=     sum((r,y),SYSCOST(r,y));
E2(r,y)..                      SYSCOST(r,y)        =E=     INVCOST(r,y) + FIXCOST(r,y) + VARCOST(r,y) + TRACOST(r,y);
E3(r,y)$(ord(y)=1)..           INVCOST(r,y)        =E=     sum((tec,f),INVE(tec,f,r,y) * cost_inv(tec,y));
E3b(r,y)$(ord(y)>1)..          INVCOST(r,y)        =E=     INVCOST(r,y-1) + sum((tec,f), INVE(tec,f,r,y) * cost_inv(tec,y));
E4(r,y)..                      FIXCOST(r,y)        =E=     sum((tec,f),CAP(tec,f,r,y) * cost_fix(tec,y));
E5(r,y)..                      VARCOST(r,y)        =E=     sum((tec,f,t),GENE(tec,f,r,t,y) * cost_var(tec,f,y));
E6(r,y)..                      TRACOST(r,y)        =E=     sum(rr,NTCinv(r,rr,y)*km(r,rr)*ACDC(r,rr))/2 * cost_NTC;

* Energy Balance constraints
E7(r,t,y)..                    DEMAND(r,t,y)       =E=     sum((gen,f)$(ftec(gen,f)),GENE(gen,f,r,t,y)) - sum((vre,f)$(ftec(vre,f)),CURT(vre,f,r,t,y)) - sum(rr,EXPORT(r,rr,t,y)) + sum((sto,f)$(ftec(sto,f)),GENE(sto,f,r,t,y)) - sum((sto,f)$(ftec(sto,f)),STO_I(sto,f,r,t,y));

* Capacity constraints
E8(ren,f,r,t,y)..              GENE(ren,f,r,t,y)   =E=     CAP(ren,f,r,y) * profile(ren,r,t) * avail(ren,r,y) * eff(ren,y);
E9(thm,f,r,t,y)..              GENE(thm,f,r,t,y)   =L=     CAP(thm,f,r,y) * avail(thm,r,y);
E10(thm,f,r,t,y)..             GENE(thm,f,r,t,y)   =G=     CAP(thm,f,r,y) * pmin(thm,r,y);
E11(vre,f,r,t,y)..             CURT(vre,f,r,t,y)   =L=     GENE(vre,f,r,t,y);

* Ramp up/dn constraints
E12(dis,f,r,t,y)$(ord(t)>1)..  GENE(dis,f,r,t-1,y) - GENE(dis,f,r,t,y) =L=  rdo(dis,y)*CAP(dis,f,r,y)*avail(dis,r,y);
E13(dis,f,r,t,y)$(ord(t)>1)..  GENE(dis,f,r,t,y) - GENE(dis,f,r,t-1,y) =L=  rup(dis,y)*CAP(dis,f,r,y)*avail(dis,r,y);

* Tranmission constraints
E14(r,rr,t,y)$km(r,rr)..       EXPORT(r,rr,t,y)    =E=     -EXPORT(rr,r,t,y);
E15(r,rr,t,y)$km(r,rr)..       EXPORT(r,rr,t,y)    =L=     ntc0(r,rr) + NTCinv(r,rr,y);
E16(r,rr,t,y)$km(rr,r)..       EXPORT(rr,r,t,y)    =L=     ntc0(rr,r) + NTCinv(rr,r,y);
E17(r,rr,y)$km(r,rr)..         NTCinv(r,rr,y)      =E=     NTCinv(rr,r,y);

* Ancillary services constraints (to be redefined to spinning reserves)
E18(r,t,y)..                   ASC(r,t,y)          =G=     as(r,t,y) + as_res * sum((vre,f),CAP(vre,f,r,y));
E19(r,t,y)..                   ASC(r,t,y)          =L=     sum((dis,f),GENE(dis,f,r,t,y)) - sum((sto,f),STO_I(sto,f,r,t,y));

* Storage equations
E20(sto,f,r,t,y)..             STO_V(sto,f,r,t,y)  =E=     STO_V(sto,f,r,t-1,y)$(ord(t)>1) + STO_I(sto,f,r,t,y) - GENE(sto,f,r,t,y);
E21(sto,f,r,t,y)..             STO_I(sto,f,r,t,y)  =L=     CAP(sto,f,r,y)*avail(sto,r,y);
E22(sto,f,r,t,y)..             GENE(sto,f,r,t,y)   =L=     CAP(sto,f,r,y)*avail(sto,r,y);
E23(sto,f,r,t,y)..             STO_V(sto,f,r,t,y)  =L=     CR(sto,y) * CAP(sto,f,r,y)*avail(sto,r,y);

* Time consistency of capacity additions and retirements
E29(tec,f,r,y)$(ord(y)>1)..    CAP(tec,f,r,y)      =E=     CAP(tec,f,r,y-1) + INVE(tec,f,r,y)$(freg(tec,f,r)) - DECO(tec,f,r,y)$(freg(tec,f,r));
E30(tec,f,r,y)$(ord(y)=1)..    CAP(tec,f,r,y)      =E=     capa0(tec,f,r) + INVE(tec,f,r,y)$(freg(tec,f,r));
E31(tec,f,r,y)$(ord(y)>1)..    BUILD(tec,f,r,y)    =E=     BUILD(tec,f,r,y-1) + INVE(tec,f,r,y)$(freg(tec,f,r));
E32(tec,f,r,y)$(ord(y)=1)..    BUILD(tec,f,r,y)    =E=     INVE(tec,f,r,y)$(freg(tec,f,r));
E33(tec,f,r,y)$(ord(y)>1)..    RETIRE(tec,f,r,y)   =E=     RETIRE(tec,f,r,y-1) + DECO(tec,f,r,y)$(freg(tec,f,r));
E34(tec,f,r,y)$(ord(y)=1)..    RETIRE(tec,f,r,y)   =E=     DECO(tec,f,r,y)$(freg(tec,f,r));

* Enviornmental constraints
E35(y)..                       EMISSIONS(y)        =E=     sum((gen,f,r,t),(GENE(gen,f,r,t,y)) * co2_int(gen,y) / eff(gen,y))  * sc / th;

* Share of Clean Energy constraints
E36(y)..                       RES(y)              =E=    (sum((cln,f,r,t),GENE(cln,f,r,t,y)) - sum((vre,f,r,t),CURT(vre,f,r,t,y))) / sum((r,t),load(r,t,y)) * 100;

*-----------------------------------
* DEFINE THE MODEL
*-----------------------------------

Model MELI /all/;

*-----------------------------------
* GENERAL CONSTRAINTS
*-----------------------------------
DEMAND.FX(r,t,y)                   = load(r,t,y);
EXPORT.FX(r,rr,t,y)$(not km(r,rr)) = 0;
EXPORT.FX(rr,r,t,y)$(not km(rr,r)) = 0;
INVE.FX(tec,f,r,"2020")            = 0;
DECO.FX(ren,f,r,y)                 = 0;
DECO.FX(sto,f,r,y)                 = 0;

as(r,t,y)             = 0;
as_res                = 0;


*-----------------------------------
* SCENARIOS LOOP
*-----------------------------------

loop(s,

*-----------------------------------
* SCENARIO 1: BASE
*-----------------------------------

if(ord(s)=1,

*RES.FX("2020")          = 28;
RES.FX("2025")          = 30.5;
RES.FX("2030")          = 34.6;
RES.FX("2035")          = 41.2;
DECO.FX(tec,f,r,y)      = 0;
NTCinv.FX(r,rr,y)       = 0;

);

*-----------------------------------
* SCENARIO 2: LEAST-COST
*-----------------------------------

if(ord(s)=2,

*RES.FX("2020")          = 28;
RES.UP("2025")          = inf;
RES.UP("2030")          = inf;
RES.UP("2035")          = inf;
DECO.UP(thm,f,r,y)      = inf;
NTCinv.UP(r,rr,y)       = inf;
NTCinv.FX(r,rr,"2020")  = 0;

co2p(y)                 = i_fuel("co2",s,y);
cost_fuel(f,y)          = i_fuel(f,s,y);
cost_var(tec,f,y)$(ftec(tec,f))  = (var_om(tec,y) + cost_fuel(f,y)*HR(tec,y) + co2_int(tec,y) / eff(tec,y) * co2p(y)) / th;
);

*-----------------------------------
* SCENARIO 3: USER-DEF
*-----------------------------------
if(ord(s)=3,

*RES.FX("2020")          = 28;
RES.UP("2025")          = inf;
RES.UP("2030")          = inf;
RES.UP("2035")          = inf;
DECO.UP(thm,f,r,y)      = inf;
NTCinv.UP(r,rr,y)       = inf;
NTCinv.FX(r,rr,"2020")  = 0;

co2p(y)                 = i_fuel("co2",s,y);
cost_fuel(f,y)          = i_fuel(f,s,y);
cost_var(tec,f,y)$(ftec(tec,f))  = (var_om(tec,y) + cost_fuel(f,y)*HR(tec,y) + co2_int(tec,y) / eff(tec,y) * co2p(y)) / th;
);

*-----------------------------------
* OPTIONS
*-----------------------------------

*Your options ------ example
$onecho > cplex.opt
nodefileind 2
workmem 1000
names no
lpmethod=4
*perind=1
*threads 5
*nodesel 2
*varsel 3
*tuning tuning-result.txt
$offecho

MELI.optfile=1;                    // choose the option file
MELI.reslim=8*60*60;               // limits solving time to given seconds
MELI.limrow=0;                     // reduces the size of the listing file
MELI.limcol=0;                     // reduces the size of the listing file
MELI.solprint=0;                   // reduces the size of the listing file
MELI.savepoint=2;                  // saves bases for every solve

*-----------------------------------
* SOLVE THE MODEL
*-----------------------------------

* Specify solution method and solve
Solve MELI USING LP minimizing COST;

*-----------------------------------
* INSPECT RESULTS
*-----------------------------------

*display COST.L, SYSCOST.L, INVCOST.L,FIXCOST.L,VARCOST.L,TRACOST.L, CAP.L, BUILD.L, INVE.L, RETIRE.L, DECO.L, GENE.L, CURT.L, DEMAND.L,EXPORT.L, STO_V.L, STO_I.L, NTCinv.L, DEMAND.M, EMISSIONS.L, RES.L;

*-----------------------------------
* REPORT RESULTS
*-----------------------------------

*===================================
* OUTCOME PARAMETERS
*===================================

* By technology and region

o_capa(tec       ,r,s,y)                  = sum(f,CAP.L(tec,f,r,y))                  + eps;
o_ygene(tec      ,r,s,y)                  = sum((f,t),GENE.L(tec,f,r,t,y)) * sc / th + eps;
o_ygene("STO"    ,r,s,y)                  = sum((sto,f,t),GENE.L(sto,f,r,t,y) - STO_I.L(sto,f,r,t,y)) * sc / th + eps;
o_ygene("REN"    ,r,s,y)                  = sum(ren,o_ygene(ren,r,s,y)) + eps;
o_ygene("CLN"    ,r,s,y)                  = sum(cln,o_ygene(cln,r,s,y)) + eps;
o_ygene("VRE"    ,r,s,y)                  = sum((vre,f,t),GENE.L(vre,f,r,t,y)) * sc / th;
o_ygene("FOS"    ,r,s,y)                  = sum(fos,o_ygene(fos,r,s,y)) + eps;
o_invcost(tec    ,r,s,y)                  = sum(f,INVE.L(tec,f,r,y) * cost_inv(tec,y));
o_invcost(tec    ,r,s,y)$(ord(y)>1)       = o_invcost(tec,r,s,y-1) + sum(f,INVE.L(tec,f,r,y) * cost_inv(tec,y));
o_cost(tec       ,r,s,y)                  = (o_invcost(tec,r,s,y) + sum(f,CAP.L(tec,f,r,y) * cost_fix(tec,y)) + sum((f,t),GENE.L(tec,f,r,t,y) * cost_var(tec,f,y))) * sc;

o_revs(tec       ,r,s,y)                  = sum((f,t),GENE.L(tec,f,r,t,y)  * DEMAND.M(r,t,y)) * sc + eps;
o_LCOE(tec,r,s,y)$(o_ygene(tec,r,s,y)<>0) = o_cost(tec,r,s,y) / o_ygene(tec,r,s,y) + eps;
o_MV(tec,r,s,y)$(o_ygene(tec,r,s,y)<>0)   = o_revs(tec,r,s,y) / o_ygene(tec,r,s,y) + eps;
o_profit(tec,r,s,y)                       = o_MV(tec,r,s,y) - o_LCOE(tec,r,s,y)  + eps;

*display o_capa,o_ygene,o_invcost, o_cost,o_revs,o_LCOE,o_MV,o_profit;

* By region

o_bp(r,s,y)                              = sum(t,DEMAND.M(r,t,y)) / card(t) * th;
o_pp(r,s,y)                              = sum(t$tpeak(t,"p") ,DEMAND.M(r,t,y)) / sum(t$tpeak(t,"p"), 1)  * th  + eps;
o_op(r,s,y)                              = sum(t$tpeak(t,"op"),DEMAND.M(r,t,y)) / sum(t$tpeak(t,"op"), 1) * th  + eps;
o_dem(r,s,y)                             = sum(t,load(r,t,y)) * sc / th;
o_gen(r,s,y)                             = sum(tec,o_ygene(tec,r,s,y));
o_CO2(r,s,y)                             = sum((gen,f,t),(GENE.L(gen,f,r,t,y)) * co2_int(gen,y) / eff(gen,y)) * sc / th;
o_cur(r,s,y)                             = sum((vre,f,t),CURT.L(vre,f,r,t,y)) * sc / th ;
*o_ASp(r,s,y)                             = sum(t,E19.M(r,t,y)) * sc;

o_hd(hourd,r,s,y)                        = sum(t$thourd(t,hourd), DEMAND.M(r,t,y)) / sum(t$thourd(t,hourd),1) * th + eps;

o_ramp(dis,f,r,t,y)$(ord(t)>1)           = GENE.L(dis,f,r,t,y) - GENE.L(dis,f,r,t-1,y);

*display o_bp,o_pp, o_op,o_dem,o_gen,o_CO2,o_cur, o_hd, o_ramp;

*===================================
* MODEL STATS
*===================================

r0("modelstat",s)                           = MELI.modelstat                               +eps;
r0("objective",s)                           = COST.L                                       +eps;
r0("seconds",s)                             = MELI.resusd                                  +eps;
r0("minutes",s)                             = MELI.resusd / 60                             +eps;
r0("hours",s)                               = MELI.resusd / 3600                           +eps;
r0("Iterations",s)                          = MELI.iterusd                                 +eps;
r0("Hours modelled",s)                      = card(t)                                      +eps;
r0("Regions modelled",s)                    = card(r)                                      +eps;
r0("Years modelled",s)                      = card(y)                                      +eps;

*===================================
* SYSTEM SUMMARY
*===================================

r1("TWh","Load"                 ,s,y)       = sum((r,t),load(r,t,y)) / th * sc;
r1("GW","Max Demand"            ,s,y)       = smax(t,sum(r,load(r,t,y)));

r1("Bn USD","Sunk Costs"        ,s,y)       = (sum((tec,f,r),(capa0(tec,f,r) - RETIRE.L(tec,f,r,y)) * cost_inv(tec,"2020"))+(sum((r,rr),ntc0(r,rr)*km(r,rr))/2 * cost_NTC)) * sc / th + eps;
r1("Bn USD","Investment Costs"  ,s,y)       = sum(r,INVCOST.L(r,y)) * sc / th + eps;
r1("Bn USD","Fix O&M Costs"     ,s,y)       = sum(r,FIXCOST.L(r,y)) * sc / th + eps;
r1("Bn USD","Variable Costs"    ,s,y)       = sum(r,VARCOST.L(r,y)) * sc / th + eps;
r1("Bn USD","Transmission Costs",s,y)       = sum(r,TRACOST.L(r,y)) * sc / th + eps;
r1("Bn USD","System Costs"      ,s,y)       = r1("Bn USD","Sunk Costs",s,y) + sum(r,SYSCOST.L(r,y) * sc / th) + eps;

r1("USD/MWh","Base Price"       ,s,y)       = sum(r,o_dem(r,s,y)*o_bp(r,s,y)) / sum(r,o_dem(r,s,y))$(sum(r,o_dem(r,s,y))<>0) + eps;
r1("USD/MWh","Load Price"       ,s,y)       = {sum((r,t), DEMAND.M(r,t,y) * load(r,t,y)) / sum((r,t),load(r,t,y))$(sum((r,t),load(r,t,y))<>0)} * th     +eps;
r1("USD/MWh","Peak Price"       ,s,y)       = sum(r,o_pp(r,s,y)) / card(r)        +eps;
r1("USD/MWh","Off-Peak Price"   ,s,y)       = sum(r,o_op(r,s,y)) / card(r)        +eps;
r1("USD/MWh","SCOE"             ,s,y)       = {r1("Bn USD","System Costs",s,y) / r1("TWh","Load",s,y)$(r1("TWh","Load",s,y)<>0)} * th;

r1("Installed Capacity (GW)",tec,s,y)       = sum((f,r),CAP.L(tec,f,r,y))   + eps;
r1("Installed Capacity (GW)","TOT",s,y)     = sum((tec,f,r),CAP.L(tec,f,r,y)) + eps;
r1("New Capacity (GW)",tec      ,s,y)       = sum((f,r),INVE.L(tec,f,r,y)) + eps;
r1("New Capacity (GW)","TOT"    ,s,y)       = sum((tec,f,r),INVE.L(tec,f,r,y)) + eps;
r1("Retire (GW)",tec            ,s,y)       = sum((f,r),DECO.L(tec,f,r,y))+ eps;
r1("Retire (GW)","TOT"          ,s,y)       = sum((tec,f,r),DECO.L(tec,f,r,y))+ eps;
r1("Generation (TWh)",tec       ,s,y)       = sum((f,r,t),GENE.L(tec,f,r,t,y)) * sc / th   + eps;
r1("Generation (TWh)",vre       ,s,y)       = sum((f,r,t),GENE.L(vre,f,r,t,y) - CURT.L(vre,f,r,t,y)) * sc / th   + eps;
r1("Generation (TWh)","TOT"     ,s,y)       = (sum((tec,f,r,t),GENE.L(tec,f,r,t,y)) - sum((vre,f,r,t),CURT.L(vre,f,r,t,y))) * sc / th   + eps;
r1("Capacity Factor (%)",tec,s,y)$sum((f,r),CAP.L(tec,f,r,y)=0)   =  eps;
r1("Capacity Factor (%)",tec,s,y)$sum((f,r),CAP.L(tec,f,r,y)<>0)  = (sum((f,r,t),GENE.L(tec,f,r,t,y))  * sc) / (sum((f,r),CAP.L(tec,f,r,y))*8760) * 100 + eps;
r1("Capacity Factor (%)",vre,s,y)$sum((f,r),CAP.L(vre,f,r,y)<>0)  = (sum((f,r,t),GENE.L(vre,f,r,t,y) - CURT.L(vre,f,r,t,y))  * sc) / (sum((f,r),CAP.L(vre,f,r,y))*8760) * 100 + eps;

r1("e USD/MWh","Carbon Price"   ,s,y)       = co2p(y) + eps;
r1("e %","RE share"             ,s,y)       = (sum((ren,f,r,t),GENE.L(ren,f,r,t,y)) - sum((vre,f,r,t),CURT.L(vre,f,r,t,y))) / sum((r,t),load(r,t,y)) * 100 + eps;
r1("e %","Clean share"          ,s,y)       = {sum(r,o_ygene("CLN",r,s,y) - o_cur(r,s,y)) / sum(r,o_dem(r,s,y))$(sum(r,o_dem(r,s,y))<>0)} * 100 + eps;
r1("e %","Fossil share"         ,s,y)       = {sum(r,o_ygene("FOS",r,s,y)) / sum(r,o_dem(r,s,y))$(sum(r,o_dem(r,s,y))<>0)} * 100 + eps;
r1("e MtCO2","Emissions"        ,s,y)       = sum(r,o_CO2(r,s,y)) + eps;
r1("e gco2eq/kWh","Carbon intensity",s,y)   = sum(r,o_CO2(r,s,y)) / sum(r,o_dem(r,s,y))$(sum(r,o_dem(r,s,y))<>0) + eps;

r1("f GW/h","Max Ramp"          ,s,y)       = smax(t,sum((dis,f,r),o_ramp(dis,f,r,t,y))) + eps;
r1("f TWh","Curtailment"        ,s,y)       = sum((vre,f,r,t),CURT.L(vre,f,r,t,y) * sc / th) + eps;
r1("f %","As % VRE Gen "        ,s,y)       = {sum((vre,f,r,t),CURT.L(vre,f,r,t,y)) / sum((vre,f,r,t),GENE.L(vre,f,r,t,y))$(sum((vre,f,r,t),GENE.L(vre,f,r,t,y))<>0)} * 100 + eps;
r1("f GWh","BES Capacity"       ,s,y)       = sum((sto,f,r),CAP.L(sto,f,r,y) * CR(sto,y)) + eps;
r1("f GW","Interconnection cap" ,s,y)       = sum((r,rr),(ntc0(r,rr)+NTCinv.L(r,rr,y)))/2 + eps;
r1("f %","Reserve Margin"       ,s,y)       = smin(t,(sum((thm,f,r),CAP.L(thm,f,r,y) * avail(thm,r,y)) + sum((dre,f,r),CAP.L(dre,f,r,y) * avail(dre,r,y)) + sum((vre,f,r),GENE.L(vre,f,r,t,y)) + sum((sto,f,r),GENE.L(sto,f,r,t,y)) - sum((sto,f,r),STO_I.L(sto,f,r,t,y)) - sum((vre,f,r),CURT.L(vre,f,r,t,y)) - sum(r,load(r,t,y))) / sum(r,load(r,t,y))$(sum(r,load(r,t,y))<>0) * 100) + eps;

r1("g Fuel (TWht)",f            ,s,y)       = sum((tec,r,t),GENE.L(tec,f,r,t,y) / eff(tec,y)$(eff(tec,y)<>0)) * sc / th   + eps;


r1("e USD/MWh","Carbon Price"   ,s,y)       = co2p(y) + eps;
r1("e %","RE share"             ,s,y)       = (sum((ren,f,r,t),GENE.L(ren,f,r,t,y)) - sum((vre,f,r,t),CURT.L(vre,f,r,t,y))) / sum((t,r),load(r,t,y))$(sum((t,r),load(r,t,y))<>0) * 100;
r1("e %","Clean share"          ,s,y)       = sum(r,o_ygene("CLN",r,s,y) - o_cur(r,s,y)) / sum(r,o_dem(r,s,y))$(sum(r,o_dem(r,s,y))<>0) * 100;
r1("e %","Fossil share"         ,s,y)       = sum(r,o_ygene("FOS",r,s,y)) / sum(r,o_dem(r,s,y))$(sum(r,o_dem(r,s,y))<>0) * 100;
r1("e MtCO2","Emissions"        ,s,y)       = sum(r,o_CO2(r,s,y)) + eps;
r1("e gco2eq/kWh","Carbon intensity",s,y)   = sum(r,o_CO2(r,s,y)) / sum(r,o_dem(r,s,y))$(sum(r,o_dem(r,s,y))<>0) + eps;

r1("l LCOE (USD/MWh)",tec       ,s,y)$(sum(r,o_ygene(tec,r,s,y)=0)) = eps;
r1("l LCOE (USD/MWh)",tec       ,s,y)$(sum(r,o_ygene(tec,r,s,y)<>0))
                                            =  sum(r,o_cost(tec,r,s,y)) / sum(r,o_ygene(tec,r,s,y)) + eps;
r1("l MV (USD/MWh)",tec         ,s,y)$(sum(r,o_ygene(tec,r,s,y)=0)) = eps;
r1("l MV (USD/MWh)",tec         ,s,y)$(sum(r,o_ygene(tec,r,s,y)<>0))
                                            =  sum(r,o_revs(tec,r,s,y)) / sum(r,o_ygene(tec,r,s,y)) + eps;
r1("l P&L (USD/MWh)",tec        ,s,y)       =  r1("l MV (USD/MWh)",tec,s,y) - r1("l LCOE (USD/MWh)",tec,s,y) + eps;


*===================================
* SYSTEM HOURLY DISPATCH AND MARGINAL PRICE
*===================================
* Hourly Dispatch
r2(t,sys,s,y,"DEMAND")        = sum(r$(sreg(sys,r)),DEMAND.L(r,t,y))                 + eps;
r2(t,sys,s,y,"CURT")          = -sum((vre,f,r)$(sreg(sys,r)),CURT.L(vre,f,r,t,y))    + eps;
r2(t,sys,s,y,gen)             = sum((f,r)$(sreg(sys,r)),GENE.L(gen,f,r,t,y))         + eps;
r2(t,sys,s,y,"Di/Ch (+/-)")   = sum((sto,f,r)$(sreg(sys,r)),GENE.L(sto,f,r,t,y) - STO_I.L(sto,f,r,t,y)) + eps;
r2(t,sys,s,y,"IMP/EXP(+/-)")  = sum((r,rr)$(sreg(sys,r)),-EXPORT.L(r,rr,t,y))        + eps;
r2(t,sys,s,y,"DFLEX")         = sum(r$(sreg(sys,r)),DEMAND.L(r,t,y))                  + eps;
r2(t,sys,s,y,"STO_V.L")       = sum((sto,f,r)$(sreg(sys,r)),STO_V.L(sto,f,r,t,y))    + eps;

* Marginal Price
r3(t,r,s,y)                   = DEMAND.M(r,t,y) * th + eps;


*===================================
* SYSTEM NETWORK
*===================================

* NTC
r4(r,rr,s,y)$(conex(r,rr))   = ntc0(r,rr) + NTCinv.L(r,rr,y)   + eps;

* Net Exports
r5(r,s,y)                    = sum((rr,t),EXPORT.L(r,rr,t,y)) / th * sc;

* NTC Utilization rate
r6(r,rr,s,y)$(conex(r,rr))   =  (sum(t$(EXPORT.L(r,rr,t,y)<>0),abs(EXPORT.L(r,rr,t,y)) /
                                (ntc0(r,rr)+NTCinv.L(r,rr,y)))/card(t)) * 100 + eps;

*===================================
* SUMMARY BY REGION
*===================================

r7("TWh","Load"                 ,r,s,y)       = sum(t,load(r,t,y)) / th * sc;
r7("GW","Max Demand"            ,r,s,y)       = smax(t,load(r,t,y));

r7("Bn USD","Sunk Costs"        ,r,s,y)       = (sum((tec,f),(capa0(tec,f,r) - RETIRE.L(tec,f,r,y)) * cost_inv(tec,"2020"))+(sum(rr,ntc0(r,rr)*km(r,rr))/2 * cost_NTC)) * sc / th + eps;
r7("Bn USD","Investment Costs"  ,r,s,y)       = INVCOST.L(r,y) * sc / th + eps;
r7("Bn USD","Fix O&M Costs"     ,r,s,y)       = FIXCOST.L(r,y) * sc / th + eps;
r7("Bn USD","Variable Costs"    ,r,s,y)       = VARCOST.L(r,y) * sc / th + eps;
r7("Bn USD","Transmission Costs",r,s,y)       = TRACOST.L(r,y) * sc / th + eps;
r7("Bn USD","System Costs"      ,r,s,y)       = r7("Bn USD","Sunk Costs",r,s,y) + (SYSCOST.L(r,y) * sc / th) + eps;

r7("USD/MWh","SCOE"             ,r,s,y)       = r7("Bn USD","System Costs",r,s,y) / r7("TWh","Load",r,s,y)$(r7("TWh","Load",r,s,y)<>0) * th;
r7("USD/MWh","Base Price"       ,r,s,y)       = o_dem(r,s,y)*o_bp(r,s,y) / o_dem(r,s,y)$(o_dem(r,s,y)<>0) + eps;
r7("USD/MWh","Load Price"       ,r,s,y)       = sum(t, DEMAND.M(r,t,y) * load(r,t,y)) / sum(t,load(r,t,y))$(sum(t,load(r,t,y))<>0) * th     +eps;
r7("USD/MWh","Peak Price"       ,r,s,y)       = o_pp(r,s,y) +eps;
r7("USD/MWh","Off-Peak Price"   ,r,s,y)       = o_op(r,s,y) +eps;

r7("Installed Capacity (GW)",tec,r,s,y)       = sum(f,CAP.L(tec,f,r,y))   + eps;
r7("Installed Capacity (GW)","TOT",r,s,y)     = sum((tec,f),CAP.L(tec,f,r,y)) + eps;
r7("New Capacity (GW)",tec      ,r,s,y)       = sum(f,INVE.L(tec,f,r,y)) + eps;
r7("New Capacity (GW)","TOT"    ,r,s,y)       = sum((tec,f),INVE.L(tec,f,r,y)) + eps;
r7("Retire (GW)",tec            ,r,s,y)       = sum(f,RETIRE.L(tec,f,r,y))+ eps;
r7("Retire (GW)","TOT"          ,r,s,y)       = sum((tec,f),RETIRE.L(tec,f,r,y))+ eps;
r7("Generation (TWh)",tec       ,r,s,y)       = sum((f,t),GENE.L(tec,f,r,t,y)) * sc / th   + eps;
r7("Generation (TWh)",vre       ,r,s,y)       = sum((f,t),GENE.L(vre,f,r,t,y) - CURT.L(vre,f,r,t,y)) * sc / th   + eps;
r7("Generation (TWh)","TOT"     ,r,s,y)       = (sum((tec,f,t),GENE.L(tec,f,r,t,y)) - sum((vre,f,t),CURT.L(vre,f,r,t,y))) * sc / th   + eps;
r7("Capacity Factor (%)",tec,r,s,y)$sum(f,CAP.L(tec,f,r,y)=0)  =  eps;
r7("Capacity Factor (%)",tec,r,s,y)$sum(f,CAP.L(tec,f,r,y)>0)  = (sum((f,t),GENE.L(tec,f,r,t,y))  * sc) / (sum(f,CAP.L(tec,f,r,y))*8760)$((sum(f,CAP.L(tec,f,r,y))*8760)<>0) * 100 + eps;
r7("Capacity Factor (%)",vre,r,s,y)$sum(f,CAP.L(vre,f,r,y)>0)  = (sum((f,t),GENE.L(vre,f,r,t,y) - CURT.L(vre,f,r,t,y))  * sc) / (sum(f,CAP.L(vre,f,r,y))*8760)$((sum(f,CAP.L(vre,f,r,y))*8760)<>0) * 100 + eps;

r7("e USD/MWh","Carbon Price"   ,r,s,y)       = co2p(y) + eps;
r7("e %","RE share"             ,r,s,y)       = (sum((ren,f,t),GENE.L(ren,f,r,t,y)) - sum((vre,f,t),CURT.L(vre,f,r,t,y))) / sum(t,load(r,t,y))$(sum(t,load(r,t,y))<>0) * 100 + eps;
r7("e %","Clean share"          ,r,s,y)       = (o_ygene("CLN",r,s,y) - o_cur(r,s,y)) / o_dem(r,s,y)$(o_dem(r,s,y)<>0) * 100 + eps;
r7("e %","Fossil share"         ,r,s,y)       = (o_ygene("FOS",r,s,y)) / o_dem(r,s,y)$(o_dem(r,s,y)<>0) * 100 + eps;
r7("e MtCO2","Emissions"        ,r,s,y)       = o_CO2(r,s,y) + eps;
r7("e gco2eq/kWh","Carbon intensity",r,s,y)   = o_CO2(r,s,y) / o_dem(r,s,y)$(o_dem(r,s,y)<>0) + eps;

r7("f GW/h","Max Ramp"          ,r,s,y)       = smax(t,sum((dis,f),o_ramp(dis,f,r,t,y))) + eps;
r7("f TWh","Curtailment"        ,r,s,y)       = sum((vre,f,t),CURT.L(vre,f,r,t,y) * sc / th) + eps;
r7("f %","As % VRE Gen "        ,r,s,y)       = {sum((vre,f,t),CURT.L(vre,f,r,t,y)) / sum((vre,f,t),GENE.L(vre,f,r,t,y))$(sum((vre,f,t),GENE.L(vre,f,r,t,y))<>0)} * 100 + eps;
r7("f GWh","BES Capacity"       ,r,s,y)       = sum((sto,f),CAP.L(sto,f,r,y) * CR(sto,y)) + eps;
r7("f GW","Interconnection cap" ,r,s,y)       = sum(rr,(ntc0(r,rr)+NTCinv.L(r,rr,y)))/2;
r7("f %","Reserve Margin"       ,r,s,y)       = smin(t,((sum((thm,f),CAP.L(thm,f,r,y) * avail(thm,r,y)) + sum((ren,f),CAP.L(ren,f,r,y) * profile(ren,r,t) * avail(ren,r,y) * eff(ren,y))) - load(r,t,y)) / load(r,t,y)$(load(r,t,y)<>0)) * 100 + eps;

r7("g Fuel (TWht)",f            ,r,s,y)       = sum((tec,t),GENE.L(tec,f,r,t,y) / eff(tec,y)$(eff(tec,y)<>0)) * sc / th   + eps;

r7("l LCOE (USD/MWh)",tec       ,r,s,y)$(o_ygene(tec,r,s,y)=0) = eps;
r7("l LCOE (USD/MWh)",tec       ,r,s,y)$(o_ygene(tec,r,s,y)<>0)
                                              =  o_LCOE(tec,r,s,y) + eps;
r7("l MV (USD/MWh)",tec         ,r,s,y)$(o_ygene(tec,r,s,y)=0) = eps;
r7("l MV (USD/MWh)",tec         ,r,s,y)$(o_ygene(tec,r,s,y)<>0)
                                              =  o_MV(tec,r,s,y) + eps;
r7("l P&L (USD/MWh)",tec        ,r,s,y)       =  o_profit(tec,r,s,y) + eps;

* Price-setting fuel

r8(thm,f                       ,r,s,y)$(ftec(thm,f))  = sum(t$(DEMAND.M(r,t,y)=cost_var(thm,f,y)),1) /card(t)*100 +eps;
r8("zero","zero"               ,r,s,y)        = sum(t$(DEMAND.M(r,t,y)=0),1) /card(t)*100        +eps;
r8("other","other"             ,r,s,y)        = 100 - sum((thm,f),r8(thm,f,r,s,y)) - r8("zero","zero",r,s,y)  +eps;


*===================================
* CLOSES LOOP
*===================================
);  // closes loop (s)

display r0,r1,r2,r3,r4,r5,r6,r7,r8;

*================================================================================================================================================
* OUTPUT GDX FILES
*================================================================================================================================================

* Export results into GDX file
execute_UNLOAD '%gdxdir%Results.gdx'
r0
r1
r2
r3
r4
r5
r6
r7
r8
;

*-----------------------------------
* EXPORT OUTPUT PARAMETERS TO EXCEL
*-----------------------------------

* Specify how files should be organized in Excel (sheet, cells, orientation)
$onecho > %tempdir%temp_exceloutput.tmp
par=r1       rng=sys!a3           rdim=2
par=r2       rng=dis!a3           cdim=4
par=r3       rng=lmp!a6           rdim=1
par=r4       rng=trn!a3           rdim=2
par=r5       rng=exp!a3           rdim=1
par=r6       rng=uti!a3           rdim=2
par=r7       rng=reg!a3           rdim=2
par=r8       rng=pst!a3           rdim=2
par=r0       rng=sts!a3           rdim=1
$offecho


* Convert GDX file into XLS file [Mac Users: COMMENT OUT]
execute "XLSTALK -c  %resultdir%Results.xlsx"
execute "GDXXRW.EXE  i=%gdxdir%Results.gdx   EpsOut=0   o=%resultdir%Results.xlsx   @%tempdir%temp_exceloutput.tmp"


* Convert GDX file into CSV files
execute "$call gdxdump %gdxdir%Results.gdx output=r1.csv        symb=r1       format=csv"
execute "$call gdxdump %gdxdir%Results.gdx output=r2.csv        symb=r2       format=csv"
execute "$call gdxdump %gdxdir%Results.gdx output=r3.csv        symb=r3       format=csv"
execute "$call gdxdump %gdxdir%Results.gdx output=r4.csv        symb=r4       format=csv"
execute "$call gdxdump %gdxdir%Results.gdx output=r5.csv        symb=r5       format=csv"
execute "$call gdxdump %gdxdir%Results.gdx output=r6.csv        symb=r6       format=csv"
execute "$call gdxdump %gdxdir%Results.gdx output=r7.csv        symb=r7       format=csv"
execute "$call gdxdump %gdxdir%Results.gdx output=r8.csv        symb=r8       format=csv"
execute "$call gdxdump %gdxdir%Results.gdx output=r0.csv        symb=r0       format=csv"


*-----------------------------------
* END!
*-----------------------------------


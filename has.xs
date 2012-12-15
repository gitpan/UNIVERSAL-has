#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

MODULE = UNIVERSAL::has        PACKAGE = UNIVERSAL::has        

AV *
xs_has(sv)
    SV * sv
PROTOTYPE: $
PREINIT:
    HV *pkg = NULL;
    AV *linear_av;

    HV *cstash;
    SV **linear_svp;
    SV *linear_sv;

    HE *entry;
    SV *val;

    I32 len;

    char *txt;
CODE:
    RETVAL = newAV();
    sv_2mortal((SV*)RETVAL);

    SvGETMAGIC(sv);

    if (!SvOK(sv) || !SvOBJECT(sv))
        XSRETURN_EMPTY;

    pkg = SvSTASH(sv);

    if (pkg) {

        linear_av = mro_get_linear_isa(pkg); /* has ourselves at the top of the list */

        linear_svp = AvARRAY(linear_av);
        items = AvFILLp(linear_av);

        while (items--) {
            linear_sv = *linear_svp++;
            cstash = gv_stashsv(linear_sv, 0);

            if (cstash) {
                hv_iterinit(cstash);
                while ((entry = hv_iternext(cstash))) {
                    val = hv_iterval(cstash,entry);

                    if (val && SvTYPE(cv) == SVt_PVCV) {
                        txt = hv_iterkey(entry,&len);

                        av_push(RETVAL, newSVpv(txt,0));
                    }
                }
            }
        }
    }
OUTPUT:
    RETVAL

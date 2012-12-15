#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

MODULE = UNIVERSAL::has		PACKAGE = UNIVERSAL::has		

SV *
xs_has(obj)
    SV * obj
INIT:
    AV * results;

    results = (AV *)sv_2mortal((SV *)newAV());
CODE:
    SV   *sv;
    HV   *pkg = NULL;
    AV* linear_av;

    sv = obj;

    SvGETMAGIC(sv);

    if (!SvOK(sv) || !(SvROK(sv) || (SvPOK(sv) && SvCUR(sv))
		|| (SvGMAGICAL(sv) && SvPOKp(sv) && SvCUR(sv))))
	XSRETURN_UNDEF;

    if (SvROK(sv)) {
        sv = MUTABLE_SV(SvRV(sv));
        if (SvOBJECT(sv))
            pkg = SvSTASH(sv);
    }
    else {
        pkg = gv_stashsv(sv, 0);
    }

    if (pkg) {
	    HV* cstash;
	    SV** linear_svp;
	    SV* linear_sv;

	    linear_av = mro_get_linear_isa(pkg); /* has ourselves at the top of the list */

	    linear_svp = AvARRAY(linear_av);
	    items = AvFILLp(linear_av);
	    while (items--) {
		    linear_sv = *linear_svp++;
		    cstash = gv_stashsv(linear_sv, 0);

		    if (cstash) {
			    HE *entry;
			    const I32 riter = HvRITER_get(cstash);
			    HE * const eiter = HvEITER_get(cstash);
			    hv_iterinit(cstash);
			    while ((entry = hv_iternext_flags(cstash, 0))) {
				SV *val = hv_iterval(cstash,entry);

				if (val) {
				    STRLEN len;
				    char *txt = hv_iterkey(entry,&len);

				    av_push(results, newSVpv(txt,0));
				}
			    }
			    HvRITER_set(cstash, riter);
			    HvEITER_set(cstash, eiter);
	    	   }
	   }
    }

    RETVAL = newRV((SV *)results);
OUTPUT:
    RETVAL

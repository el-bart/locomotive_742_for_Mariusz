# wiering diagram

## power regulation
DC/DC is not an option, as they tend to shutdown when too much power is requested.
however current from a small PV is, by definition, low.

therefor regular, linear stabilization is used.
LM317 has been selected, with R1=2.2k and R2=5.1k.
this gives `Uout=1.25[V]*(1+R2/R1)~=4.15[V]`.
not that these values may need some adjusting as +-5% resistors will not give exact voltage.
there's also a rectifying diode that will drop by another `0.2[V]`.

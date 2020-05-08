cd "D:\gis"
spshape2dta y11, replace
use y11.dta, clear
spset
spmatrix  create contiguity W, replace
spregress confirm GDP pd POI, dvarlag(W) gs2sls
preserve
predict y0
replace pd = 100 if cname == "南山区"
predict y1
generate double y_diff = y1 - y0
grmap, activate
grmap y_diff, title("Global spillover")
restore
estat impact
margins,at(pd =generate(pd))
margins,at(pd =generate(pd-1))
local lambda = _b[W:confirm]
predict xb0, xb
replace pd = 100 if cname == "南山区"
predict xb1, xb
generate dy=xb1 - xb0
format dy %9.2f
generate Wy = dy
generate lamWy = dy
grmap dy
graph export dy_0.png, replace
local input dy_0.png
forvalues p=1/3 {
spgenerate tmp = W*Wy
        replace lamWy = `lambda'^`p'*tmp
		replace Wy = tmp
		replace dy = dy + lamWy
        grmap dy
        graph export dy_`p'.png, replace
        local input `input' dy_`p'.png
        drop tmp
}
shell convert -delay 150 -loop 0 `input' glsp.gif
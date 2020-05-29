clear all
cd "D:\gis6"

***01矩阵
spwmatrix import using m1.gal, wname(wcontig)
matlist wcontig

use datd.dta
sum confirm GDP PD flow
gen lnconfirm=ln(confirm)
gen lnGDP=ln(GDP)
gen lnPD=ln(PD)
gen lnflow=ln(flow)

***相关检验
**LM检验
reg confirm lnGDP PD flow
spatdiag,weights(wcontig)

***模型估计
spmatrix  create contiguity W, replace
spregress confirm lnGDP PD flow, dvarlag(W) gs2sls
preserve

***总效应分解
estat impact

***溢出效应图
predict y0
replace flow = 2000 if CITYNAME_1 == "深圳市"
predict y1
generate double y_diff = y1 - y0
grmap, activate
grmap y_diff, title("Global spillover")
restore

***政策分析
margins,at(flow =generate(flow))
margins,at(flow =generate(flow-1))

local lambda = _b[W:confirm]
predict xb0, xb
replace  PD = 66.5 if CITYNAME_1 == "深圳市"
generate dy=xb1 - xb0
format dy %9.2f
generate Wy = dy
generate lamWy = dy
grmap, activate
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
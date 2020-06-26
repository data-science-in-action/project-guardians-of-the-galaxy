clear all
cd "D:\gis6"

***01矩阵
spwmatrix import using m1.gal, wname(wcontig)
matlist wcontig

use final-data.dta
sum confirm X1 X2 X3
gen lnconfirm=ln(confirm)
gen lnX1=ln(X1)
gen lnX3=ln(X3)
gen lnX2=ln(X2)
gen lnopen=ln(open)
gen lnratio=ln(ratio)
***相关检验
**LM检验
reg confirm lnX1 lnX2 X3
spatdiag,weights(wcontig)

spmatrix  create contiguity W, replace
spregress confirm lnX1 lnX2 X3, dvarlag(W) gs2sls
preserve


***模型估计
spmatrix  create contiguity W, replace
spregress ratio lnflow lnGDP diff lncz, dvarlag(W) gs2sls
preserve

***总效应分解
estat impact

***溢出效应图
predict y0
replace X3 = 470  if CITYNAME_1 == "广州市"
predict y1
generate double y_diff = y1 - y0
grmap, activate
grmap y_diff, title("Global spillover")
restore

***政策分析
margins,at(X3 =generate(X3))
margins,at(X3 =generate(X3-1))

local lambda = _b[W:confirm]
predict xb0, xb
replace flow = 2000 if CITYNAME_1 == "深圳市"
predict xb1, xb
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
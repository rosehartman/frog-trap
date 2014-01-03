Trap model analytics
====================

For ease of analysis, let $S=S_1=S_2$ and, $f_1=f$, and $J_1 = J_1(1-p)$ Thus,

$$A = \left[\begin{matrix}0 & f & 0 & 0\\d J_1 & S & d J_2 & 0\\0 & 0 & 0 & f\\J_1 \left(- d + 1\right) & 0 & J_2 \left(- d + 1\right) & S\end{matrix}\right]$$

The dominant eigenvalue of $A$ are 0, $S$, and

$$\frac{S}{2} \pm \frac{1}{2} \sqrt{S^2 + 4f (J_1 d +  J_2 (1-d))}$$

The positive root of the more complex eigenvalue will always be the dominant value. For simplicity hereafter square-root term is referred to as $v$.  Here are sensitivities $(s)$ of the deterministic growth rate $(\lambda_d)$:

$$s_d = \frac{\partial \lambda_d}{\partial d}  = \frac{f(J_1 - J_2)}{v}$$

$$s_f = \frac{\partial \lambda_d}{\partial f}  = \frac{J_1 d + J_2 (1-d)}{v}$$

$$s_S = \frac{\partial \lambda_d}{\partial S}  = \frac{1}{2} + \frac{1}{2} \frac{S}{v}$$

$$s_{J_1} = \frac{\partial \lambda_d}{\partial J_1}  = \frac{df}{v}$$

$$s_{J_2} = \frac{\partial \lambda_d}{\partial J_2}  = \frac{df}{v}$$



Using Doak's [-@Doak2005] modification of  Tuljapurkar’s [Tuljapurkar1990] approximation, I calculate an expression for the stochastic growth rate.  :

$$\log \lambda_s = \log \hat \lambda_d - \frac{1}{2} \left(\frac{\tau}{\hat {\lambda_d}}\right)^2$$
$$\tau^2 = \sum_i \sum_j \rho_{i,j} \sigma_i \sigma_j s_i s_j$$

where $i$ and $j$ are each of the parameters, $\sigma$ are their standard deviations, and $\rho$ their correlations.  For a case where we assume that there is stochasticity in $J_1$ and $J_2$ but not $S$

$$\begin{aligned}
\tau^2 &= \rho_{J_1, J_2} \sigma_{J_1} \sigma_{J_2} s_{J_1} s_{J_2} + \sigma^2_{J_1} s^2_{J_1} + \sigma^2_{J_1} s^2_{J_2} \\
       &=  \left(\frac{df}{v}\right)^2 \left(\rho_{J_1, J_2} \sigma_{J_1} \sigma_{J_2} + \sigma^2_{J_1} + \sigma^2_{J_1}\right)
\end{aligned}$$

$$\begin{aligned}
  \log \lambda_s &= \log \lambda_d - \frac{1}{2} \left(\frac{\tau}{ {\lambda_d}}\right)^2 \\
                 &= \log \left(\frac{S + v}{2}\right) - 2 \left(\frac{df}{(S + v)v}\right)^2 \left(\rho_{J_1, J_2} \sigma_{J_1} \sigma_{J_2} + \sigma^2_{J_1} + \sigma^2_{J_2}\right)
\end{aligned}$$

We can simplify even more by assuming that variance is equal in the two patches

$$\log \lambda_s = \log \left(\frac{S + v}{2}\right) - 2 \left(\frac{df}{(S + v)v}\right)^2 \left((2+\rho)\sigma^2\right)$$

Now calculate the derivative of $\log \lambda_s$ with respect to $d$:

$$\frac{\partial \log \lambda_s}{\partial d} = \frac{2f \left(J_{1} - J_{2}\right)}{(S+v)v} - (2+\rho)\sigma^2 \left(\frac{4df^2}{(S+v)^2 v^2} - \frac{8d^2f^3(J_1-J_2)}{(S+v)^2 v^4} - \frac{8 d^2f^3(J_1-J_2)}{(S+v)^3 v^3}\right)$$

This is ugly but we are interested in where this derivative equals zero.  Setting the left side to zero allows a number of terms to fall out:

$$0 = (J_1 - J_2) - (2+\rho)\sigma^2 \left(\frac{2df}{(S+v)v} - \frac{4d^2f^2(J_1-J_2)}{(S+v) v^3} - \frac{4 d^2f^2(J_1-J_2)}{(S+v)^2 v^2}\right)$$

OK, still ugly.  But one solution to this is:

$$d = \frac{J_2}{J_2 - J_1} = \frac{J_2}{p}$$

(Solved that last one with SymPy but need to check it)


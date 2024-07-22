# Simulation Framework

In this documentation we discuss our framework for efficient implementation of
Monte Carlo methods that aim at simulating joint diffusion processes.
The framework is designed with the following objectives in mind:

-   Simulation should be exact (i.e. bias-free) if the underlying model
    allows for exact simulation.

-   Framework should allow for efficient factorisation of the joint
    covariance matrix and exploit independence structures.

-   Simulation should be formulated in terms of matrix and tensor
    operations.

Simulation models in scope are models for interest rates, FX rates,
equities, inflation, futures and credit. Basic variants of such models
can be formulated as Ornstein-Uhlenbeck (OU) processes. Such OU
processes do allow for exact simulation.

**Common notation.**

-   $X_{t}$ is an $n$-dimensional state variable which describes the
    model dynamic.

-   $W_{u}$ is an $m$-dimensional Brownian motion under the common
    risk-neutral measure $\mathbb{Q}$.

-   $\Gamma$ is an $m\times m$ matrix representing correlations of
    increments in $W_{u}$.

-   $s$, $u$, $t$ are simulation times with $0\leq s\leq u\leq t$.

-   $X_{t}^{k}$ for $k=1,\ldots,N$ are model component states that
    represent a slice of the full vector $X_{t}$.

-   $\Theta\left(\cdot\right)$, $H\left(\cdot\right)$,
    $\Sigma\left(\cdot\right)$ and $L\left(\cdot\right)$ are composite
    model functions for the full state $X_{t}$.

-   $\Theta^{k}\left(\cdot\right)$, $H^{k}\left(\cdot\right)$ and
    $\Sigma^{k}\left(\cdot\right)$ are component model functions that
    represent slices of $\Theta\left(\cdot\right)$,
    $H\left(\cdot\right)$ and $\Sigma\left(\cdot\right)$.

-   $V\left(s,t,X_{s}\right)$ is a diagonal $n\times n$ matrix
    representing volatilities of the increments of state vector $X_{t}$.

-   $C\left(s,t,X_{s}\right)$ is a $n\times n$ matrix representing
    correlations of the increments of state vector $X_{t}$.

-   $Z^{\left(1\right)},\ldots,Z^{\left(p\right)}$ are independent
    $n$-dimensional standard normal random variables for $p$ paths.

-   $X_{t}^{\left(1\right)},\ldots,X_{t}^{\left(p\right)}$ are simulated
    realisations of the full random state variable $X_{t}$ for $p$
    paths.

# Hybrid Model Specification

The hybrid model is described by a multi-variate process
$\left(X_{t}\right)_{t}$ with $X_{t}\in\mathbb{R}^{n}$ and initial
condition $X_{0}=0$. The elements of the process
$\left(X_{t}\right)_{t}$ are grouped into *models*. That is, we
decompose

$$X_{t}=\left[\begin{array}{c}
X_{t}^{1}\\
\vdots\\
X_{t}^{N}
\end{array}\right].$$

Each component model is descibed by the process
$\left(X_{t}^{k}\right)_{t}$ with $X_{t}^{k}\in\mathbb{R}^{n_{k}}$,
$k=1,\ldots,N$. Each component model is specified independently but with
a common interface. This allows for a flexible combination of models.

**Component models.**

Denote $\left(\Omega,{\cal F}_{t},\mathbb{Q}\right)$ a filtered
probability space with (risk-neutral) probability measure $\mathbb{Q}$.
The common structure of the component models is given by the dynamics

$$X_{t}^{k}=\Theta^{k}\left(s,t,X_{s}\right)+H^{k}\left(s,t,X_{s}\right)X_{s}+\int_{s}^{t}\Sigma^{k}\left(u,X_{s}\right)^{\top}dW_{u}$$

for $0\leq s\leq t$. Here,
$\Theta^{k}\left(s,t,X_{s}\right)\in\mathbb{R}^{n_{k}}$ is a
deterministic drift vector. The matrix
$H^{k}\left(s,t,X_{s}\right)\in\mathbb{R}^{n_{k}\times n}$ typically
accounts for mean reversion in the component model. Finally, the matrix
$\Sigma^{k}\left(u,X_{s}\right)^{\top}\in\mathbb{R}^{n_{k}\times m}$
represents the volatility function of the component model and
$W_{u}\in\mathbb{R}^{m}$ is an $m$-dimensional vector of Brownian
motions under $\mathbb{Q}$.

Above specification is fairly general. We make a few comments to
indicate how concrete component models will implement the specification.

1.  The component model functions $\Theta^{k}$, $H^{k}$ and $\Sigma^{k}$
    may depend on the model state $X_{s}$. However, we impose that the
    model state is observed at time $s$. This allows to cover local and
    stochastic volatility models. But the component model functions
    already need to implement some time-discretisation.

2.  Ideally, the component model functions $\Theta^{k}$, $H^{k}$ and
    $\Sigma^{k}$ are independent of the model state. This is the case
    for models based on OU processes. Then simulation can be exact.

3.  In typical cases, component model states $X_{t}^{k}$ do not depend
    on the full hybrid model state $X_{s}$. Instead, $X_{t}^{k}$ (as
    well as $\Theta^{k}$, $H^{k}$ and $\Sigma^{k}$) only use information
    from $X_{s}^{k}$ plus a few dependencies to other models.
    Consequently, the dimensions $n$ and $m$ can effectively be reduced
    to numbers in the order of $n_{k}$. We leave the general
    representation in order to keep notation brief. But keep in mind
    that with the general notation the full matrices $H^{k}$ and
    $\Sigma^{k}$ will be sparse.

## Hybrid Model Simulation

Our general component model specification yields that the hybrid model
dynamics become

$$X_{t}=\Theta\left(s,t,X_{s}\right)+H\left(s,t,X_{s}\right)X_{s}+\int_{s}^{t}\Sigma\left(u,X_{s}\right)^{\top}dW_{u}$$

with composite hybrid model functions

$$\begin{aligned}
\Theta\left(s,t,X_{s}\right) & =\left[\begin{array}{c}
\Theta^{1}\left(s,t,X_{s}\right)\\
\vdots\\
\Theta^{N}\left(s,t,X_{s}\right)
\end{array}\right]\in\mathbb{R}^{n},\\
H\left(s,t,X_{s}\right) & =\left[\begin{array}{c}
H^{1}\left(s,t,X_{s}\right)^{\top}\\
\vdots\\
H^{N}\left(s,t,X_{s}\right)^{\top}
\end{array}\right]\in\mathbb{R}^{n\times n},\quad\text{and}\\
\Sigma\left(u,X_{s}\right)^{\top} & =\left[\begin{array}{c}
\Sigma^{1}\left(u,X_{s}\right)^{\top}\\
\vdots\\
\Sigma^{N}\left(u,X_{s}\right)^{\top}
\end{array}\right]\in\mathbb{R}^{n\times m}.
\end{aligned}$$

As a consequence, we find that $X_{t}|X_{s}$ is multi-variate normally
distributed with

$$\mathbb{E}\left[X_{t}|X_{s}\right]=\Theta\left(s,t,X_{s}\right)+H\left(s,t,X_{s}\right)X_{s}\in\mathbb{R}^{n}$$

and

$$\text{Cov}\left[X_{t}|X_{s}\right]=\int_{s}^{t}\Sigma\left(u,X_{s}\right)^{\top}\,\Gamma\,\Sigma\left(u,X_{s}\right)dt\in\mathbb{R}^{n\times n}.$$

The constant symmetric matrix $\Gamma\in\mathbb{R}^{m\times m}$
represents the instantaneous correlations of increments $dW_{t}$. We get
for the elements $\text{Cov}\left[X_{t}|X_{s}\right]_{i,j}$ of the
covariance matrix

$$\begin{aligned}
\text{Cov}\left[X_{t}|X_{s}\right]_{i,j} & =\int_{s}^{t}\Sigma\left(u,X_{s}\right)_{i}^{\top}\,\Gamma\,\Sigma\left(u,X_{s}\right)_{j}du.
\end{aligned}$$

Here, $\Sigma\left(u,X_{s}\right)_{i}$ and
$\Sigma\left(u,X_{s}\right)_{j}$ are the $i$-th and $j$-th column
($i,j=1,\ldots,n$) of the volatility matrix
$\Sigma\left(u,X_{s}\right)$.

The covariance matrix is decomposed into a diagonal state-volatility
matrix $V\left(s,t,X_{s}\right)$ and a state-correlation matrix
$C\left(s,t,X_{s}\right)$ such that

$$\begin{aligned}
\left[V\left(s,t,X_{s}\right)\right]_{i.i} & =\sqrt{\left[\text{Cov}\left[X_{t}|X_{s}\right]\right]_{i,i}/\left(t-s\right)},\\
\left[C\left(s,t,X_{s}\right)\right]_{i.i} & =1,\\
\left[C\left(s,t,X_{s}\right)\right]_{i.j} & =\begin{cases}
\frac{\left[\text{Cov}\left[X_{t}|X_{s}\right]\right]_{i,j}}{\left[V\left(s,t,X_{s}\right)\right]_{i.i}\left[V\left(s,t,X_{s}\right)\right]_{j.j}\left(t-s\right)} & \text{if }\left[V\left(s,t,X_{s}\right)\right]_{i.i}\left[V\left(s,t,X_{s}\right)\right]_{j.j}>0\\
0 & \text{else}
\end{cases}
\end{aligned}$$ 

for all indices $i,j=1,\ldots,n$. Then
$$\text{Cov}\left[X_{t}|X_{s}\right]=V\left(s,t,X_{s}\right)C\left(s,t,X_{s}\right)V\left(s,t,X_{s}\right)\left(t-s\right).$$

If all model functions are independent of the state $X_{s}$ then we can
directly calculate a (Cholesky) decomposition

$$\text{Cov}\left[X_{t}|X_{s}\right]=V\left(s,t\right)\,L\left(s,t\right)\,L\left(s,t\right)^{\top}\,V\left(s,t\right)\,\left(t-s\right).$$

With such a factorisation we can simulate

$$X_{t}=\Theta\left(s,t\right)+H\left(s,t\right)X_{s}+V\left(s,t\right)\,L\left(s,t\right)\,Z\,\sqrt{t-s}$$

with standard normal vectors $Z\sim{\cal N}\left(0,1\right)$. For a list
of paths
$\left[X_{s}^{\left(1\right)},\ldots,X_{s}^{\left(p\right)}\right]\in\mathbb{R}^{n\times p}$
and standard normal increments
$\left[Z^{\left(1\right)},\ldots,Z^{\left(p\right)}\right]\in\mathbb{R}^{n\times p}$
this can be implemented as matrix multiplication and addition

$$\begin{aligned}
\left[X_{t}^{\left(1\right)},\ldots,X_{t}^{\left(p\right)}\right] & =\left[\Theta\left(s,t\right),\ldots,\Theta\left(s,t\right)\right]\\
 & \quad+H\left(s,t\right)^{\top}\left[X_{s}^{\left(1\right)},\ldots,X_{s}^{\left(p\right)}\right]\\
 & \quad+V\left(s,t\right)\,L\left(s,t\right)\,\left[Z^{\left(1\right)},\ldots,Z^{\left(p\right)}\right]\,\sqrt{t-s}.
\end{aligned}$$

The assumption of state-independent model component
functions holds e.g. for Gaussian short rate models, Black-Scholes
equity/foreign exchange models, and Dodgson-Kainth inflation model.

# Component Models

In this section, we specify component models for our hybrid model
framework.

## Interest Rate Models

Interest rate models are formulated as separable Heath-Jarrow-Morton
(HJM) models for the continuous forward rate $f\left(t,T\right)$ with
observation time $t$ and term $T$.

Our specification follows in large parts
[Andersen/Piterbarg, *Interest Rate Modeling*, 2010](@ref label_literature_and_references),
Sec. 4.4 and 4.5.

Forward rates are directly linked to zero coupon bonds $P\left(t,T\right)$. We have

$$P\left(t,T\right)=\exp\left\{ -\int_{t}^{T}f\left(t,s\right)ds\right\}$$

or equivalently

$$f\left(t,T\right)=-\frac{\partial}{\partial T}\log\left(P\left(t,T\right)\right).$$

We formulate the model in risk neutral measure. The risk neutral measure
uses the continuous bank account as numeraire. The bank account accruals
at the short rate

$$r_{t}=f(t,t).$$

And the price process of the bank account $\left(B_{t}\right)_{t}$ is given by

$$B_{t}=e^{\int_{0}^{t}r_{s}ds}.$$

### Heath-Jarrow-Morton Modelling Framework

Consider a general HJM model for the forward rates $f(t,T)$.
No-arbitrage considerations yield the dynamics

$$df\left(t,T\right)=\sigma_{f}\left(t,T\right)^{\top}\cdot\left[\int_{t}^{T}\sigma_{f}\left(t,u\right)du\right]\cdot dt+\sigma_{f}\left(t,T\right)^{\top}\cdot dW_{t}.$$

Here, $\sigma_{f}\left(t,T\right)^{\top}$ is a $d$-dimensional vector of
forward rate volatilities and $W_{t}$ is a $d$-dimensional Brownian
motion in the risk-neutral measure. The drift term of the HJM model
follows from no-arbitrage considerations. Thus it remains to specify the
forward rate volatility function $\sigma_{f}\left(t,T\right)^{\top}$.

In an HJM model with separable volatility the forward rate volatility
takes the form
$\sigma_{f}\left(t,T\right)=g\left(t\right)h\left(T\right)$. Here
$g\left(t\right)=g\left(t,\omega\right)\in\mathbb{R}^{d\times d}$ is a
matrix-valued process adapted to ${\cal F}_{t}$ and
$h\left(T\right)\in\mathbb{R}^{d}$ is a vector-valued deterministic
function. The models of this class are also considered Quasi-Gaussian
models.

For an HJM model we get the bond price dynamics in risk-neutral measure
as

$$\frac{dP\left(t,T\right)}{P\left(t,T\right)}=r_{t}\cdot dt-\sigma_{P}\left(t,T\right)^{\top}\cdot dW_{t}.$$

The minus sign indicates that if rates increase bond prices decrease
(and vice versa). In a separable volatility HJM model the bond price
volatility becomes

$$\sigma_{P}\left(t,T\right)=g\left(t\right)\cdot\int_{t}^{T}h\left(u\right)\cdot du.$$

Integration yields the forward rates

$$\begin{aligned}
f\left(t,T\right) & =f\left(0,T\right)+\\
 & \quad h\left(T\right)^{\top}\int_{0}^{t}g\left(s\right)^{\top}g\left(s\right)\left(\int_{s}^{T}h\left(u\right)du\right)ds+\\
 & \quad h\left(T\right)^{\top}\int_{0}^{t}g\left(s\right)^{\top}dW_{s}
\end{aligned}$$

and

$$r_{t}=f\left(0,t\right)+h\left(t\right)^{\top}\left[\int_{0}^{t}g\left(s\right)^{\top}g\left(s\right)\left(\int_{s}^{t}h\left(u\right)du\right)ds+\int_{0}^{t}g\left(s\right)^{\top}dW_{s}\right].$$

We can re-write
$h\left(t\right)^{\top}=\boldsymbol{1}^{\top}H\left(t\right)$ and get

$$r(t)=f(0,t)+\boldsymbol{1}^{\top}H\left(t\right)\left[\int_{0}^{t}g\left(s\right)^{\top}g\left(s\right)\left(\int_{s}^{t}h\left(u\right)du\right)ds+\int_{0}^{t}g\left(s\right)^{\top}dW_{s}\right]$$

with

$$\boldsymbol{1}=\left(\begin{array}{c}
1\\
\vdots\\
1
\end{array}\right)\text{ and }H\left(t\right)=\text{diag}\left(h\left(t\right)\right)=\left(\begin{array}{ccc}
h_{1}\left(t\right) & 0 & 0\\
0 & \ddots & 0\\
0 & 0 & h_{d}\left(t\right)
\end{array}\right).$$

Now, we can introduce the vector of state variables $x_{t}$ with

$$\begin{aligned}
x_{t} & =H\left(t\right)\left[\int_{0}^{t}g\left(s\right)^{\top}g\left(s\right)\left(\int_{s}^{t}h\left(u\right)du\right)ds+\int_{0}^{t}g\left(s\right)^{\top}dW_{s}\right]\\
 & =H\left(t\right)\left[\int_{0}^{t}g\left(s\right)^{\top}\sigma_{P}\left(s,t\right)ds+\int_{0}^{t}g\left(s\right)^{\top}dW_{s}\right]
\end{aligned}$$

Some (lengthy) calculations yield the representation

$$H\left(t\right)^{-1}x_{t}-H\left(s\right)^{-1}x_{s}=H\left(s\right)^{-1}y_{s}G\left(s,t\right)+\int_{s}^{t}g\left(u\right)^{\top}\left[\sigma_{P}\left(u,t\right)du+dW_{u}\right]$$

with model function

$$G\left(s,t\right)=\int_{s}^{t}H\left(s\right)^{-1}H\left(u\right)\boldsymbol{1}du$$

and auxilliary state variable process

$$y_{t}=H\left(t\right)\left(\int_{0}^{t}g\left(s\right)^{\top}g\left(s\right)ds\right)H\left(t\right).$$

**Separation of volatility and mean reversion.**

In order to better separate volatility and mean reversion components, we
set

$$\begin{aligned}
g\left(t\right) & =H\left(t\right)^{-1}\sigma_{t},\\
H\left(s,t\right) & =H\left(t\right)H\left(s\right)^{-1}.
\end{aligned}$$

Then

$$\begin{aligned}
x_{t} & =H\left(s,t\right)\left[x_{s}+y_{s}G\left(s,t\right)+\int_{s}^{t}H\left(s,u\right)^{-1}\sigma_{u}^{\top}\left[\sigma_{u}G\left(u,t\right)du+dW_{u}\right]\right],\\
y_{t} & =H\left(s,t\right)y_{s}H\left(s,t\right)+\int_{s}^{t}H\left(u,t\right)\sigma_{u}^{\top}\sigma_{u}H\left(u,t\right)ds,\\
G\left(s,t\right) & =\int_{s}^{t}H\left(s,u\right)\boldsymbol{1}du,\\
\sigma_{P}\left(u,t\right) & =\sigma_{u}G\left(u,t\right).
\end{aligned}$$

Above representation is the basis for our hybrid model interface.

We note, that we also get the following equality for the drift terms

$$\underbrace{y_{s}G\left(s,t\right)+\int_{s}^{t}H\left(s,u\right)^{-1}\sigma_{u}^{\top}\sigma_{u}G\left(u,t\right)du}_{I_{1}\left(t\right)}=\underbrace{\int_{s}^{t}H\left(s,u\right)^{-1}y_{u}\boldsymbol{1}du}_{I_{2}\left(t\right)}.$$

This property follows by differentiating both sides w.r.t. $t$. Then we
get for the left side of the equation

$$\begin{aligned}
I_{1}'\left(t\right) & =y_{s}H\left(s,t\right)\boldsymbol{1}+\int_{s}^{t}H\left(s,u\right)^{-1}\sigma_{u}^{\top}\sigma_{u}H\left(u,t\right)\boldsymbol{1}du\\
 & =y_{s}H\left(s,t\right)\boldsymbol{1}+H\left(s,t\right)^{-1}\int_{s}^{t}H\left(u,t\right)\sigma_{u}^{\top}\sigma_{u}H\left(u,t\right)\boldsymbol{1}du\\
 & =y_{s}H\left(s,t\right)\boldsymbol{1}+H\left(s,t\right)^{-1}\left[y_{t}-H\left(s,t\right)y_{s}H\left(s,t\right)\right]\boldsymbol{1}\\
 & =H\left(s,t\right)^{-1}y_{t}\boldsymbol{1}\\
 & =I_{2}'\left(t\right).
\end{aligned}$$

The alternative representation of the drift term is
useful in some situations because the integrand does not depend on the
upper boundary $t$. We get

$$x_{t}=H\left(s,t\right)\left[x_{s}+\int_{s}^{t}H\left(s,u\right)^{-1}\left[y_{u}\boldsymbol{1}du+\sigma_{u}^{\top}dW_{u}\right]\right].$$

**Integrated state variable.**

In addition to the state variable $x_{t}$ itself we are also interested
in the integrated state variable
$z_{t}=\boldsymbol{1}^{\top}\int_{0}^{t}x_{s}ds$. In order to derive the
dynamics of the integrated state variable, we need to calculate

$$\begin{aligned}
I\left(s,t\right) & =\int_{s}^{t}x_{v}dv\\
 & =\int_{s}^{t}\left(H\left(s,v\right)\left[x_{s}+\int_{s}^{v}H\left(s,u\right)^{-1}\left[y_{u}\boldsymbol{1}du+\sigma_{u}^{\top}dW_{u}\right]\right]\right)dv.
\end{aligned}$$

For the first term, we get

$$\int_{s}^{t}H\left(s,v\right)x_{s}dv=\text{diag}\left(G\left(s,t\right)\right)x_{s}.$$

In order to simplify calculation for the second term we substitute
$d\bar{W}_{u}=y_{u}\boldsymbol{1}du+\sigma_{u}^{\top}dW_{u}$. Then

$$\begin{aligned}
\int_{s}^{t}H\left(s,v\right)\int_{s}^{v}H\left(s,u\right)^{-1}d\bar{W}_{u}dv & =\int_{s}^{t}\int_{s}^{v}H\left(u,v\right)d\bar{W}_{u}dv\\
 & =\int_{s}^{t}\left(\int_{u}^{t}H\left(u,v\right)dv\right)d\bar{W}_{u}\\
 & =\int_{s}^{t}\text{diag}\left(G\left(u,t\right)\right)d\bar{W}_{u}.
\end{aligned}$$

This yields

$$I\left(s,t\right)=\text{diag}\left(G\left(s,t\right)\right)x_{s}+\int_{s}^{t}\text{diag}\left(G\left(u,t\right)\right)\left[y_{u}\boldsymbol{1}du+\sigma_{u}^{\top}dW_{u}\right].$$

With these preparations we get
$$z_{t}=z_{s}+G\left(s,t\right)^{\top}x_{s}+\int_{s}^{t}G\left(u,t\right)^{\top}\left[y_{u}\boldsymbol{1}du+\sigma_{u}^{\top}dW_{u}\right].$$

**Yield Curve Reconstruction**

We can derive future zero coupon bonds in terms of $x_{t}$ and $y_{t}$
as

$$P(t,T)=\frac{P(0,T)}{P(0,t)}\exp\left\{ -G(t,T)^{\top}x_{t}-\frac{1}{2}G(t,T)^{\top}y_{t}G(t,T)\right\}$$

and future forward rates as

$$f(t,T)=f(0,T)+\boldsymbol{1}^{\top}H(T)H(t)^{-1}\left[x_{t}+y_{t}G(t,T)\right].$$

Also, we directly get the short rate representation

$$r_{t}=f(0,t)+\boldsymbol{1}^{\top}x_{t}.$$

From the short rate we can also recontruct the bank account price process $\left(B_{t}\right)_{t}$
as

$$B_{t}=e^{\int_{0}^{t}r_{s}ds}=\frac{e^{z_{t}}}{P\left(0,t\right)}.$$

The zero coupon bond formula is the basic building block for calculating
future option payoffs. More details on HJM models are elaborated in
Andersen/Piterbarg, *Interest Rate Modeling*, 2010, Sec. 4.4 and 4.5.
The bank account representation is used for
numeraire calculation as well as future asset price reconstruction.

**Constant mean reversion specification.**

So far, we have not specified the structure of the matrix function
$H\left(t\right)$ in our separable HJM model. In order, to make the
model tractable, we set

$$H\left(t\right)=\text{diag}\left(\left[e^{-\chi_{1}t},\ldots,e^{-\chi_{d}t}\right]\right).$$

The parameters $\chi_{1},\ldots,\chi_{d}$ represent the constant mean
reversion parameters in the model.

With constant mean reversion parameters we can calculate

$$H\left(s,t\right)=\text{diag}\left(\left[e^{-\chi_{1}\left(t-s\right)},\ldots,e^{-\chi_{d}\left(t-s\right)}\right]\right)$$

and

$$G\left(s,t\right)=\left[\frac{1-e^{-\chi_{1}\left(t-s\right)}}{\chi_{1}},\ldots,\frac{1-e^{-\chi_{d}\left(t-s\right)}}{\chi_{d}}\right]^{\top}.$$

**Benchmark rates.**

We choose $d$ benchmark rates $f_{i}(t)=f(t,t+\delta_{i})$
($i=1,\ldots,d$). The maturity terms $\delta_{i}$ represent the points
on the yield curve that are selected to be modelled specifically.
Consequently, $\delta_{1}$ to $\delta_{d}$ should reasonably span the
whole yield curve maturities relevant for pricing.

Furthermore, we denote

$$H^{f}(t)=\left(\begin{array}{c}
h\left(t+\delta_{1}\right)^{\top}\\
\vdots\\
h\left(t+\delta_{d}\right)^{\top}
\end{array}\right)=\left(\begin{array}{ccc}
e^{-\chi_{1}\left(t+\delta_{1}\right)} & \ldots & e^{-\chi_{d}\left(t+\delta_{1}\right)}\\
\vdots &  & \vdots\\
e^{-\chi_{1}\left(t+\delta_{d}\right)} & \ldots & e^{-\chi_{d}\left(t+\delta_{d}\right)}
\end{array}\right)$$

which yields

$$H(t)H^{f}(t)^{-1}=\left[H^{f}(t)H(t)^{-1}\right]^{-1}=\left(\begin{array}{ccc}
e^{-\chi_{1}\delta_{1}} & \ldots & e^{-\chi_{d}\delta_{1}}\\
\vdots &  & \vdots\\
e^{-\chi_{1}\delta_{d}} & \ldots & e^{-\chi_{d}\delta_{d}}
\end{array}\right)^{-1}.$$

Note that $H(t)H^{f}(t)^{-1}$ is independent
of the observation time $t$. Consequently, the matrix inversion only
needs to be evaluated once at inception of the model.

**Benchmark rate volatility.**

Model volatility is characterised by the volatility specification of the
benchmark rates as

$$\sigma_{t}^{f}=\left(\begin{array}{ccc}
\sigma_{t}^{f_{1}}\\
 & \ddots\\
 &  & \sigma_{t}^{f_{d}}
\end{array}\right).$$

The benchmark rate dynamics are coupled by a
$d\times d$ correlation matrix $\Gamma_{f}$ which is decomposed into

$$\Gamma_{f}=\left[D^{f}\right]^{\top}D^{f}.$$

For our specification we
choose a time-homogenous correlation matrix. Hence, the matrix
decomposition above only needs to be computed at inception of the model.

Given the above specifications the volatility of the HJM model is
defined via

$$\sigma_{t}^{\top}=H(t)H^{f}(t)^{-1}\sigma_{t}^{f}D^{f}(t)^{\top}.$$

The volatility specification is chosen such that dynamics of the
benchmark rates become

$$df_{i}(t)=O(dt)+\sigma_{t}^{f_{1}}dU_{i}(t)$$

with $dU(t)=D^{f}(t)^{\top}dW(t)$. For details on the derivation of the
benchmark rate dynamics see Andersen/Piterbarg, *Interest Rate Modeling*,
2010, Prop. 13.3.2.

Note that within our hybrid model framework, the correlation
$\Gamma_{f}$ is part of the full risk factor correlation matrix
$\Gamma$. Consequently, for our hybrid model interface, we use the
specification

$$\sigma_{t}^{\top}=H(t)H^{f}(t)^{-1}\sigma_{t}^{f}.$$

### Multi-factor Gaussian Model

In order fully specify an interest rate model we need to define the
$d\times d$ volatility process matrix $\left(\sigma_{t}\right)_{t}$. By
means of the benchmark forward rates $f_{i}$ we already reduced this
problem to the specification of the $d$ individual benchmark rate
volatility processes $\left(\sigma_{i,t}\right)_{t}$. In this section,
we give a first full specification of the benchmark rate volatility
processes.

In a Gaussian model we assume deterministic volatility processes
$\sigma_{i,t}=\sigma_{i}\left(t\right)$ for $i=1,\ldots,d$. In order to
simplify analytics, er also assume that the volatility functions
$\sigma_{i}\left(t\right)$ are piece-wise constant. Then, also the model
volatility $\sigma_{t}=\sigma\left(t\right)$ is deterministic and
piece-wise constant.

An important consequence of this modelling choice is that the auxiliary
state process $y_{t}$ also becomes deterministic and easily computable.
Assume $y\left(s\right)$ is known and $\sigma\left(u\right)=\sigma$ is
constant on the intervall $\left(s,t\right)$. Then

$$y\left(s\right)=H\left(s,t\right)y\left(s\right)H\left(s,t\right)+\int_{s}^{t}H\left(u,t\right)\sigma^{\top}\sigma H\left(u,t\right)ds.$$

The integral becomes

$$\begin{aligned}
\int_{s}^{t}H\left(u,t\right)\sigma^{\top}\sigma H\left(u,t\right)ds & =\left[\int_{s}^{t}e^{-\chi_{i}\left(t-u\right)}\left[\sigma^{\top}\sigma\right]_{i,j}e^{-\chi_{j}\left(t-u\right)}du\right]_{i,j=1,\ldots,d}\\
 & =\left[\left[\sigma^{\top}\sigma\right]_{i,j}\int_{s}^{t}e^{-\left(\chi_{i}+\chi_{j}\right)\left(t-u\right)}du\right]_{i,j=1,\ldots,d}\\
 & =\left[\left[\sigma^{\top}\sigma\right]_{i,j}\left[\frac{1-e^{-\left(\chi_{i}+\chi_{j}\right)\left(t-u\right)}}{\chi_{i}+\chi_{j}}\right]\right]_{i,j=1,\ldots,d}.
\end{aligned}$$

With this formula we calculate and store
$\left(y\left(t_{k}\right)\right)_{k}$ on the grid
$\left(t_{1},t_{2},\ldots\right)$ of piece-wise constant volatility
values $\left(\sigma_{\left(k\right)}\right)_{k}$. Then a value
$y\left(t\right)$ for some $t_{k-1}\leq t<t_{k}$ is calculated as

$$y\left(t\right)=H\left(t_{k-1},t\right)y\left(t_{k-1}\right)H\left(t_{k-1},t\right)+\left[\left[\sigma_{\left(k\right)}^{\top}\sigma_{\left(k\right)}\right]_{i,j}\left[\frac{1-e^{-\left(\chi_{i}+\chi_{j}\right)\left(t-t_{k-1}\right)}}{\chi_{i}+\chi_{j}}\right]\right]_{i,j=1,\ldots,d}.$$

**Hybrid model interface.**

In our hybrid model framework we need to take into account that we
simulate in a measure other than the natural risk neutral measure for a
given rates model. In such a situation need to take into account quanto
adjustments. Denote $\left(W_{t}^{n}\right)_{t}$ a Brownian motion under
a common hybrid mode risk neutral measure. Girsanov's theorem yields
that there is a process $\left(\alpha_{t}\right)_{t}$ and

$$W_{t}^{n}=W_{t}+\int_{0}^{t}\alpha_{s}dt.$$

With this change of measure, we get

$$x_{t}=H\left(s,t\right)\left[x_{s}+y_{s}G\left(s,t\right)+\int_{s}^{t}H\left(s,u\right)^{-1}\sigma_{u}^{\top}\left[\sigma_{u}G\left(u,t\right)du+\left[dW_{u}^{n}-\alpha_{u}du\right]\right]\right].$$

$$\begin{aligned}
x_{t} & =H\left(s,t\right)y\left(s\right)G\left(s,t\right)+\int_{s}^{t}H\left(u,t\right)\sigma\left(u\right)^{\top}\left[\sigma\left(u\right)G\left(u,t\right)-\alpha_{u}\right]du+\\
 & \quad H\left(s,t\right)x_{s}+\\
 & \quad\int_{s}^{t}H\left(u,t\right)\sigma\left(u\right)^{\top}dW_{u}^{n}.
\end{aligned}$$

Furthermore, we have for the integrated state variable

$$\begin{aligned}
z_{t} & =z_{s}+G\left(s,t\right)^{\top}x_{s}+\int_{s}^{t}G\left(u,t\right)^{\top}\left[y\left(u\right)\boldsymbol{1}du+\sigma\left(u\right)^{\top}\left[dW_{u}^{n}-\alpha_{u}du\right]\right]\\
 & =z_{s}+G\left(s,t\right)^{\top}x_{s}+\int_{s}^{t}G\left(u,t\right)^{\top}\left[\left[y\left(u\right)\boldsymbol{1}-\sigma\left(u\right)^{\top}\alpha_{u}\right]du+\sigma\left(u\right)^{\top}dW_{u}^{n}\right].
\end{aligned}$$

As a result, we find that we can specify our hybrid model state variable
$X_{t}^{k}$ and identify the model component functions
$\Theta^{k}\left(\cdot\right)$, $H^{k}\left(\cdot\right)$ and
$\Sigma^{k}\left(\cdot\right)$ for a Gaussian model. We set

$$X_{t}^{k}=\left[\begin{array}{c}
x_{t}\\
z_{t}
\end{array}\right]=\left[\begin{array}{c}
x_{t}^{1}\\
\vdots\\
x_{t}^{d}\\
z_{t}
\end{array}\right].$$

Then

$$\begin{aligned}
\Theta^{k}\left(s,t\right) & =\left[\begin{array}{c}
H\left(s,t\right)y\left(s\right)G\left(s,t\right)+\int_{s}^{t}H\left(u,t\right)\sigma\left(u\right)^{\top}\left[\sigma\left(u\right)G\left(u,t\right)-\alpha_{u}\right]du\\
\int_{s}^{t}G\left(u,t\right)^{\top}\left[y\left(u\right)\boldsymbol{1}-\sigma\left(u\right)^{\top}\alpha_{u}\right]du
\end{array}\right],\\
H^{k}\left(s,t\right) & =\left[\begin{array}{cc}
H\left(s,t\right) & 0\\
G\left(s,t\right)^{\top} & 1
\end{array}\right],\\
\Sigma\left(u\right)^{\top} & =\left[\begin{array}{c}
H\left(u,t\right)\sigma\left(u\right)^{\top}\\
G\left(u,t\right)^{\top}\sigma\left(u\right)^{\top}
\end{array}\right].
\end{aligned}$$ 

We note, that the drift function $\Theta^{k}$ is only
state-independent if the quanto drift $\alpha_{t}$ is state-independent.
This property is closely linked to the volatility assumptions of the
foreign exchange model between rates model's currency and the hybrid
model numeraire currency.

**Alternative drift formula.**

$$x_{t}=H\left(s,t\right)\left[x_{s}+\int_{s}^{t}H\left(s,u\right)^{-1}\left[y_{u}\boldsymbol{1}du+\sigma_{u}^{\top}\left[dW_{u}^{n}-\alpha_{u}du\right]\right]\right].$$

$$\begin{aligned}
x_{t} & =\int_{s}^{t}H\left(u,t\right)\left[y\left(u\right)\boldsymbol{1}-\sigma\left(u\right)^{\top}\alpha_{u}\right]dt+\\
 & \quad H\left(s,t\right)x_{s}+\\
 & \quad\int_{s}^{t}H\left(u,t\right)\sigma\left(u\right)^{\top}dW_{u}^{n}
\end{aligned}$$


## Tradeable Asset Models

In this subsection we specify our component models for tradeable assets.
Such assets are typically foreign exchange rates, equities, equity
indices and inflation indices. We use the notation of foreign exchange
rates models with *domestic* and *foreign* currency. An adaption to
equity and inflation models is then straight forward.

### Hybrid FX Modelling Framework

We consider the positive price process $\left(S_{t}\right)_{t}$ of one
unit of foreign currency measured by units of domestic currency.
Moreover, denote $\left(B_{t}^{d}\right)_{t}$ and
$\left(B_{t}^{f}\right)_{t}$ the bank account processes in domestic and
foreign currency. The process $\left(S_{t}B_{t}^{f}\right)_{t}$
represents the price process of the foreign currency bank account
measured in units of domestic currency. This is a tradeable asset in
domestic currency. The domestic currency risk-neutral measure uses the
bank account $\left(B_{t}^{d}\right)_{t}$ as numeraire. As a
consequence, the process

$$\left(\frac{S_{t}B_{t}^{f}}{B_{t}^{d}}\right)_{t}$$

must be a martingale.

The martingale property motivates the asset price process

$$S_{t}=\frac{B_{t}^{d}}{B_{t}^{f}}e^{x_{t}}$$

for a normalised state
variable process $\left(x_{t}\right)_{t}$. For the state variable we
assume the dynamics

$$x_{t}=-\frac{1}{2}\int_{0}^{t}\sigma_{s}^{2}ds+\int_{0}^{t}\sigma_{s}dW_{s}.$$

Here, $\left(\sigma_{t}\right)_{t}$ is a scalar volatility process
adapted to ${\cal F}_{t}$, and $\left(W_{t}\right)_{t}$ is a scalar
Brownian motion in the domestic currency risk-neutral measure.

Note that above specification of the process $\left(x_{t}\right)_{t}$
covers a wide range of models. The models are distinguished by the
modelling of the volatility process $\left(\sigma_{t}\right)_{t}$. The
representation $S_{t}=\left(B_{t}^{d}/B_{t}^{f}\right)e^{x_{t}}$ allows
for a clear decoupling of interest rate modelling and hybrid asset
modelling. For the sake of clarity we can also write the dynamics of
$\left(S_{t}\right)_{t}$ explicitely as

$$S_{t}=S_{s}+\int_{s}^{t}S_{u}\left(r_{u}^{d}-r_{u}^{f}\right)du+\int_{s}^{t}\sigma_{u}dW_{u}$$

with domestic and foreign short rates $r_{u}^{d}$ and $r_{u}^{f}$.

There is an important consequence from the asset price representation
$S_{t}=\left(B_{t}^{d}/B_{t}^{f}\right)e^{x_{t}}$ . In order to
reconstruct future asset prices $S_{t}$ the asset model must *know* its
corresponding domestic and foreign interest rate model. Moreover, the
asset model also requires the integrated state variables $z_{t}^{d}$ and
$z_{t}^{f}$ in order to allow for the domestic and foreign interest rate
model to calculate $B_{t}^{d}$ and $B_{t}^{f}$.

### Quanto Adjustment

So far, we implicitly assumed that interest rate models are formulated
in the risk-neutral measure of their respective currency. Similarly, we
also assumed that asset models are formulated in their respective
domestic currency risk neutral measure.

In a hybrid modelling framework for various currencies we need to decide
on a common numeraire currency, the corresponding numeraire price
process and the common martingale measure. Such a common martingale
measure in general does not coincide with the risk-neutral measures that
are typically used to formulate foreign currency component models.
Consequently, we need to incorporate a change of measure for such
foreign currency component models.

In this section, we formulate the change of measure from a given risk
neutral measure to a common numeraire currency risk neutral measure. The
change of measure is formulated in a rather general way in order to
apply it later on for various component models. We consider a domestic
currency with some asset price process $X_{t}^{d}$. For practical
purposes, such an asset is typically

-   a domestic zero coupon bond with price process
    $\left(P^{d}\left(t,T\right)\right)_{t}$ or

-   foreign currency bank account measured in units of domestic currency
    with price process $\left(S_{t}^{f-d}B_{t}^{f}\right)_{t}$.

The corresponding domestic currency discounted asset process is denoted
$\left(\tilde{X}_{t}^{d}\right)_{t}$ with

$$\tilde{X}_{t}^{d}=\frac{X_{t}^{d}}{B_{t}^{d}}.$$

Without loss of
generality, we assume that the discounted asset price process follows
the dynamics

$$\frac{d\tilde{X}_{t}^{d}}{\tilde{X}_{t}^{d}}=\left[\sigma_{t}^{X^{d}}\right]^{\top}dW_{t}^{d}$$

where $\left(\sigma_{t}^{X^{d}}\right)_{t}$ is an adapted process and
$\left(W_{t}^{d}\right)_{t}$ is a $n^{d}$-dimensional Brownian motion in
domestic currency risk neutral measure $\mathbb{Q}^{d}$.

In addition to the domestic (and foreign) currency we consider a
numeraire currency with bank account prices $B_{t}^{n}$. The price of
one unit domestic currency measured by units of numeraire currency is
denoted as $S_{t}^{d-n}$. The price of our domestic currency asset
measured in units of numeraire currency is $S_{t}^{d-n}X_{t}^{d}$. Under
the numeraire currency risk-neutral measure $\mathbb{Q}^{n}$ with
numeraire price process $\left(B_{t}^{n}\right)_{t}$ we can also
formulate the discounted price process $\left(M_{t}\right)_{t}$ with
$$M_{t}=\frac{S_{t}^{d-n}P^{d}\left(t,T\right)}{B_{t}^{n}}.$$
No-arbitrage arguments require that $\left(M_{t}\right)_{t}$ is a
$\mathbb{Q}^{n}$-martingale.

Using our hybrid FX modelling framework we can write $M_{t}$ as

$$M_{t}=\frac{B_{t}^{n}}{B_{t}^{d}}e^{x_{t}^{d-n}}\frac{X_{t}^{d}}{B_{t}^{n}}=\frac{X_{t}^{d}}{B_{t}^{d}}e^{x_{t}^{d-n}}=\tilde{X}_{t}^{d}e^{x_{t}^{d-n}}.$$

with domestic numeraire FX model state variable process
$\left(x_{t}^{d-n}\right)_{t}$. In order to further simplify notation,
we set $Y_{t}^{d-n}=e^{x_{t}^{d-n}}$ and note that

$$\begin{aligned}
Y_{t}^{d-n} & =Y_{0}^{d-n}+\int_{0}^{t}Y_{s}^{d-n}dx_{s}^{d-n}+\frac{1}{2}\int_{0}^{t}Y_{s}^{d-n}d\left\langle x_{s}^{d-n},x_{s}^{d-n}\right\rangle \\
 & =Y_{0}^{d-n}+\int_{0}^{t}Y_{s}^{d-n}\sigma_{s}^{d-n}dW_{s}^{d-n}.
\end{aligned}$$

In this representation,
$\left(\sigma_{t}^{d-n}\right)_{t}$ is the FX volatility process of
$\left(S_{t}^{d-n}\right)_{t}$ and $\left(W_{t}^{d-n}\right)_{t}$ is a
Brownian motion in numeraire currency risk neutral measure. Above
calculation also demonstrates that $\left(Y_{t}^{d-n}\right)_{t}$ is a
$\mathbb{Q}^{n}$-martingale driven by an Ito integral.

Now, Ito product rule yields for the process $\left(M_{t}\right)_{t}$
that

$$M_{t}=M_{0}+\int_{0}^{t}\tilde{X}_{s}^{d}dY_{s}^{d-n}+\int_{0}^{t}Y_{s}^{d-n}d\tilde{X}_{s}^{d}+\int_{0}^{t}d\left\langle \tilde{X}_{s}^{d},Y_{s}^{d-n}\right\rangle .$$

The first Ito integral is

$$I_{1}=\int_{0}^{t}\tilde{X}_{s}^{d}dY_{s}^{d-n}=\int_{0}^{t}M_{s}\sigma_{s}^{d-n}dW_{s}^{d-n}.$$

This term is a $\mathbb{Q}^{n}$-martingale. For the second integral we
get

$$I_{2}=\int_{0}^{t}Y_{s}^{d-n}d\tilde{X}_{s}^{d}=\int_{0}^{t}M_{s}\left[\sigma_{s}^{X^{d}}\right]^{\top}dW_{s}^{d}.$$

This term is a $\mathbb{Q}^{d}$-martingale because by construction
$\left(W_{t}^{d}\right)_{t}$ is a Brownian motion in the domestic
currency risk neutral measure. for the third integral we get

$$I_{3}=\int_{0}^{t}d\left\langle \tilde{X}_{s}^{d},Y_{s}^{d-n}\right\rangle =\int_{0}^{t}\left\langle d\tilde{X}_{s}^{d},dY_{s}^{d-n}\right\rangle =\int_{0}^{t}M_{s}\left\langle \left[\sigma_{s}^{X^{d}}\right]^{\top}dW_{s}^{d},\sigma_{s}^{d-n}dW_{s}^{d-n}\right\rangle .$$

Girsanov's theorem yields that there is an adapted process
$\left(\alpha_{t}\right)_{t}$ such that

$$W_{t}^{d,n}=W_{t}^{d}+\int_{0}^{t}\alpha_{s}ds$$

is a Brownian motion
under $\mathbb{Q}^{n}$. This yields

$$I_{2}=\int_{0}^{t}M_{s}\left[\sigma_{t}^{X^{d}}\right]^{\top}\left(dW_{s}^{d,n}-\alpha_{s}ds\right).$$

For the third integral, we can now use linearity of covariance process
and the property, that the quadratic variation of
$\int_{0}^{t}\alpha_{s}ds$ vanishes. This gives

$$\begin{aligned}
I_{3} & =\int_{0}^{t}M_{s}\left\langle \left[\sigma_{s}^{X^{d}}\right]^{\top}\left(dW_{s}^{d,n}-\alpha_{s}ds\right),\sigma_{s}^{d-n}dW_{s}^{d-n}\right\rangle \\
 & =\int_{0}^{t}M_{s}\left\langle \left[\sigma_{s}^{X^{d}}\right]^{\top}dW_{s}^{d,n},\sigma_{s}^{d-n}dW_{s}^{d-n}\right\rangle .
\end{aligned}$$

The Brownian motion increments are correlated such that

$$\left\langle dW_{s}^{d,n},dW_{s}^{d-n}\right\rangle =\Gamma^{X^{d},S^{d-n}}dt$$

with instantaneous correlation matrix $\Gamma^{X^{d},S^{d-n}}$ of shape
$\left(n^{d},1\right)$. This leads to the representation

$$I_{3}=\int_{0}^{t}M_{s}\left[\sigma_{s}^{X^{d}}\right]^{\top}\Gamma^{X^{d},S^{d-n}}\sigma_{s}^{d-n}ds.$$

Recall that $\left(M_{t}\right)_{t}$ is a $\mathbb{Q}^{n}$-martingale.
This requires that

$$I_{2}+I_{3}=\int_{0}^{t}M_{s}\left[\sigma_{t}^{X^{d}}\right]^{\top}\left(dW_{s}^{d,n}+\left[\Gamma^{X^{d},S^{d-n}}\sigma_{s}^{d-n}-\alpha_{s}\right]ds\right)$$

is a $\mathbb{Q}^{n}$-martingale. This leads to the condition

$$\alpha_{t}=\Gamma^{X^{d},S^{d-n}}\sigma_{t}^{d-n}$$

and the change of measure formula

$$W_{t}^{d,n}=W_{t}^{d}+\int_{0}^{t}\Gamma^{X^{d},S^{d-n}}\sigma_{s}^{d-n}ds.$$

**Quanto adjustment for rates models.**

For Gaussian rates models in a domestic currency we have

$$\Theta^{k}\left(s,t\right)=\left[\begin{array}{c}
H\left(s,t\right)y\left(s\right)G\left(s,t\right)+\int_{s}^{t}H\left(u,t\right)\sigma^{d}\left(u\right)^{\top}\left[\sigma^{d}\left(u\right)G\left(u,t\right)-\alpha_{u}\right]du\\
\int_{s}^{t}G\left(u,t\right)^{\top}\left[y\left(u\right)\boldsymbol{1}-\sigma^{d}\left(u\right)^{\top}\alpha_{u}\right]du
\end{array}\right].$$

Assets prices are zero coupon bonds,
$X_{t}^{d}=P^{d}\left(t,T\right)$ driven by the state variable
$x_{t}^{d}$. Consequently, the quanto adjustment drift becomes

$$\alpha_{t}=\Gamma^{x^{d},S^{d-n}}\sigma_{t}^{d-n}.$$

Here, $\Gamma^{x^{d},S^{d-n}}$ summarises the instantaneous correlations of the
interest rate risk factors and the FX risk factor. Assuming FX
volatility is deterministic with
$\sigma_{t}^{d-n}=\sigma^{d-n}\left(t\right)$, we get

$$\Theta^{k}\left(s,t\right)=\left[\begin{array}{c}
H\left(s,t\right)y\left(s\right)G\left(s,t\right)+\int_{s}^{t}H\left(u,t\right)\sigma^{d}\left(u\right)^{\top}\left[\sigma^{d}\left(u\right)G\left(u,t\right)-\Gamma^{x^{d},S^{d-n}}\sigma_{t}^{d-n}\right]du\\
\int_{s}^{t}G\left(u,t\right)^{\top}\left[y\left(u\right)\boldsymbol{1}-\sigma^{d}\left(u\right)^{\top}\Gamma^{x^{d},S^{d-n}}\sigma_{t}^{d-n}\right]du
\end{array}\right].$$

### Lognormal Model

We construct a basic asset model by assuming that the volatility process
$\left(\sigma_{t}^{f-d}\right)_{t}$ is deterministic, i.e.
$\sigma_{t}^{f-d}=\sigma^{f-d}\left(t\right)$. Then

$$x_{t}^{f-d}=x_{s}^{f-d}-\frac{1}{2}\int_{s}^{t}\sigma^{f-d}\left(u\right)^{2}du+\int_{s}^{t}\sigma^{f-d}\left(u\right)dW_{u}^{d}.$$

If the domestic currency differs from the numeraire currency then we
need to incorporate quanto adjustment with

$$W_{t}^{d,n}=W_{t}^{d}+\int_{0}^{t}\Gamma^{S^{f-d},S^{d-n}}\sigma_{s}^{d-n}ds.$$

This yields

$$\begin{aligned}
x_{t}^{f-d} & =x_{s}^{f-d}-\frac{1}{2}\int_{s}^{t}\sigma^{f-d}\left(u\right)^{2}du+\int_{s}^{t}\sigma^{f-d}\left(u\right)\left[dW_{u}^{d,n}-\Gamma^{S^{f-d},S^{d-n}}\sigma_{u}^{d-n}du\right]\\
 & =x_{s}^{f-d}-\frac{1}{2}\int_{s}^{t}\sigma^{f-d}\left(u\right)\left[\sigma^{f-d}\left(u\right)+2\Gamma^{S^{f-d},S^{d-n}}\sigma_{u}^{d-n}\right]du+\int_{s}^{t}\sigma^{f-d}\left(u\right)dW_{u}^{d,n}.
\end{aligned}$$

In this model setting the state variable process
$\left(x_{t}^{f-d}\right)_{t}$ has normal terminal distributions.
Consequently, $e^{x_{t}}$ is lognormal. If interest rates are modelled
by (multi-factor) Gaussian models then $B_{t}^{d}$ and $B_{t}^{f}$ are
also lognormal. As a result, we find that the asset price $S_{t}$ is
also lognormal.

In the lognormal model, our generic hybrid model state variable
$X_{t}^{k}$ and component functions $\Theta^{k}\left(\cdot\right)$,
$H^{k}\left(\cdot\right)$ and $\Sigma^{k}\left(\cdot\right)$ are easily
identified. We set

$$\begin{aligned}
X_{t}^{k} & =\left[x_{t}\right],\\
\Theta^{k}\left(s,t\right) & =\left[-\frac{1}{2}\int_{s}^{t}\sigma^{f-d}\left(u\right)\left[\sigma^{f-d}\left(u\right)+2\Gamma^{S^{f-d},S^{d-n}}\sigma_{u}^{d-n}\right]du\right],\\
H^{k}\left(s,t\right) & =\left[1\right],\\
\Sigma^{k}\left(u\right)^{\top} & =\left[\sigma^{f-d}\left(u\right)\right].
\end{aligned}$$


## Future Index/Price Models

In this section we specify models for Future index curves or Future
price curves. Such models are typical for commodity derivatives.

### Markov Model Specification

The model is specified following 
[Andersen 2008](@ref label_literature_and_references), eq. (10) - (12).
We keep notation as close as possible to the HJM model specification used for
interest rates.

We denote

$$F\left(t,T\right)$$

a Future index or future price curve.
The Future price is denominated in units of domestic currency. A key
proposition is that for $t\leq T$ the future
price $\left(F\left(t,T\right)\right)_{t}$ is a martingale in the
domestic currency risk-neutral measure. The martingale property and the
theory of separable HJM models motivate the specification

$$F\left(t,T\right) = 
F\left(0,T\right)\exp
  \left\{ 
    h\left(t,T\right)^{\top}
    \left[
        x_{t}+\frac{1}{2}y_{t}\left(I-H\left(t,T\right)\right)\boldsymbol{1}
    \right]
\right\}$$

with $d$-dimensional state variable process $\left(x_{t}\right)_{t}$ and
$d\times d$-dimensional auxiliary (variance) variable process
$\left(y_{t}\right)_{t}$. State and auxiliary variable follow the
dynamics

$$\begin{aligned}
  x_{t} &=
  H\left(s,t\right)
  \left[
    x_{s}+\int_{s}^{t}H\left(s,u\right)^{-1}
    \left[
        \frac{1}{2}
        \left(
            y_{u}\chi\left(u\right)-\sigma_{u}^{\top}\sigma_{u}
        \right)
        \boldsymbol{1}du+\sigma_{u}^{\top}dW_{u}^{d}
    \right]
  \right],\\
  y_{t} &=
  H\left(s,t\right)y_{s}H\left(s,t\right)+
  \int_{s}^{t}H\left(u,t\right)\sigma_{u}^{\top}\sigma_{u}H\left(u,t\right)du.
  \end{aligned}$$

**Quanto-adjustment.**

If the domestic currency differs from the numeraire currency then we
need to incorporate the change of measure

$$\begin{aligned}
  W_{t}^{d,n}
  &= W_{t}^{d}+\int_{0}^{t}\alpha_{s}ds\\
  &= W_{t}^{d}+\int_{0}^{t}\Gamma^{X^{d},S^{d-n}}\sigma_{s}^{d-n}ds.
\end{aligned}$$

This yields the state variable representation with Quanto adjustment as

$$x_{t} =
H\left(s,t\right)
\left[
  x_{s} + 
  \int_{s}^{t}H\left(s,u\right)^{-1}
  \left[
    \frac{1}{2}\left(y_{u}\chi\left(u\right)\boldsymbol{1} -
    \sigma_{u}^{\top}\left[\sigma_{u}\boldsymbol{1}-2\alpha_{u}\right]\right)du +
    \sigma_{u}^{\top}dW_{u}^{d,n}
  \right]
\right].$$

### Multi-factor Gaussian Model

A critical aspect is the specification of the volatility process
$\left(\sigma_{t}\right)_{t}$. For the Gaussian Future index model we
re-use the methodology from the interest rate model. That is, we assume
constant mean reversion parameters $\chi_{1},\ldots,\chi_{d}$ and
benchmark times $\delta_{1},\ldots,\delta_{d}$. Moreover, denote
$\Gamma^{F}=\left[\Gamma_{ij}^{F}\right]$ the instantaneous correlations
between Future prices $F\left(t,t+\delta_{i}\right)$ and
$F\left(t,t+\delta_{j}\right)$.

Then we set

$$\sigma_{t}^{\top}=H(t)H^{F}(t)^{-1}\sigma_{t}^{F}\left[D^{F}(t)\right]^{\top}$$

with

$$\begin{aligned}
H(t)H^{F}(t)^{-1} & =\left(\begin{array}{ccc}
e^{-\chi_{1}\delta_{1}} & \ldots & e^{-\chi_{d}\delta_{1}}\\
\vdots &  & \vdots\\
e^{-\chi_{1}\delta_{d}} & \ldots & e^{-\chi_{d}\delta_{d}}
\end{array}\right)^{-1},\\
\left[D^{F}(t)\right]^{\top}D^{F}(t) & =\Gamma^{F}.
\end{aligned}$$ 

This methodology reduces the modelling to the
specification of a diagonal matrix of benchmark price volatilities

$$\sigma_{t}^{F}=\left(\begin{array}{ccc}
\sigma_{t}^{F_{1}}\\
 & \ddots\\
 &  & \sigma_{t}^{F_{d}}
\end{array}\right).$$

For the Gaussian Future index model, we further assume piece-wise
constant volatility functions
$\sigma_{t}^{F_{i}}=\sigma_{i}\left(t\right)$. Then, also the model
volatility $\sigma_{t}=\sigma\left(t\right)$ is deterministic and
piece-wise constant. With this specification the auxilliary variable process
$\left(y_{t}\right)_{t}$ is deterministic as well. And we can re-use the
machinery from interest rate models to calculate $y_{t}=y\left(t\right)$.

**Hybrid model interface.**

We specify the hybrid model state variable $X_{t}^{k}$ and identify the
model component functions $\Theta^{k}\left(\cdot\right)$,
$H^{k}\left(\cdot\right)$ and $\Sigma^{k}\left(\cdot\right)$ for a
Gaussian Future price model.

We set

$$X_{t}^{k}=\left[\begin{array}{c}
x_{t}^{1}\\
\vdots\\
x_{t}^{d}
\end{array}\right].$$

Then

$$\begin{aligned}
\Theta^{k}\left(s,t\right)
&= \frac{1}{2}\int_{s}^{t}H\left(u,t\right)
   \left[
     \left(
        y\left(u\right)\chi\boldsymbol{1}-
        \left[
            \sigma\left(u\right)^{\top}\sigma\left(u\right)\boldsymbol{1} - 
            2\sigma\left(u\right)^{\top}\alpha\left(u\right)
        \right]
     \right) du
    \right],\\
H^{k}\left(s,t\right) &= H\left(s,t\right),\\
\Sigma^{k}\left(u\right)^{\top}
&= H\left(u,t\right)\sigma\left(u\right)^{\top}.
\end{aligned}$$

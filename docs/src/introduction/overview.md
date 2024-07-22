# Overview

On this page, we give an overview of the DiffFusion.jl modelling framework.

Some features mentioned here are still under development and will be added going forward. If you want to check the status of particular features, please get in touch.

## What Is the Purpose of the Framework?

Scenario-based financial instrument pricing is at the core of most risk management processes and methods. The DiffFusion.jl modelling framework provides a flexible and computationally efficient simulation and pricing engine. It contains state-of-the art model implementations for single and multi-factor models.

The framework is designed for regular large-scale portfolio simulations as well as ad-hoc and interactive pricing and risk calculation analysis. As such, the framework can be used in production processes as well for benchmarking and model validation purposes. 

DiffFusion.jl is decomposed into the following components:

 - scenario generation,
 - scenario-based financial instrument pricing and sensitivity calculation, as well as
 - scenario-based risk measure calculation.

The components can be used independently. However, they develop their full potential when combined together. 


### Scenario Generation

Scenario generation is based on Monte Carlo simulation of risk factors. Risk factors are represented by generic model state variables. The evolution of the model state variables is based on diffusion models.

The diffusion models in the DiffFusion.jl framework represent market standard risk neutral valuation models. For details on the specific models, see the [model section](#What-Models-and-Products-Are-Covered?). A key objective of the framework is flexibility regarding the choice model. For example, you can combine multi-factor rates models for major currencies with single-factor rates models for other currencies.  

Component models for e.g. interest rates, exchange rates and equities are combined into a cross-asset hybrid model. The joint evolution of the hybrid model state variables is then calculated by Monte Carlo simulation.

The Monte Carlo method in the DiffFusion.jl framework uses bias-free simulation of random variables whenever the model allows for. This approach provides flexibility on the chosen time grid and allows simulating long time-horizons without sacrificing simulation accuracy. Random numbers are drawn from efficient pseudo-random number generators or low-discrepancy sequences.


### Financial Instrument Pricing and Sensitivity Calculation

Financial instruments in the DiffFusion.jl framework are represented as a layered composition of payoffs, cash flows and cash flow legs. Each layer adds a level of abstraction and common functionality. Cash flow legs are finally combined into products and portfolios.

The layered design of portfolios and products allows for a very flexible extendability of the framework for new products and feature. Exotic products can easily be integrated since payoffs and payoff-scripting are integral functionalities by design.

Portfolios and products are agnostic to the simulation model and Monte Carlo method. The link between model, simulation and market data is established via a separate entity that holds the context details. This feature also contributes to the flexibility and extendability of the framework. 

Future risk-neutral prices of portfolios and products are calculated using the simulated state variables and the corresponding models. We implement analytical pricing methods whenever available and appropriate. American Monte-Carlo methods will be available for complex products.

Sensitivities of future prices can be calculated efficiently using Algorithmic Differentiation (AD) methods. AD methods are directly available in the Julia language. For more details on AD in Julia, see the [Julia section](#Why-Do-We-Use-Julia-Language?). 


### Risk Measure Calculation

Scenario prices for portfolios and products are stored in a three-dimensional scenario cube. The axes of the cube are simulated scenarios, future observation times and individual product legs. With these data we calculate risk measures like expected exposure and potential future exposure. New risk measures can easily be added to the framework. Alternatively, scenario cubes can also be processed by client applications or directly by the user.


## What Models and Products Are Covered?

The DiffFusion.jl framework covers models for interest rates, exchange rates, equities/indices, inflation, and commodity futures. All models can be combined into hybrid models for joint simulation.

Financial products are composed of cash flows. Cash flows for linear products and Vanilla options are directly available in the framework. New cash flow types can easily be added.


### Component Models

We make extensive use of the Heath-Jarrow-Morton (HJM) framework for the component models. This approach yields most analytical tractability for simulation, pricing and model calibration. More complex model variants can be easily added to the framework.

Interest rates are modelled as multi-factor Gaussian HJM models. Such models allow for a rich set of simulated yield curves involving curve shifts, slopes and curvatures. The models can be calibration to the full surface of at-the-money swaptions. In its single-factor form, the model reduces to the classical Hull-White interest rate model.

Exchange rates are modelled in a classical Black-Scholes-type model. Exchange rate models are linked to the corresponding domestic and foreign interest rate models. Calibration of the models takes into account the joint evolution of exchange rates as well as corresponding interest rates.

Equities and indices are modelled analogous to exchange rates. In that context, the foreign interest rate model is replaced by a dividend yield term structure. The framework allows for a modelling of discrete dividend and dividend yields.

Inflation models are designed following the foreign currency analogy. As a consequence, inflation models are also analogous to exchange rate models. This approach covers the classical Jarrow-Yildirim three-factor model as well as the two-factor Dodgson-Kainth model. Initial inflation forward curves are direct inputs to the model. This allows for modelling seasonality.

Commodity futures are modelled following the HJM framework applied for interest rates. As a consequence, we can cover single-factor models and multi-factor models. This allows for a modelling of futures volatility term structures. Initial futures curves are direct input to the model and can incorporate commodity-specific features like seasonality patterns.

### Cash Flows and Legs

The DiffFusion.jl framework already includes standard fixed income and interest rate cash flows for principal payments, fixed rates and floating rates. Options on forward-looking and backward-looking interest rates are also available.

Linear FX and cross currency instruments are covered by the interest rate cash flows and exchange rate conversion. Additional principal payments in mark-to-market cross currency swaps are handled by a specific leg type.

European and Bermudan swaptions are are also modelled as cash flow legs. For European swaptions we use analytical scenario pricers. Bermudan swaptions scenario prices are calculated by means of American Monte Carlo methods.

Further cash flow typed and leg types will be added going forward.


## Why Do We Use Julia Language?

Risk factor simulation and scenario-based financial instrument pricing are computationally expensive calculations. Efficient implementation of such calculations requires fast compiled machine code, ability to parallelize and distribute calculations as well as support for high-performance computing hardware like GPU. The Julia language natively fulfils all these requirements.

Development in Julia language is lightweight and similar to languages like Python. As a result, new functionalities can easily be added within the framework or attached by client applications or user interaction.

Sensitivity calculation is critical for risk management processes. For exposure simulations, sensitivity calculations can be particularly challenging from a computational perspective. These challenges are addressed by Automatic Differentiation (AD) methods. Julia language supports forward mode and reverse mode AD via operator overloading and source transformation. We leverage these language features and provide efficient and accurate Delta and Vega calculations.

The DiffFusion.jl framework can be incorporated as package in Julia application and user code. Furthermore, the framework can be used e.g. in Jupyter notebooks, Python code and R code via Julia's interfaces to these environments.

The DiffFusion.jl framework can also run fully independent, e.g. in a Docker container. A corresponding server application is implemented in the [DiffFusionServer.jl](https://github.com/frame-consulting/DiffFusionServer.jl) project.


## [Related Literature and References] (@id label_literature_and_references)

- [L. Andersen, V. Piterbarg. Interest Rate Modeling. 2010.](http://andersen-piterbarg-book.com/)
- [R. Jarrow, Y. Yildirim. Pricing Treasury Inflation Protected Securities and Related Derivatives Using an Hjm Model. 2003.](https://ssrn.com/abstract=585828)
- [L. Andersen. Markov Models for Commodity Futures: Theory and Practice. 2008.](https://ssrn.com/abstract=1138782)
- [A. Green. XVA. 2016.](https://www.wiley.com/en-us/XVA:+Credit,+Funding+and+Capital+Valuation+Adjustments-p-9781118556788)
- [L. Andersen, M. Pykhtin, A. Sokol. Rethinking Margin Period of Risk. 2016.](https://ssrn.com/abstract=2719964)

- [The Julia Programming Language](https://julialang.org/)
- [PyJulia - a Python interface to the Julia language](https://pyjulia.readthedocs.io/en/latest/index.html)
- [JuliaCall - an R interface to the Julia language](https://cran.r-project.org/web/packages/JuliaCall/readme/README.html)

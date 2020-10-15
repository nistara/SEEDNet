---
title: ""
authors:
- affiliation: 1
  name: Nistara Randhawa
  orcid: 0000-0002-3335-5516
- affiliation: 2
  name: Duncan Temple Lang
  orcid: 0000-0003-0159-1546
- affiliation: 1
  name: Jonna A.K. Mazet
  orcid: 0000-0002-8712-5951

date: "15 October  2020"
output: pdf_document
bibliography: paper.bib
csl: apa.csl
tags:
- R
- epidemics
- infectious disease model
- stochastic
- networks
affiliations:
- index: 1
  name: One Health Institute, School of Veterinary Medicine, University of California, Davis, USA
- index: 2
  name: Department of Statistics, University of California, Davis, USA
---

# Summary
Advances in mobility have enabled infectious diseases to disseminate rapidly and extensively from one region of the world to another. If we can better predict how diseases may spread, and how they react to different interventions, we stand a better chance at mitigating and controlling them. We devloped an approach to combine fine-grained satellite data on areas of human settlements with high-resolution population information and road data were to build a road-connected network of human settlements. The SEEDNet (Satellite enhanced epidemic disease model) package facilitates the application of a discrete-time stochastic SEIR metapopulation model upon this networks associated with population information and combined with human mobility. This package can be used to model other infectious diseases in different geographic regions. 

# Statement of need
`SEEDNet` is an R package for modeling the spread of infectious diseases across networks of human settlements with human mobility derived from road network transportation. It models the spread using a discrete time stochastic metapopulation model, wherein the infectious disease transmission is coupled with the underlying mobility of individuals across the network. It enables users to calculate mobility patterns and uses this to determine effective populations and subsequently the force of infection with which individuals can acquire the infection. It allows users to determine which nodes or settlement to seed and initiate outbreaks from, and also enables the exploration of scenarios such as vaccination. It uses generated simulation results to determine the spread of the outbreak, including identifying the infection start times, to enable the user to target locations which would be affected first. By instituting vaccination scenarios, the user can determine how targeted control options can attenuate the probability and spread of infectious disease outbreaks. 

# Acknowledgments
This work was made possible by the generous support of the American people through the United States Agency for International Development (USAID) Emerging Pandemic Threats PREDICT project (cooperative agreement number GHN-A-OO-09-00010-00). The contents are the responsibility of the authors and do not necessarily reflect the views of USAID or the United States Government.

# References



---
title: "A Map of California with Census and GDP D ata"
output: github_document
---

```{r setup, include=FALSE, , message = FALSE}
knitr::opts_chunk$set(echo = TRUE)
```


Note: Collaborative work with Margo Weber.

## Code


```{r, echo=FALSE, , message = FALSE}
# Load all packages here
library(tidyverse)
library(RColorBrewer)
library(viridis)
library(sf)
library(USAboundaries)
library(tidycensus)
library(mapdeck)
library(scales)
```



An example of mapdeck code.

```{r, message = FALSE}
get_flowCA <- get_flows(
  geography = "county",
  state = "CA",
  county = "Los Angeles County",
  geometry = TRUE,
  year = 2018) %>%  
  filter(variable == "MOVEDOUT") %>%
  na.omit() %>% 
  slice_max(estimate, n = 25) %>%
  mutate(weight = (estimate/2000),
         info = paste0(scales::comma(estimate) , 
                        " people moved from LA County to " , str_remove(FULL2_NAME, "county") , " in 2018"))
```



```{r, message=FALSE, warning=FALSE, echo=FALSE}
# Do not edit this chunk unless you know what you are doing
knitr::opts_chunk$set(
  echo = TRUE, message = FALSE, warning = FALSE, fig.width = 16/2, fig.height = 9/2
)

```



```{r, echo=FALSE, message = FALSE}
#map of California partitioned by county
CA_counties <- 
  USAboundaries::us_counties(resolution = "low", states = c("california")) %>% 
  select(-state_name) %>% 
 mutate(
    lon = purrr::map_dbl(geometry, ~st_centroid(.x)[[1]]),
    lat = purrr::map_dbl(geometry, ~st_centroid(.x)[[2]])
    )

Labels_CA <- CA_counties %>% 
  filter(name %in% c("Los Angeles"))

#join data frames so counties have geometry
data <- read_csv("data/GDP_CAcounties copy.csv") %>%
  left_join(CA_counties, by="name") %>% 
  st_as_sf()

#migration data from tidycensus
get_map <- get_flows(
  geography = "county",
  state = "CA",
  geometry = TRUE,
  year = 2018) %>% 
  filter(variable == "MOVEDNET") %>% 
  mutate(estimate = ifelse(is.na(estimate), 0, estimate)) %>% 
  group_by(FULL1_NAME, GEOID1) %>% 
  summarise(estimate=sum(estimate))

```




# Static map of California counties net migration and GDP

This choropleth map depicts the counties in the state of California. Each county is shaded according to the GDP of the county in 2018. Most of the state falls into the lower third of the GDP range depicted in the key, with a GDP less than or around $300,000,000. The other information layered onto the map is depicted in the transparent dots located in each county which display the net migration for that county in 2018. It is interesting to note that the net migration for most counties in the state was close to zero, with the highly notable exception of Los Angeles county. Los Angeles county experienced a very low net migration; many more people left the county than moved in. The GDP likely has to do with the high economic value of the entertainment industry located in LA, and the migration is possibly due to the high cost of housing and living in the county, which is 43% higher than the national average.^[https://www.payscale.com/cost-of-living-calculator/California-Los-Angeles]

For this map, the geographical data, including the counties, was taken from the tidycensus package. The GDP data was taken from the BEA.^[U.S. Bureau of Economic Analysis | bea.gov | U.S. Census Bureau | census.gov]



```{r, echo = FALSE, message = FALSE}
# Put code to create your static map here:
ggplot() +
  geom_sf(data = CA_counties) +
  geom_sf(mapping = aes(fill=GDP), data= data, size= 0.5) +
  geom_sf(mapping = aes(size=estimate), color = "orange", alpha = .4, data = get_map) +
  theme_void() +
  # scale_fill_viridis(discrete = FALSE, trans = "log", name="GDP per County", guide = guide_legend( keyheight = unit(3, units = "mm"), keywidth=unit(12, units = "mm"), label.position = "bottom", title.position = 'top', nrow=1) ) +
  scale_fill_continuous(type = "gradient", labels = comma)+
  labs(
    title = "Cross Analysis of California County Migration Data",
    subtitle = "with Real Gross Domestic Product in 2018",
    caption = "U.S. Bureau of Economic Analysis | bea.gov | U.S. Census Bureau | census.gov"
  ) +
   geom_sf_label(aes(label = name), data= Labels_CA, nudge_x = -2.5, nudge_y= -0.5 ) +
  labs(size = "Net County Migration") +
    coord_sf()
```






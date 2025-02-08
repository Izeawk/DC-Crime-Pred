# DC-Crime-Pred

## Final Project Code for Data Processing in R

The R code file is my final version submitted for grading in the class "Data Science with R I".

This end-of-term project was designated as an "open project" from which we could select any topic to write code for. 
Upon searching at [[catalog.data.gov](catalog.data.gov)], I stumbled upon a dataset for crime in Washington, DC in 2024. 
This data was free for use, so I downloaded the dataset and began a prediction model.

Dataset: [[https://catalog.data.gov/dataset/crime-incidents-in-2024](https://catalog.data.gov/dataset/crime-incidents-in-2024)]

## GLM Prediction Model

I was rather unsure where to even begin, but I decided on a GLM model to predict the probability that if a crime was responded to, the crime would be a "violent" one. 

The dependent variable in the code is therefore: VIOLENT_CRIME - a variable that is binary for reported crimes that are violent or not (1 or 0)

That was done with the following independent variables: WARD_DUMMY + DAY_WEIGHT + HOLIDAY_PROXIM + SEASON
The following variables can be summaried as the following:

WARD_DUMMY - A "dummy variable" for whether or not the Ward that the crime was reported in was not in Ward 2 or 6 (1 or 0)
DAY_WEIGHT - A variable to weigh the time of day in accordance with crimes. Day = 0, Evening = 0.5, Midnight = 1
HOLIDAY_PROXIM - The amount of days a crime was reported to a Federal Holiday (+ Christmas Eve)
SEASON - An automatic weighting done by the GLM to give proper weight to each of the four seasons

## Plotting

Various plots could be made with the DCmapR library. This library came to be incredibly useful when plotting the results. 
[[https://github.com/BingoLaHaye/DCmapR](https://github.com/BingoLaHaye/DCmapR)]
## Results

The results showed that most of the variables were very significant to the overall model, but this also resulted in an incredibly small McFadden R^2 model. 
Therefore, these results should not be used to extract any sort of significant meaning in the results. This code is ultimately a good practice run for future code projects, and nothing more. 
This code is for anyone to use for anything, but should NOT be taken seriously or used as an "official" prediction model in any way. 



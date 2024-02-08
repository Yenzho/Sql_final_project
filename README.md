# Flight Database Queries
## Data description (in Russian)
The project uses a demo database https://edu.postgrespro.ru/bookings.pdf
## Tasks
1. Print the name of aircraft that have less than 50 seats?
2. Print the percentage change in the monthly ticket booking amount, rounded to the nearest hundredth.
3. Print the names of aircraft that do not have business class. The solution should be through the array_agg function.
4. Derive a cumulative total of the number of seats on planes for each airport for each day, taking into account only those planes that flew empty and only those days where more than one such plane took off from one airport.\
The result should be the airport code, date, number of empty seats on the plane and a cumulative total.
5. Find the percentage of flights on the routes from the total number of flights.\
Output the airport names and percentages.\
The solution should be through a window function.
6. Print the number of passengers for each mobile operator code, taking into account that the operator code is three characters after +7
7. Classify financial turnover (the amount of flight costs) by route: \
Up to 50 million - low \
From 50 million inclusive to 150 million - middle \
From 150 million inclusive - high \
Output the number of routes in each resulting class
8. Calculate the median flight cost, median booking size, and the ratio of the median booking to the median flight cost, rounded to the nearest hundredth
9. Find the minimum cost of a 1 km flight for passengers. That is, you need to find the distance between airports and, taking into account the cost of flights, get the desired result
